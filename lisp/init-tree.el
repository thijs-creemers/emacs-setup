;;; init-tree.el --- Project tree sidebar (Treemacs)  -*- lexical-binding: t; -*-

;; SPC o p shows/hides the tree of the current project (follows project and
;; open file). Git status colors per file; ? in the tree shows all keys.
(use-package treemacs
  :commands (treemacs treemacs-select-window)
  :custom
  (treemacs-width 32)
  (treemacs-collapse-dirs 3)                  ; a/b/c shown on one line if single child
  :config
  (treemacs-follow-mode 1)                    ; highlight the file you're editing
  (treemacs-project-follow-mode 1)            ; always show the current project
  (treemacs-filewatch-mode 1)                 ; refresh when files change on disk
  (treemacs-git-mode 'deferred)               ; git colors, computed in the background
  (treemacs-fringe-indicator-mode 'always))

;; SPC o p: plain `treemacs' asks "Project root:" on an empty workspace; this
;; shows the current project straight away, or hides the tree when open.
(defun my/project-tree ()
  "Show/hide the tree of the current project."
  (interactive)
  (require 'treemacs)
  (if (eq (treemacs-current-visibility) 'visible)
      (delete-window (treemacs-get-local-window))
    (if (project-current)
        (treemacs-add-and-display-current-project-exclusively)
      (treemacs))))

(use-package treemacs-evil :after (treemacs evil))
(use-package treemacs-magit :after (treemacs magit))   ; refresh git colors after Magit

;; Same Nerd Font icons as Dired and the status bar.
(use-package treemacs-nerd-icons
  :after treemacs
  :config (treemacs-load-theme "nerd-icons"))

(provide 'init-tree)
