;;; init-jira.el --- Jira Cloud issues, same features as Linear  -*- lexical-binding: t; -*-

;; Login = e-mail + API token (id.atlassian.com > Security > API tokens), in the Keychain:
;;   security add-internet-password -a <email> -s <site>.atlassian.net -w <TOKEN>
;; REST API v2: text is Jira wiki markup, pandoc converts it to and from Markdown.

(require 'auth-source)
(require 'cl-lib)
(require 'url)
(defvar url-http-response-status)
(declare-function org-entry-get "org")
(declare-function org-cycle-set-startup-visibility "org-cycle")

(defcustom my/jira-site nil
  "Jira Cloud host, e.g. \"company.atlassian.net\". Asked once, saved in custom.el."
  :type '(choice (const nil) string) :group 'tools)

(defvar my/jira-org-file (expand-file-name "~/org/jira.org") "My open Jira tickets.")
(defvar my/jira-status-category-order '("indeterminate" "new" "done")
  "Status groups: in progress first, then to do, then done.")
(defvar my/jira--cache-issues nil "My tickets from the last fetch (for SPC l s).")
(defvar my/jira--myself nil "accountId of the logged-in user.")

;; ---- REST API ----

(defun my/jira--site ()
  (or my/jira-site
      (let ((site (replace-regexp-in-string
                   "\\`https?://\\|/.*\\'" ""
                   (string-trim (read-string "Jira site (e.g. company.atlassian.net): ")))))
        (when (string-empty-p site) (user-error "No Jira site given"))
        (customize-save-variable 'my/jira-site site)
        site)))

(defun my/jira--auth ()
  "Basic auth header from the Keychain entry for the Jira site."
  (let* ((entry (car (auth-source-search :host (my/jira--site) :max 1)))
         (secret (plist-get entry :secret)))
    (unless entry (user-error "Jira: no token in Keychain for %s (see lisp/init-jira.el)" my/jira-site))
    (concat "Basic " (base64-encode-string
                      (format "%s:%s" (plist-get entry :user) (if (functionp secret) (funcall secret) secret))
                      t))))

(defun my/jira--error (json)
  (or (and (alist-get 'errorMessages json) (mapconcat #'identity (alist-get 'errorMessages json) "; "))
      (and (alist-get 'errors json)
           (mapconcat (lambda (e) (format "%s: %s" (car e) (cdr e))) (alist-get 'errors json) "; "))
      "unknown error"))

(defun my/jira--request (method path &optional body)
  "Call Jira REST API v2 PATH with METHOD (and BODY as JSON); return the parsed JSON."
  (let* ((url-request-method method)
         (url-request-extra-headers `(("Authorization" . ,(my/jira--auth))
                                      ("Accept" . "application/json")
                                      ("Content-Type" . "application/json")))
         (url-request-data (and body (encode-coding-string (json-serialize body) 'utf-8)))
         (buf (url-retrieve-synchronously (format "https://%s/rest/api/2/%s" (my/jira--site) path) t t 30)))
    (unless buf (user-error "Jira: no response"))
    (with-current-buffer buf
      (unwind-protect
          (let ((status url-http-response-status)
                (text (progn (goto-char (point-min))
                             (re-search-forward "\r?\n\r?\n" nil t)
                             (decode-coding-string (buffer-substring-no-properties (point) (point-max)) 'utf-8))))
            (let ((json (and (string-match-p "\\`[[:space:]]*[[{]" text)
                             (json-parse-string text :object-type 'alist :array-type 'list
                                                :null-object nil :false-object nil))))
              (if (and status (>= status 400))
                  (user-error "Jira %s: %s" status
                              (cond (json (my/jira--error json))
                                    ((string-match "<title>\\(.*?\\)</title>" text) (match-string 1 text))
                                    (t (truncate-string-to-width (string-trim text) 200))))
                json)))
        (kill-buffer buf)))))

(defconst my/jira--list-fields ["summary" "status" "project" "assignee" "priority" "issuetype"])

(defun my/jira--search (jql &optional limit)
  "Issues matching JQL (at most LIMIT, default 500)."
  (let ((limit (or limit 500)) issues token)
    (while (progn
             (let ((page (my/jira--request "POST" "search/jql"
                                           `((jql . ,jql) (maxResults . ,(min 100 (- limit (length issues))))
                                             (fields . ,my/jira--list-fields)
                                             ,@(and token `((nextPageToken . ,token)))))))
               (setq issues (append issues (alist-get 'issues page))
                     token (alist-get 'nextPageToken page)))
             (and token (< (length issues) limit))))
    issues))

(defun my/jira--myself ()
  (or my/jira--myself
      (setq my/jira--myself (alist-get 'accountId (my/jira--request "GET" "myself")))))

(defun my/jira--f (issue &rest keys)
  "Walk ISSUE's fields along KEYS."
  (let ((v (alist-get 'fields issue)))
    (dolist (key keys v) (setq v (alist-get key v)))))

(defun my/jira--key (issue) (alist-get 'key issue))
(defun my/jira--date (iso) (if iso (replace-regexp-in-string "T" " " (substring iso 0 16)) "?"))
(defun my/jira--url (key) (format "https://%s/browse/%s" (my/jira--site) key))

(defun my/jira--pandoc (text from to)
  (with-temp-buffer
    (insert text)
    (unless (zerop (call-process-region (point-min) (point-max) "pandoc" t t nil "-f" from "-t" to "--wrap=none"))
      (user-error "pandoc failed: %s" (buffer-string)))
    (string-trim (buffer-string))))

(defconst my/jira--split "JIRASPLITMARKER7Q")

(defun my/jira--wiki-to-md (texts)
  "Convert the wiki markup strings TEXTS to Markdown with one pandoc call."
  (let ((md (my/jira--pandoc (mapconcat (lambda (s) (or s "")) texts (format "\n\n%s\n\n" my/jira--split))
                             "jira" "gfm")))
    (mapcar #'string-trim (split-string md (regexp-quote my/jira--split)))))

;; ---- Choosing a ticket / project ----

(defun my/jira--label (issue)
  (format "%-10s %s  [%s · %s]" (my/jira--key issue) (my/jira--f issue 'summary)
          (my/jira--f issue 'project 'name) (my/jira--f issue 'status 'name)))

(defun my/jira--choose (prompt issues)
  (let ((table (mapcar (lambda (i) (cons (my/jira--label i) (my/jira--key i))) issues)))
    (cons table (completing-read prompt table))))

(defun my/jira--my-open-jql ()
  "assignee = currentUser() AND statusCategory != Done ORDER BY updated DESC")

;; Pick one of my tickets, type a key (ABC-123) that isn't in the list,
;; or words + M-RET to search all of Jira.
(defun my/jira-read-ticket (prompt)
  (pcase-let* ((`(,table . ,input) (my/jira--choose prompt (or my/jira--cache-issues
                                                               (setq my/jira--cache-issues
                                                                     (my/jira--search (my/jira--my-open-jql))))))
               (input (string-trim input)))
    (cond ((assoc input table) (cdr (assoc input table)))
          ((string-match-p "\\`[A-Za-z][A-Za-z0-9]*-[0-9]+\\'" input) (upcase input))
          ((string-empty-p input) (user-error "No ticket chosen"))
          (t (let ((found (my/jira--search (format "text ~ \"%s\" ORDER BY updated DESC"
                                                   (replace-regexp-in-string "[\"\\\\]" "" input))
                                           30)))
               (unless found (user-error "No tickets match \"%s\"" input))
               (pcase-let ((`(,table . ,choice) (my/jira--choose (format "Results for \"%s\": " input) found)))
                 (or (cdr (assoc choice table)) (user-error "No ticket chosen"))))))))

(defun my/jira-read-project (prompt)
  "Key of a project chosen from all projects I can see."
  (let* ((projects (alist-get 'values (my/jira--request "GET" "project/search?maxResults=100&orderBy=name")))
         (table (mapcar (lambda (p) (cons (format "%-8s %s" (alist-get 'key p) (alist-get 'name p))
                                          (alist-get 'key p)))
                        projects)))
    (or (cdr (assoc (completing-read prompt table nil t) table)) (user-error "No project chosen"))))

(defvar-local my/jira-ticket-key nil "Ticket shown in this view buffer.")

(defun my/jira--org-file-p ()
  (and buffer-file-name (file-equal-p buffer-file-name my/jira-org-file)))

(defun my/jira--key-at-point ()
  "Ticket key of the ticket view, board line, or jira.org heading."
  (or my/jira-ticket-key
      (and my/jira-board-mode
           (save-excursion (beginning-of-line)
                           (and (re-search-forward "\\_<[A-Z][A-Z0-9]*-[0-9]+\\_>" (line-end-position) t)
                                (match-string 0))))
      (and (derived-mode-p 'org-mode) (my/jira--org-file-p) (org-entry-get nil "JIRA-KEY"))))

;; ---- My tickets (SPC l l): ~/org/jira.org, * Project / ** Status / *** TODO KEY Title ----

(defun my/jira--org-keyword (issue)
  (pcase (my/jira--f issue 'status 'statusCategory 'key)
    ("done" "DONE") ("indeterminate" "DOING") (_ "TODO")))

(defun my/jira--org-priority (issue)
  (pcase (my/jira--f issue 'priority 'name)
    ((or "Highest" "High") "[#A] ") ("Medium" "[#B] ") ((or "Low" "Lowest") "[#C] ") (_ "")))

(defun my/jira--status-rank (issue)
  (or (seq-position my/jira-status-category-order (my/jira--f issue 'status 'statusCategory 'key)) 9))

(defun my/jira--org-content (issues)
  (concat
   "#+title: Jira — my tickets\n#+STARTUP: content\n#+TODO: TODO DOING | DONE\n"
   "# Generated by SPC l l (refresh = SPC l l again); edits are overwritten.\n"
   "# , t change state   , v show ticket   SPC l c comment\n\n"
   (mapconcat
    (lambda (project)
      (concat
       (format "* %s (%d)\n" (car project) (length (cdr project)))
       (mapconcat
        (lambda (status)
          (concat
           (format "** %s (%d)\n" (car status) (length (cdr status)))
           (if (equal "done" (my/jira--f (cadr status) 'status 'statusCategory 'key))
               ":PROPERTIES:\n:VISIBILITY: folded\n:END:\n" "")
           (mapconcat (lambda (i)
                        (format "*** %s %s%s %s\n:PROPERTIES:\n:JIRA-KEY: %s\n:TYPE: %s\n:END:\n"
                                (my/jira--org-keyword i) (my/jira--org-priority i) (my/jira--key i)
                                (my/jira--f i 'summary) (my/jira--key i) (my/jira--f i 'issuetype 'name)))
                      (cdr status) "")))
        (seq-sort-by (lambda (g) (cons (my/jira--status-rank (cadr g)) (car g)))
                     (lambda (a b) (if (equal (car a) (car b)) (string< (cdr a) (cdr b)) (< (car a) (car b))))
                     (seq-group-by (lambda (i) (my/jira--f i 'status 'name)) (cdr project)))
        "")))
    (seq-sort-by #'car #'string< (seq-group-by (lambda (i) (my/jira--f i 'project 'name)) issues))
    "")))

(defun my/jira-my-issues ()
  "Write my open Jira tickets (and those done in the last 14 days) to jira.org and show it."
  (interactive)
  (let ((issues (my/jira--search
                 "assignee = currentUser() AND (statusCategory != Done OR updated >= -14d) ORDER BY key")))
    (setq my/jira--cache-issues (seq-remove (lambda (i) (equal "done" (my/jira--f i 'status 'statusCategory 'key)))
                                            issues))
    (make-directory (file-name-directory my/jira-org-file) t)
    (with-temp-file my/jira-org-file (insert (my/jira--org-content issues)))
    (let ((buf (find-buffer-visiting my/jira-org-file)))
      (if buf
          (with-current-buffer buf (revert-buffer t t) (org-cycle-set-startup-visibility))
        (setq buf (find-file-noselect my/jira-org-file)))
      (pop-to-buffer-same-window buf)
      (message "Jira: %d tickets" (length issues)))))

;; , t in jira.org or a ticket view: Jira workflows decide the next states.
(defun my/jira-transition ()
  "Move the ticket at point to another status (allowed transitions only)."
  (interactive)
  (let* ((key (or (my/jira--key-at-point) (my/jira-read-ticket "Ticket: ")))
         (transitions (alist-get 'transitions (my/jira--request "GET" (format "issue/%s/transitions" key))))
         (table (mapcar (lambda (tr)
                          (cons (if (equal (alist-get 'name tr) (alist-get 'name (alist-get 'to tr)))
                                    (alist-get 'name tr)
                                  (format "%s → %s" (alist-get 'name tr) (alist-get 'name (alist-get 'to tr))))
                                (alist-get 'id tr)))
                        transitions))
         (id (cdr (assoc (completing-read (format "%s to: " key) table nil t) table))))
    (my/jira--request "POST" (format "issue/%s/transitions" key) `((transition . ((id . ,id)))))
    (message "%s moved" key)
    (cond ((my/jira--org-file-p) (my/jira-my-issues))
          (my/jira-ticket-key (my/jira-ticket-refresh))
          (my/jira-board-mode (my/jira-board-refresh)))))

;; ---- One ticket (SPC l s): Markdown view ----

(define-minor-mode my/jira-ticket-mode "Keys in a Jira ticket view." :keymap (make-sparse-keymap))

(defun my/jira--render (issue)
  (let* ((f (lambda (&rest keys) (apply #'my/jira--f issue keys)))
         (comments (alist-get 'comments (funcall f 'comment)))
         (md (my/jira--wiki-to-md (cons (funcall f 'description) (mapcar (lambda (c) (alist-get 'body c)) comments))))
         (labels (mapconcat #'identity (funcall f 'labels) ", ")))
    (concat
     (format "# %s %s\n\n" (my/jira--key issue) (funcall f 'summary))
     (format "- **Status:** %s\n- **Type:** %s\n- **Project:** %s\n- **Priority:** %s\n"
             (funcall f 'status 'name) (funcall f 'issuetype 'name) (funcall f 'project 'name)
             (or (funcall f 'priority 'name) "none"))
     (format "- **Assignee:** %s\n- **Reporter:** %s, %s\n- **Updated:** %s\n"
             (or (funcall f 'assignee 'displayName) "nobody") (or (funcall f 'reporter 'displayName) "?")
             (my/jira--date (funcall f 'created)) (my/jira--date (funcall f 'updated)))
     (if (string-empty-p labels) "" (format "- **Labels:** %s\n" labels))
     (format "- **Link:** %s\n\n## Description\n\n%s\n\n## Comments (%d)\n"
             (my/jira--url (my/jira--key issue))
             (if (string-empty-p (car md)) "_No description._" (car md)) (length comments))
     (mapconcat (lambda (pair)
                  (format "\n### %s, %s\n\n%s\n" (or (alist-get 'displayName (alist-get 'author (car pair))) "Jira")
                          (my/jira--date (alist-get 'created (car pair))) (cdr pair)))
                (cl-mapcar #'cons comments (cdr md)) ""))))

(defun my/jira-show-ticket (key)
  "Show Jira ticket KEY (e.g. ABC-123) in a Markdown buffer."
  (interactive (list (my/jira-read-ticket "Ticket (key or words; M-RET searches all): ")))
  (let* ((issue (my/jira--request "GET" (format "issue/%s?fields=summary,status,project,priority,assignee,reporter,created,updated,labels,issuetype,description,comment" key)))
         (buf (get-buffer-create (format "*Jira %s*" (my/jira--key issue)))))
    (with-current-buffer buf
      (let ((inhibit-read-only t)) (erase-buffer) (insert (my/jira--render issue)))
      (gfm-mode)
      (setq my/jira-ticket-key (my/jira--key issue) buffer-read-only t)
      (my/jira-ticket-mode 1)
      (evil-normalize-keymaps)
      (goto-char (point-min)))
    (pop-to-buffer buf)))

(defun my/jira-show-ticket-at-point ()
  "View the ticket under the cursor (jira.org, board), or ask for one."
  (interactive)
  (my/jira-show-ticket (or (my/jira--key-at-point) (my/jira-read-ticket "Ticket: "))))

(defun my/jira-ticket-refresh () (interactive) (my/jira-show-ticket my/jira-ticket-key))
(defun my/jira-ticket-browse () (interactive) (browse-url (my/jira--url (my/jira--key-at-point))))

;; ---- Writing (comment, new ticket): Markdown buffer, , , send / , k cancel ----

(defvar-local my/jira-compose-send nil "Function called with the Markdown text.")
(define-minor-mode my/jira-compose-mode "Keys while writing for Jira." :keymap (make-sparse-keymap))

(defun my/jira--compose (name header send-fn)
  (let ((buf (get-buffer-create name)))
    (with-current-buffer buf
      (erase-buffer)
      (gfm-mode)
      (setq my/jira-compose-send send-fn
            header-line-format (concat " " header ":  , , send   , k cancel"))
      (my/jira-compose-mode 1)
      (evil-normalize-keymaps))
    (pop-to-buffer buf)
    (evil-insert-state)))

(defun my/jira-compose-send ()
  (interactive)
  (let ((text (string-trim (buffer-substring-no-properties (point-min) (point-max))))
        (send my/jira-compose-send))
    (funcall send (if (string-empty-p text) "" (my/jira--pandoc text "gfm" "jira")))
    (quit-window t)))

(defun my/jira-compose-cancel () (interactive) (quit-window t) (message "Discarded"))

(defun my/jira-add-comment ()
  "Write a comment (Markdown) for the ticket at point, or a chosen ticket."
  (interactive)
  (let ((key (or (my/jira--key-at-point) (my/jira-read-ticket "Comment on ticket: "))))
    (my/jira--compose (format "*Jira comment %s*" key) (format "Comment on %s" key)
                      (lambda (wiki)
                        (when (string-empty-p wiki) (user-error "Comment is empty"))
                        (my/jira--request "POST" (format "issue/%s/comment" key) `((body . ,wiki)))
                        (message "Comment added to %s" key)
                        (when-let* ((view (get-buffer (format "*Jira %s*" key))))
                          (with-current-buffer view (my/jira-ticket-refresh)))))))

(defun my/jira-new-issue (project)
  "Create a ticket in PROJECT: type and title in the minibuffer, description as Markdown."
  (interactive (list (or (bound-and-true-p my/jira-board-project) (my/jira-read-project "New ticket in project: "))))
  (let* ((meta (my/jira--request "GET" (format "issue/createmeta/%s/issuetypes" project)))
         (types (seq-remove (lambda (ty) (alist-get 'subtask ty))
                            (or (alist-get 'issueTypes meta) (alist-get 'values meta))))
         (table (mapcar (lambda (ty) (cons (alist-get 'name ty) (alist-get 'id ty))) types))
         (type (cdr (assoc (completing-read "Type: " table nil t) table)))
         (summary (read-string "Title: ")))
    (when (string-empty-p summary) (user-error "Title is empty"))
    (my/jira--compose (format "*Jira new %s*" project) (format "Description for \"%s\" (may stay empty)" summary)
                      (lambda (wiki)
                        (let ((key (alist-get 'key (my/jira--request
                                                    "POST" "issue"
                                                    `((fields . ((project . ((key . ,project)))
                                                                 (issuetype . ((id . ,type)))
                                                                 (summary . ,summary)
                                                                 ,@(and (not (string-empty-p wiki))
                                                                        `((description . ,wiki))))))))))
                          (setq my/jira--cache-issues nil)
                          (message "Created %s" key)
                          (run-at-time 0 nil #'my/jira-show-ticket key))))))

;; ---- Project board (SPC l p): open tickets of one project, by status ----

(defvar-local my/jira-board-project nil)
(defvar-local my/jira-board-issues nil)
(defvar-local my/jira-board-filter "All" "\"All\", \"Me\", \"Unassigned\" or a name.")
(define-minor-mode my/jira-board-mode "Keys in a Jira project board." :keymap (make-sparse-keymap))

(defun my/jira--assignee (issue)
  (let ((assignee (my/jira--f issue 'assignee)))
    (cond ((null assignee) "Unassigned")
          ((equal (alist-get 'accountId assignee) (my/jira--myself)) "Me")
          (t (alist-get 'displayName assignee)))))

(defun my/jira--board-filtered (issues filter)
  (if (member filter '(nil "All")) issues
    (seq-filter (lambda (i) (equal (my/jira--assignee i) filter)) issues)))

(defun my/jira--choose-assignee (issues)
  "Ask who: All, Me, Unassigned, then everyone with tickets (with counts)."
  (let* ((counts (mapcar (lambda (g) (cons (car g) (length (cdr g)))) (seq-group-by #'my/jira--assignee issues)))
         (others (sort (seq-remove (lambda (n) (member n '("Me" "Unassigned"))) (mapcar #'car counts)) #'string<))
         (names (append '("All") (seq-filter (lambda (n) (assoc n counts)) '("Me" "Unassigned")) others))
         (table (mapcar (lambda (n) (cons (format "%s (%d)" n (if (equal n "All") (length issues) (cdr (assoc n counts))))
                                          n))
                        names)))
    (cdr (assoc (completing-read "Assignee: " table nil t) table))))

(defun my/jira--board-content (project issues filter)
  (let* ((shown (my/jira--board-filtered issues filter))
         (groups (seq-sort-by (lambda (g) (my/jira--status-rank (cadr g))) #'<
                              (seq-group-by (lambda (i) (my/jira--f i 'status 'name)) shown))))
    (concat
     (format "#+title: %s\n" project)
     (format "Assignee: %s — %d of %d open tickets\n" filter (length shown) (length issues))
     "RET / , v show ticket   , t status   , a assignee   , c comment   , r refresh   , o browser   q close\n\n"
     (if groups "" "No open tickets.\n")
     (mapconcat (lambda (g)
                  (concat (format "* %s (%d)\n" (car g) (length (cdr g)))
                          (mapconcat (lambda (i)
                                       (format "- %-10s %s  /%s · %s/\n" (my/jira--key i) (my/jira--f i 'summary)
                                               (downcase (my/jira--assignee i)) (or (my/jira--f i 'priority 'name) "none")))
                                     (cdr g) "")))
                groups ""))))

(defun my/jira--board-render ()
  (let ((inhibit-read-only t))
    (erase-buffer)
    (insert (my/jira--board-content my/jira-board-project my/jira-board-issues my/jira-board-filter))
    (goto-char (point-min))))

(defun my/jira-project-board (project &optional filter)
  "Show open tickets of PROJECT, grouped by status, for one assignee or all."
  (interactive (list (my/jira-read-project "Project: ")))
  (let* ((issues (my/jira--search (format "project = \"%s\" AND statusCategory != Done ORDER BY priority DESC, key" project)))
         (filter (or filter (my/jira--choose-assignee issues)))
         (buf (get-buffer-create (format "*Jira: %s*" project))))
    (with-current-buffer buf
      (org-mode)
      (setq my/jira-board-project project my/jira-board-issues issues my/jira-board-filter filter)
      (my/jira--board-render)
      (setq buffer-read-only t)
      (my/jira-board-mode 1)
      (evil-normalize-keymaps))
    (pop-to-buffer buf)))

(defun my/jira-board-assignee ()
  "Show the board for another assignee (no new request)."
  (interactive)
  (setq my/jira-board-filter (my/jira--choose-assignee my/jira-board-issues))
  (my/jira--board-render))

(defun my/jira-board-refresh () (interactive) (my/jira-project-board my/jira-board-project my/jira-board-filter))
(defun my/jira-board-browse ()
  (interactive)
  (browse-url (format "https://%s/jira/software/projects/%s/issues" (my/jira--site) my/jira-board-project)))

;; ---- jira.org: , t / , v act on the Jira ticket of the heading ----

(define-minor-mode my/jira-org-mode "Keys in jira.org." :keymap (make-sparse-keymap))
(defun my/jira-org-setup () (when (my/jira--org-file-p) (my/jira-org-mode 1)))
(add-hook 'org-mode-hook #'my/jira-org-setup)

(with-eval-after-load 'evil
  (evil-define-key 'normal my/jira-org-mode-map
    (kbd "<localleader>t") '("Change status" . my/jira-transition)
    (kbd "<localleader>v") '("Show ticket" . my/jira-show-ticket-at-point))
  (evil-define-key 'normal my/jira-ticket-mode-map
    (kbd "<localleader>c") '("Comment" . my/jira-add-comment)
    (kbd "<localleader>t") '("Change status" . my/jira-transition)
    (kbd "<localleader>r") '("Refresh" . my/jira-ticket-refresh)
    (kbd "<localleader>o") '("Open in browser" . my/jira-ticket-browse)
    "q" #'quit-window)
  (evil-define-key 'normal my/jira-board-mode-map
    (kbd "RET") '("Show ticket" . my/jira-show-ticket-at-point)
    (kbd "<localleader>v") '("Show ticket" . my/jira-show-ticket-at-point)
    (kbd "<localleader>t") '("Change status" . my/jira-transition)
    (kbd "<localleader>a") '("Choose assignee" . my/jira-board-assignee)
    (kbd "<localleader>c") '("Comment" . my/jira-add-comment)
    (kbd "<localleader>r") '("Refresh" . my/jira-board-refresh)
    (kbd "<localleader>o") '("Open project in browser" . my/jira-board-browse)
    "q" #'quit-window)
  (evil-define-key 'normal my/jira-compose-mode-map
    (kbd "<localleader>,") '("Send" . my/jira-compose-send)
    (kbd "<localleader>k") '("Cancel" . my/jira-compose-cancel)))
(keymap-set my/jira-compose-mode-map "C-c C-c" #'my/jira-compose-send)
(keymap-set my/jira-compose-mode-map "C-c C-k" #'my/jira-compose-cancel)

(provide 'init-jira)
