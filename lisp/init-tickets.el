;;; init-tickets.el --- SPC l: same ticket keys for Linear and Jira  -*- lexical-binding: t; -*-

;; Each project remembers its ticket system (asked the first time, SPC l b changes it).
;; Ticket buffers (linear.org, jira.org, views, boards) always use their own system.
;; Saved in tickets-backends.eld (git-ignored).

(defvar my/tickets-backends-file (expand-file-name "tickets-backends.eld" user-emacs-directory))

(defvar my/tickets-backends
  (ignore-errors (with-temp-buffer (insert-file-contents my/tickets-backends-file) (read (current-buffer))))
  "Alist: project root (or \"global\" outside projects) -> linear or jira.")

(defun my/tickets--project-key ()
  (if-let* ((project (project-current))) (abbreviate-file-name (project-root project)) "global"))

(defun my/tickets--buffer-backend ()
  "Backend of the current ticket buffer, nil in other buffers."
  (cond ((or (bound-and-true-p my/jira-org-mode) (bound-and-true-p my/jira-ticket-mode)
             (bound-and-true-p my/jira-board-mode) (bound-and-true-p my/jira-compose-mode))
         'jira)
        ((or (bound-and-true-p my/linear-ticket-mode) (bound-and-true-p my/linear-board-mode)
             (bound-and-true-p my/linear-comment-mode)
             (and buffer-file-name (bound-and-true-p linear-emacs-org-file-path)
                  (file-equal-p buffer-file-name linear-emacs-org-file-path)))
         'linear)))

(defun my/tickets-choose-backend ()
  "Choose the ticket system (Linear or Jira) for this project."
  (interactive)
  (let* ((key (my/tickets--project-key))
         (backend (intern (downcase (completing-read (format "Ticket system for %s: " key)
                                                     '("Jira" "Linear") nil t)))))
    (setf (alist-get key my/tickets-backends nil nil #'equal) backend)
    (with-temp-file my/tickets-backends-file (prin1 my/tickets-backends (current-buffer)))
    (message "%s uses %s" key (capitalize (symbol-name backend)))
    backend))

(defun my/tickets-backend ()
  (or (my/tickets--buffer-backend)
      (alist-get (my/tickets--project-key) my/tickets-backends nil nil #'equal)
      (my/tickets-choose-backend)))

(defmacro my/tickets--define (name doc linear jira)
  "Define command NAME that runs LINEAR or JIRA for the current ticket system."
  `(defun ,name ()
     ,doc
     (interactive)
     (call-interactively (if (eq (my/tickets-backend) 'jira) #',jira #',linear))))

(my/tickets--define my/tickets-my-issues "My open tickets." linear-emacs-list-issues my/jira-my-issues)
(my/tickets--define my/tickets-board "Project board." my/linear-project-board my/jira-project-board)
(my/tickets--define my/tickets-new "New ticket." linear-emacs-new-issue my/jira-new-issue)
(my/tickets--define my/tickets-find "Find and show one ticket." my/linear-show-ticket my/jira-show-ticket)
(my/tickets--define my/tickets-comment "Comment on a ticket." my/linear-add-comment my/jira-add-comment)

(provide 'init-tickets)
