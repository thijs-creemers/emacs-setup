;;; init-completion.el --- Minibuffer and in-buffer completion  -*- lexical-binding: t; -*-

;; Vertical list in the minibuffer (M-x, find-file, ...).
;; C-j / C-k move up and down, like Telescope.
(use-package vertico
  :demand t                            ; :bind would delay loading otherwise
  :custom (vertico-count 15)
  :bind (:map vertico-map
              ("C-j" . vertico-next)
              ("C-k" . vertico-previous))
  :config
  (vertico-mode 1)
  (vertico-multiform-mode 1))

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

;; Popup completion while typing code; gets candidates from LSP/cider.
(use-package corfu
  :custom
  (corfu-auto t)
  (corfu-auto-delay 0.2)
  (corfu-auto-prefix 2)
  :config (global-corfu-mode 1))

(provide 'init-completion)
