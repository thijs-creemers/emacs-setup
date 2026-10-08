;;; init-buffers.el --- Buffer groups: list them, close a whole group  -*- lexical-binding: t; -*-

;; SPC b i (ibuffer) shows buffers per group; C on a group line closes the group.
;; SPC b k closes all buffers of one group from anywhere ("Magit (7)").
;; A buffer belongs to the first group that matches (ibuffer filter syntax).

(require 'ibuf-ext)

(defvar my/buffer-groups
  '(("Claude (closing stops it)" (name . "\\`\\*claude-code\\["))
    ("Magit" (or (derived-mode . magit-mode) (name . "\\`magit")))
    ("Terminals" (or (mode . vterm-mode) (mode . eat-mode) (mode . shell-mode) (mode . eshell-mode)))
    ("Tickets" (or (name . "\\`\\*\\(Linear\\|Jira\\)")
                   (filename . "/org/\\(linear\\|jira\\)\\.org\\'")))
    ("Dired" (mode . dired-mode))
    ("Previews" (mode . eww-mode))
    ("Help and logs" (or (derived-mode . help-mode) (derived-mode . compilation-mode)
                         (derived-mode . special-mode)
                         (name . "\\`\\*\\(Messages\\|Warnings\\|Backtrace\\|Async-native\\|Native-compile\\|EGLOT\\|Flymake\\|Compile-Log\\|Shell Command\\)")))
    ("Files" (visiting-file)))
  "Buffer groups, most specific first.")

(defun my/buffer-group (buffer)
  "Name of the first group in `my/buffer-groups' that BUFFER belongs to, or \"Default\" (ibuffer's name)."
  (or (car (seq-find (lambda (group) (ibuffer-included-in-filters-p buffer (cdr group)))
                     my/buffer-groups))
      "Default"))

(defun my/buffers-in-group (name)
  (seq-filter (lambda (b) (and (not (string-prefix-p " " (buffer-name b)))
                               (equal (my/buffer-group b) name)))
              (buffer-list)))

(defun my/kill-buffer-group (name)
  "Close all buffers of group NAME, after one confirmation."
  (let ((buffers (my/buffers-in-group name)))
    (unless buffers (user-error "No %s buffers" name))
    (when (y-or-n-p (format "Close %d %s buffer%s? " (length buffers) name (if (cdr buffers) "s" "")))
      (dolist (b buffers)
        (when-let* ((process (get-buffer-process b)))       ; terminals: no extra question
          (set-process-query-on-exit-flag process nil))
        (kill-buffer b))                                     ; unsaved files still ask
      (message "Closed %d %s buffers" (length buffers) name))))

(defun my/kill-buffers-of-kind ()
  "Choose a group (with counts) and close all its buffers."
  (interactive)
  (let* ((names (append (mapcar #'car my/buffer-groups) '("Default")))
         (table (delq nil (mapcar (lambda (n) (let ((count (length (my/buffers-in-group n))))
                                                (and (> count 0) (cons (format "%s (%d)" n count) n))))
                                  names))))
    (unless table (user-error "No buffers"))
    (my/kill-buffer-group (cdr (assoc (completing-read "Close all buffers of: " table nil t) table)))))

;; ibuffer: same groups, empty ones hidden.
(setq ibuffer-saved-filter-groups `(("my" ,@my/buffer-groups))
      ibuffer-show-empty-filter-groups nil)
(add-hook 'ibuffer-mode-hook (lambda () (ibuffer-switch-to-saved-filter-groups "my")))

(defun my/ibuffer-kill-group ()
  "Close the group under the cursor (on its header or one of its buffers)."
  (interactive)
  (let* ((header (get-text-property (point) 'ibuffer-filter-group-name))
         (buffer (ignore-errors (ibuffer-current-buffer)))
         (name (cond ((stringp header) header) (buffer (my/buffer-group buffer)))))
    (unless name (user-error "Not on a group"))
    (my/kill-buffer-group name)
    (ibuffer-update nil t)))

(with-eval-after-load 'evil
  (evil-define-key 'normal ibuffer-mode-map           ; "," is ibuffer's sort key
    "C" '("Close this group" . my/ibuffer-kill-group)))

(provide 'init-buffers)
