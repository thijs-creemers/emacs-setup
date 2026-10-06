;;; init-completion.el --- Minibuffer and in-buffer completion  -*- lexical-binding: t; -*-

;; Vertical list in the minibuffer (M-x, find-file, ...).
;; C-j / C-k move up and down, like Telescope.
(use-package vertico
  :demand t                            ; :bind would delay loading otherwise
  :custom (vertico-count 15)
  :bind (:map vertico-map
              ("C-j" . vertico-next)
              ("C-k" . vertico-previous)
              ;; File prompts: Backspace after "/" goes to the parent folder,
              ;; M-Backspace removes one folder/word. Other prompts: normal.
              ("DEL" . vertico-directory-delete-char)
              ("M-DEL" . vertico-directory-delete-word))
  :config
  (vertico-mode 1)
  (vertico-multiform-mode 1)
  ;; Typing ~/ or / after a path drops the old part: ~/a/b/~/ -> ~/
  (add-hook 'rfn-eshadow-update-overlay-hook #'vertico-directory-tidy))

;; Layout: search commands show list left, preview right (Telescope).
;; Everything else (M-x, project picker, prompts): normal minibuffer.
(let ((side-by-side '(buffer (vertico-buffer-display-action
                              . (display-buffer-in-side-window
                                 (side . left) (window-width . 0.4))))))
  (setq vertico-multiform-categories `((project-finder ,@side-by-side))
        vertico-multiform-commands
        (mapcar (lambda (cmd) (cons cmd side-by-side))
                '(consult-ripgrep consult-buffer consult-recent-file
                  consult-line consult-imenu consult-flymake))))

;; Fuzzy matching: "icl" finds "init-clojure.el".
;; Words in any order also work: "clj core" finds "src/demo/core.clj".
(use-package orderless
  :custom
  (completion-styles '(orderless basic))
  (orderless-matching-styles '(orderless-literal orderless-regexp orderless-flex))
  (completion-category-overrides '((file (styles basic partial-completion orderless)))))

;; Extra info next to candidates (docstrings, file sizes).
(use-package marginalia
  :config (marginalia-mode 1))

;; Better search/switch commands (consult-line, consult-ripgrep, ...).
(use-package consult)

;; Telescope-style "find files": all project files, fuzzy, with preview.
;; Uses git ls-files (respects .gitignore); outside a project it asks for one.
(defun my/find-file-in-project ()
  "Fuzzy find a file in the current project with live preview."
  (interactive)
  (let* ((project (project-current t))
         (default-directory (project-root project))
         (files (mapcar #'file-relative-name (project-files project))))
    (find-file (consult--read files
                              :prompt "Find file: "
                              :category 'project-finder
                              :state (consult--file-preview)
                              :require-match t))))

;; SPC p p: pick a project, then go straight to the file finder.
(setq project-switch-commands #'my/find-file-in-project)

;; ---- Keep the project list (SPC p p) clean ----
;; Never remember temp folders or package sources; SPC p c removes them plus
;; projects whose folder is gone. Gone folders are also dropped at startup.
(defvar my/project-ignore-regexp
  (rx (or (seq bos (or "/tmp/" "/private/tmp/" "/var/folders/" "/private/var/folders/"))
          "/.emacs.d/elpa/"))
  "Project roots matching this are not added to the project list.")

(defun my/project-ignored-p (root)
  (string-match-p my/project-ignore-regexp (expand-file-name root)))

(define-advice project-remember-project (:around (orig project &rest args) skip-ignored)
  (unless (my/project-ignored-p (project-root project))
    (apply orig project args)))

(defun my/project-cleanup ()
  "Forget projects whose folder is gone, temp folders and package sources."
  (interactive)
  (let ((before (length (project-known-project-roots))))
    (project-forget-zombie-projects)
    (dolist (root (project-known-project-roots))
      (when (my/project-ignored-p root) (project-forget-project root)))
    (message "Project list: removed %d, %d left"
             (- before (length (project-known-project-roots)))
             (length (project-known-project-roots)))))

(add-hook 'emacs-startup-hook #'project-forget-zombie-projects)

;; Embark: actions on the highlighted item in any list. C-. = action menu
;; (open in split, copy path, delete file, ...). Kill buffer keeps the list open.
(use-package embark
  :bind (("C-." . embark-act))
  :custom (embark-quit-after-action '((kill-buffer . nil) (t . t))))

(use-package embark-consult
  :after (embark consult))

;; C-d in a buffer list (SPC b b): close the highlighted buffer, list refreshes.
;; In other prompts C-d stays "delete character".
(defun my/vertico-kill-buffer ()
  (interactive)
  (require 'embark)
  (let ((target (car (embark--targets))))
    (if (eq (plist-get target :type) 'buffer)
        (progn (kill-buffer (plist-get target :target))  ; Embark gives the clean name
               (embark--restart))                         ; reopen list, same input
      (call-interactively #'delete-char))))

(keymap-set vertico-map "C-d" #'my/vertico-kill-buffer)

;; Popup completion while typing code; gets candidates from LSP/cider.
(use-package corfu
  :custom
  (corfu-auto t)
  (corfu-auto-delay 0.2)
  (corfu-auto-prefix 2)
  :config (global-corfu-mode 1))

(provide 'init-completion)
