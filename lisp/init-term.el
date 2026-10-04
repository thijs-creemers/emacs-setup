;;; init-term.el --- Terminal + babashka task runner  -*- lexical-binding: t; -*-

;; vterm: terminal on libvterm (C), near-native speed. Main terminal.
;; Starts in insert mode; Esc for vim keys. Close: SPC b d, or type exit.
;; Module compiles once on first use (needs cmake).
(use-package vterm
  :commands (vterm)
  :custom
  (vterm-always-compile-module t)      ; compile without asking
  (vterm-max-scrollback 10000)
  (vterm-kill-buffer-on-exit t)
  :config (evil-set-initial-state 'vterm-mode 'insert))

;; Open vterm in DIR. Passes the project's .env explicitly: vterm starts
;; the shell before the .env hook (init-env.el) would run.
(defun my/vterm-in (dir name)
  (with-temp-buffer
    (setq default-directory dir)
    (let ((process-environment (append (my/project-env-vars dir)
                                       (default-value 'process-environment))))
      (vterm name))))

(defun my/vterm-project ()
  "Terminal in the project root (reuses it when open)."
  (interactive)
  (let ((root (project-root (project-current t))))
    (my/vterm-in root (format "*vterm %s*" (file-name-nondirectory (directory-file-name root))))))

(defun my/vterm-here ()
  "New terminal in the current directory."
  (interactive)
  (my/vterm-in default-directory (generate-new-buffer-name "*vterm*")))

;; eat: pure Lisp terminal, kept as fallback (M-x eat).
;; macOS's old ncurses can't read eat's terminfo files, so the shell falls
;; back to a dumb mode (Backspace doesn't redraw). Compile them once with tic.
(defun my/eat-use-macos-terminfo ()
  (let ((dir (expand-file-name "eat-terminfo/" user-emacs-directory)))
    (unless (file-directory-p dir)
      (make-directory dir t)
      (call-process "tic" nil nil nil "-x" "-o" dir
                    (expand-file-name "eat.ti" (file-name-directory (locate-library "eat")))))
    (setq eat-term-terminfo-directory dir)))

(use-package eat
  :commands (eat eat-project)
  :custom (eat-kill-buffer-on-exit t)
  :config
  (evil-set-initial-state 'eat-mode 'insert)
  (when (eq system-type 'darwin) (my/eat-use-macos-terminfo)))

;; SPC t b: pick a task from the nearest bb.edn and run it at that root.
;; Runs in a compilation buffer: errors are clickable, input works, q closes.
(defun my/bb-task ()
  "Choose and run a babashka task."
  (interactive)
  (let* ((root (or (locate-dominating-file default-directory "bb.edn")
                   (user-error "No bb.edn found above %s" default-directory)))
         (default-directory root)
         (tasks (seq-keep (lambda (line)
                            (when (string-match "\\`\\([^ \t]+\\)[ \t]*\\(.*\\)\\'" line)
                              (cons (match-string 1 line) (match-string 2 line))))
                          (cdr (process-lines "bb" "tasks"))))  ; skip header line
         (completion-extra-properties
          `(:annotation-function ,(lambda (task) (concat "  " (cdr (assoc task tasks))))))
         (task (completing-read (format "bb task (%s): " (file-name-nondirectory
                                                          (directory-file-name root)))
                                tasks nil t)))
    (compile (concat "bb " task) t)))

(provide 'init-term)
