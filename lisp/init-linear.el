;;; init-linear.el --- Linear.app issues in Org  -*- lexical-binding: t; -*-

;; API key lives in the macOS Keychain, never in this config. Add it once:
;;   security add-internet-password -a apikey -s api.linear.app -w <KEY>
;; SPC l l = my open issues (Org file). Edit TODO state there to update Linear.

;; Layout of linear.org: * Project / ** Status / *** TODO BOU-123 Title.
;; Sync back only reads level-3 TODO state + properties, so this stays safe.
(defvar my/linear-status-order '("In Progress" "In Review" "Todo" "Backlog" "Blocked" "Triage")
  "Status groups in this order; unknown statuses follow alphabetically.")

(defvar my/linear-folded-statuses '("Done" "Canceled" "Cancelled" "Duplicate")
  "Status groups that start folded (TAB opens them).")

(defun my/linear--name (issue key)
  (let ((v (cdr (assoc key issue))))
    (and (consp v) (cdr (assoc 'name v)))))

(defun my/linear--entry (issue)
  "Org entry for ISSUE, with its ticket number (BOU-123) in the heading."
  (replace-regexp-in-string "\\`\\(\\*\\*\\* \\S-+ +\\(?:\\[#.\\] +\\)?\\)"
                            (format "\\1%s " (cdr (assoc 'identifier issue)))
                            (linear-emacs--format-issue-as-org-entry issue)))

(defun my/linear--sorted-groups (issues key-fn order-fn)
  (seq-sort-by (lambda (group) (funcall order-fn (car group)))
               (lambda (a b) (if (equal (car a) (car b)) (string< (cdr a) (cdr b)) (< (car a) (car b))))
               (seq-group-by key-fn issues)))

(defun my/linear-build-org-content (orig issues)
  "Header from ORIG, then ISSUES grouped by project and status."
  (concat
   (replace-regexp-in-string "#\\+STARTUP: overview" "#+STARTUP: content" (funcall orig nil))
   (mapconcat
    (lambda (project)
      (concat
       (format "* %s (%d)\n" (car project) (length (cdr project)))
       (mapconcat
        (lambda (status)
          (concat (format "** %s (%d)\n" (car status) (length (cdr status)))
                  (if (member (car status) my/linear-folded-statuses)
                      ":PROPERTIES:\n:VISIBILITY: folded\n:END:\n"
                    "")
                  (mapconcat #'my/linear--entry
                             (seq-sort-by (lambda (i) (cdr (assoc 'identifier i))) #'string< (cdr status))
                             "")))
        (my/linear--sorted-groups (cdr project)
                                  (lambda (i) (or (my/linear--name i 'state) "Unknown"))
                                  (lambda (s) (cons (or (seq-position my/linear-status-order s) 99) s)))
        "")))
    (my/linear--sorted-groups issues
                              (lambda (i) (or (my/linear--name i 'project) "No project"))
                              (lambda (p) (cons (if (equal p "No project") 1 0) p)))
    "")))

;; , t in Org: pick the new TODO state from a list (cycling would sync every
;; step). this-command must be org-todo: otherwise linear-emacs re-sends the
;; state of *every* ticket in the file instead of just this one.
(defun my/org-todo-choose ()
  "Set the TODO state of this heading, chosen with completion."
  (interactive)
  (let ((state (completing-read "State: " org-todo-keywords-1 nil t))
        (this-command 'org-todo))
    (org-todo state)))

(with-eval-after-load 'org
  (evil-define-key 'normal org-mode-map (kbd "<localleader>t") '("Set ticket state" . my/org-todo-choose)))

;; Sync a changed TODO state of one ticket back to Linear, in linear.org only.
;; (linear-emacs-enable-org-sync hooks the wrong buffer, and its after-save
;; hook would re-send the state of every ticket on each save.)
(defun my/linear-org-sync-setup ()
  (when (and buffer-file-name (bound-and-true-p linear-emacs-org-file-path)
             (file-equal-p buffer-file-name linear-emacs-org-file-path))
    (require 'linear-emacs)
    (add-hook 'org-after-todo-state-change-hook #'linear-emacs-sync-org-to-linear nil t)))

(add-hook 'org-mode-hook #'my/linear-org-sync-setup)

;; A refresh rewrites an open linear.org in place: re-apply the folding.
(defun my/linear-refold (&rest _)
  (when-let ((buf (find-buffer-visiting linear-emacs-org-file-path)))
    (with-current-buffer buf (org-cycle-set-startup-visibility))))

(use-package linear-emacs
  :vc (:url "https://github.com/anegg0/linear-emacs" :rev :newest)
  :commands (linear-emacs-list-issues linear-emacs-list-issues-by-project
             linear-emacs-new-issue linear-emacs-test-connection)
  :init
  (setq linear-emacs-org-file-path (expand-file-name "~/org/linear.org"))
  :config
  (let ((key (auth-source-pick-first-password :host "api.linear.app" :user "apikey")))
    (if key
        (setq linear-emacs-api-key key)
      (message "Linear: no API key in Keychain (see lisp/init-linear.el)")))
  (advice-add 'linear-emacs--build-org-content :around #'my/linear-build-org-content)
  (advice-add 'linear-emacs--update-org-from-issues :after #'my/linear-refold))

;; ---- One ticket: find (SPC l s), view as Markdown, comment (SPC l c) ----

(defun my/linear--get (alist &rest keys)
  "Walk the parsed JSON ALIST along KEYS."
  (dolist (key keys alist) (setq alist (cdr (assoc key alist)))))

(defun my/linear--query (query &optional vars)
  "Run GraphQL QUERY with VARS (alist); return its data or signal Linear's error."
  (require 'linear-emacs)
  (let ((response (linear-emacs--graphql-request query vars)))
    (cond ((null response) (user-error "Linear: no response"))
          ((assoc 'errors response)
           (user-error "Linear: %s" (my/linear--get (aref (cdr (assoc 'errors response)) 0) 'message)))
          (t (cdr (assoc 'data response))))))

(defun my/linear--label (issue)
  (format "%-9s %s  [%s · %s]" (cdr (assoc 'identifier issue)) (cdr (assoc 'title issue))
          (or (my/linear--name issue 'project) "No project") (my/linear--name issue 'state)))

(defun my/linear--choose (prompt issues)
  (let ((table (mapcar (lambda (i) (cons (my/linear--label i) (cdr (assoc 'identifier i)))) issues)))
    (cons table (completing-read prompt table))))

;; Pick one of my tickets, type a number (BOU-123) that isn't in the list,
;; or words + M-RET to search all of Linear.
(defun my/linear-read-ticket (prompt)
  (require 'linear-emacs)
  (pcase-let* ((`(,table . ,input) (my/linear--choose prompt (or linear-emacs--cache-issues
                                                                   (linear-emacs-get-issues))))
               (input (string-trim input)))
    (cond ((assoc input table) (cdr (assoc input table)))
          ((string-match-p "\\`[A-Za-z]+-[0-9]+\\'" input) (upcase input))
          ((string-empty-p input) (user-error "No ticket chosen"))
          (t (let ((found (append (my/linear--get
                                   (my/linear--query "query($term: String!) { searchIssues(term: $term, first: 30) { nodes { identifier title state { name } project { name } } } }"
                                                     `(("term" . ,input)))
                                   'searchIssues 'nodes)
                                  nil)))
               (unless found (user-error "No tickets match \"%s\"" input))
               (pcase-let ((`(,table . ,choice) (my/linear--choose (format "Results for \"%s\": " input) found)))
                 (or (cdr (assoc choice table)) (user-error "No ticket chosen"))))))))

(defun my/linear--ticket-at-point ()
  "Ticket number of the ticket view, project board line, or linear.org heading."
  (or (bound-and-true-p my/linear-ticket-id)
      (and (bound-and-true-p my/linear-board-mode)
           (save-excursion (beginning-of-line)
                           (and (re-search-forward "\\_<[A-Z]+-[0-9]+\\_>" (line-end-position) t)
                                (match-string 0))))
      (and (derived-mode-p 'org-mode) (org-entry-get nil "ID-LINEAR"))))

(defconst my/linear--issue-query
  "query($id: String!) { issue(id: $id) { id identifier title url description priorityLabel
     createdAt updatedAt state { name } project { name } team { name } assignee { name }
     creator { name } labels { nodes { name } }
     comments(first: 100) { nodes { body createdAt user { name } } } } }")

(defun my/linear--date (iso) (replace-regexp-in-string "T" " " (substring iso 0 16)))

(defun my/linear--render (issue)
  "ISSUE as Markdown: facts, description, comments (oldest first)."
  (let ((labels (mapconcat (lambda (l) (cdr (assoc 'name l))) (my/linear--get issue 'labels 'nodes) ", "))
        (comments (seq-sort-by (lambda (c) (cdr (assoc 'createdAt c))) #'string<
                               (append (my/linear--get issue 'comments 'nodes) nil))))
    (concat
     (format "# %s %s\n\n" (cdr (assoc 'identifier issue)) (cdr (assoc 'title issue)))
     (format "- **Status:** %s\n- **Project:** %s\n- **Priority:** %s\n"
             (my/linear--name issue 'state) (or (my/linear--name issue 'project) "none")
             (cdr (assoc 'priorityLabel issue)))
     (format "- **Assignee:** %s\n- **Created by:** %s, %s\n- **Updated:** %s\n"
             (or (my/linear--name issue 'assignee) "nobody") (or (my/linear--name issue 'creator) "?")
             (my/linear--date (cdr (assoc 'createdAt issue))) (my/linear--date (cdr (assoc 'updatedAt issue))))
     (if (string-empty-p labels) "" (format "- **Labels:** %s\n" labels))
     (format "- **Link:** %s\n\n## Description\n\n%s\n\n## Comments (%d)\n"
             (cdr (assoc 'url issue)) (or (cdr (assoc 'description issue)) "_No description._")
             (length comments))
     (mapconcat (lambda (c) (format "\n### %s, %s\n\n%s\n" (or (my/linear--name c 'user) "Linear")
                                    (my/linear--date (cdr (assoc 'createdAt c))) (cdr (assoc 'body c))))
                comments ""))))

(defvar-local my/linear-ticket-id nil)
(defvar-local my/linear-ticket-url nil)
(define-minor-mode my/linear-ticket-mode "Keys in a Linear ticket view." :keymap (make-sparse-keymap))

(defun my/linear-show-ticket (id)
  "Show Linear ticket ID (e.g. BOU-123) in a Markdown buffer."
  (interactive (list (my/linear-read-ticket "Ticket (number or words; M-RET searches all): ")))
  (let ((issue (my/linear--get (my/linear--query my/linear--issue-query `(("id" . ,id))) 'issue)))
    (unless issue (user-error "Ticket %s not found" id))
    (let ((buf (get-buffer-create (format "*Linear %s*" (cdr (assoc 'identifier issue))))))
      (with-current-buffer buf
        (let ((inhibit-read-only t)) (erase-buffer) (insert (my/linear--render issue)))
        (gfm-mode)
        (setq my/linear-ticket-id (cdr (assoc 'identifier issue))
              my/linear-ticket-url (cdr (assoc 'url issue))
              buffer-read-only t)
        (my/linear-ticket-mode 1)
        (evil-normalize-keymaps)
        (goto-char (point-min)))
      (pop-to-buffer buf))))

(defun my/linear-show-ticket-at-point ()
  "View the ticket under the cursor (linear.org), or ask for one."
  (interactive)
  (my/linear-show-ticket (or (my/linear--ticket-at-point) (my/linear-read-ticket "Ticket: "))))

(defun my/linear-ticket-refresh () (interactive) (my/linear-show-ticket my/linear-ticket-id))
(defun my/linear-ticket-browse () (interactive) (browse-url my/linear-ticket-url))

(defvar-local my/linear-comment-target nil "(UUID . NUMBER) of the ticket being commented on.")
(define-minor-mode my/linear-comment-mode "Keys while writing a Linear comment." :keymap (make-sparse-keymap))

(defun my/linear-add-comment ()
  "Write a comment (Markdown) for the ticket at point, or a chosen ticket."
  (interactive)
  (let* ((id (or (my/linear--ticket-at-point) (my/linear-read-ticket "Comment on ticket: ")))
         (uuid (my/linear--get (my/linear--query "query($id: String!) { issue(id: $id) { id } }"
                                                 `(("id" . ,id)))
                               'issue 'id))
         (buf (get-buffer-create (format "*Linear comment %s*" id))))
    (with-current-buffer buf
      (erase-buffer)
      (gfm-mode)
      (setq my/linear-comment-target (cons uuid id)
            header-line-format (format " Comment on %s:  , , send   , k cancel" id))
      (my/linear-comment-mode 1)
      (evil-normalize-keymaps))
    (pop-to-buffer buf)
    (evil-insert-state)))

(defun my/linear-comment-send ()
  "Post this buffer as a comment, then refresh the ticket view if open."
  (interactive)
  (let ((body (string-trim (buffer-substring-no-properties (point-min) (point-max))))
        (target my/linear-comment-target))
    (when (string-empty-p body) (user-error "Comment is empty"))
    (unless (eq t (my/linear--get (my/linear--query
                                   "mutation($id: String!, $body: String!) { commentCreate(input: {issueId: $id, body: $body}) { success } }"
                                   `(("id" . ,(car target)) ("body" . ,body)))
                                  'commentCreate 'success))
      (user-error "Linear did not accept the comment"))
    (quit-window t)
    (message "Comment added to %s" (cdr target))
    (when-let ((view (get-buffer (format "*Linear %s*" (cdr target)))))
      (with-current-buffer view (my/linear-ticket-refresh)))))

(defun my/linear-comment-cancel () (interactive) (quit-window t) (message "Comment discarded"))

(with-eval-after-load 'evil
  (evil-define-key 'normal my/linear-ticket-mode-map
    (kbd "<localleader>c") '("Comment" . my/linear-add-comment)
    (kbd "<localleader>r") '("Refresh" . my/linear-ticket-refresh)
    (kbd "<localleader>o") '("Open in browser" . my/linear-ticket-browse)
    "q" #'quit-window)
  (evil-define-key 'normal my/linear-comment-mode-map
    (kbd "<localleader>,") '("Send comment" . my/linear-comment-send)
    (kbd "<localleader>k") '("Cancel" . my/linear-comment-cancel))
  (evil-define-key 'normal org-mode-map (kbd "<localleader>v") '("Show ticket" . my/linear-show-ticket-at-point)))
(keymap-set my/linear-comment-mode-map "C-c C-c" #'my/linear-comment-send)
(keymap-set my/linear-comment-mode-map "C-c C-k" #'my/linear-comment-cancel)

;; ---- Project board (SPC l p): all open tickets of one project, by status ----
;; Separate buffer; linear.org (my own tickets) is left alone.
(defconst my/linear--board-query
  "query($id: String!) { project(id: $id) { name url
     issues(first: 250, filter: { state: { type: { in: [\"started\", \"unstarted\", \"backlog\"] } } }) {
       nodes { identifier title priority priorityLabel state { name type } assignee { name isMe } } } } }")

;; The board keeps the fetched project, so , a (assignee) refilters without a request.
(defvar-local my/linear-board-project-id nil)
(defvar-local my/linear-board-url nil)
(defvar-local my/linear-board-data nil "Fetched project (name, url, issues).")
(defvar-local my/linear-board-filter "All" "\"All\", \"Me\", \"Unassigned\" or a name.")
(define-minor-mode my/linear-board-mode "Keys in a Linear project board." :keymap (make-sparse-keymap))

(defun my/linear--assignee (issue)
  "\"Me\", \"Unassigned\" or the assignee's name."
  (let ((assignee (cdr (assoc 'assignee issue))))
    (cond ((null assignee) "Unassigned")
          ((eq t (cdr (assoc 'isMe assignee))) "Me")
          (t (cdr (assoc 'name assignee))))))

(defun my/linear--board-issues (project &optional filter)
  (let ((issues (append (my/linear--get project 'issues 'nodes) nil)))
    (if (member filter '(nil "All")) issues
      (seq-filter (lambda (i) (equal (my/linear--assignee i) filter)) issues))))

(defun my/linear--choose-assignee (project)
  "Ask who: All, Me, Unassigned, then everyone with tickets (with counts)."
  (let* ((counts (mapcar (lambda (g) (cons (car g) (length (cdr g))))
                         (seq-group-by #'my/linear--assignee (my/linear--board-issues project))))
         (others (sort (seq-remove (lambda (n) (member n '("Me" "Unassigned"))) (mapcar #'car counts))
                       #'string<))
         (names (append '("All") (seq-filter (lambda (n) (assoc n counts)) '("Me" "Unassigned")) others))
         (table (mapcar (lambda (n) (cons (format "%s (%d)" n (if (equal n "All")
                                                                  (apply #'+ (mapcar #'cdr counts))
                                                                (cdr (assoc n counts))))
                                         n))
                        names)))
    (cdr (assoc (completing-read "Assignee: " table nil t) table))))

(defun my/linear--board-line (issue)
  (format "- %-9s %s  /%s · %s/\n" (cdr (assoc 'identifier issue)) (cdr (assoc 'title issue))
          (downcase (my/linear--assignee issue)) (cdr (assoc 'priorityLabel issue))))

(defun my/linear--board-content (project filter)
  "PROJECT's open issues for FILTER as Org: In Progress first, then Todo, then Backlog."
  (let* ((type-rank '(("started" . 0) ("unstarted" . 1) ("backlog" . 2)))
         (issues (my/linear--board-issues project filter))
         (groups (seq-sort-by
                  (lambda (g) (cdr (assoc (my/linear--get (cadr g) 'state 'type) type-rank))) #'<
                  (seq-group-by (lambda (i) (my/linear--get i 'state 'name)) issues))))
    (concat
     (format "#+title: %s\n" (cdr (assoc 'name project)))
     (format "Assignee: %s — %d of %d open tickets\n" filter (length issues)
             (length (my/linear--board-issues project)))
     "RET / , v show ticket   , a assignee   , c comment   , r refresh   , o browser   q close\n\n"
     (if groups "" "No open tickets.\n")
     (mapconcat
      (lambda (g)
        (concat (format "* %s (%d)\n" (car g) (length (cdr g)))
                (mapconcat #'my/linear--board-line
                           ;; urgent first; "no priority" (0) last
                           (seq-sort-by (lambda (i) (let ((p (cdr (assoc 'priority i)))) (if (eq p 0) 5 p)))
                                        #'< (cdr g))
                           "")))
      groups ""))))

(defun my/linear--board-render ()
  (let ((inhibit-read-only t))
    (erase-buffer)
    (insert (my/linear--board-content my/linear-board-data my/linear-board-filter))
    (goto-char (point-min))))

(defun my/linear-project-board (project-id &optional filter)
  "Show open tickets of a project, grouped by status, for one assignee or all."
  (interactive
   (progn (require 'linear-emacs)
          (let* ((team (linear-emacs-select-team))
                 (project (and team (linear-emacs-select-project (cdr (assoc 'id team))))))
            (list (or (cdr (assoc 'id project)) (user-error "No project chosen"))))))
  (let* ((project (my/linear--get (my/linear--query my/linear--board-query `(("id" . ,project-id))) 'project))
         (filter (or filter (my/linear--choose-assignee project)))
         (buf (get-buffer-create (format "*Linear: %s*" (cdr (assoc 'name project))))))
    (with-current-buffer buf
      (org-mode)
      (setq my/linear-board-project-id project-id
            my/linear-board-url (cdr (assoc 'url project))
            my/linear-board-data project
            my/linear-board-filter filter)
      (my/linear--board-render)
      (setq buffer-read-only t)
      (my/linear-board-mode 1)
      (evil-normalize-keymaps))
    (pop-to-buffer buf)))

(defun my/linear-board-assignee ()
  "Show the board for another assignee (no new request)."
  (interactive)
  (setq my/linear-board-filter (my/linear--choose-assignee my/linear-board-data))
  (my/linear--board-render))

(defun my/linear-board-refresh ()
  (interactive)
  (my/linear-project-board my/linear-board-project-id my/linear-board-filter))
(defun my/linear-board-browse () (interactive) (browse-url my/linear-board-url))

(with-eval-after-load 'evil
  (evil-define-key 'normal my/linear-board-mode-map
    (kbd "RET") '("Show ticket" . my/linear-show-ticket-at-point)
    (kbd "<localleader>v") '("Show ticket" . my/linear-show-ticket-at-point)
    (kbd "<localleader>a") '("Choose assignee" . my/linear-board-assignee)
    (kbd "<localleader>c") '("Comment" . my/linear-add-comment)
    (kbd "<localleader>r") '("Refresh" . my/linear-board-refresh)
    (kbd "<localleader>o") '("Open project in browser" . my/linear-board-browse)
    "q" #'quit-window))

(provide 'init-linear)
