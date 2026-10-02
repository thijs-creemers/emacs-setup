;;; init-git.el --- Git: Magit + changed lines in the margin  -*- lexical-binding: t; -*-

;; Magit: full git UI. SPC g g, then press ? for all keys.
(use-package magit
  :commands (magit-status magit-blame-addition magit-log-buffer-file magit-diff-range)
  :custom
  (magit-display-buffer-function #'magit-display-buffer-same-window-except-diff-v1)
  (magit-bury-buffer-function #'magit-restore-window-configuration) ; q = layout as before
  (magit-save-repository-buffers 'dontask))  ; save open files before git commands

;; Esc closes Magit's key popups (c, P, b, ...) instead of only C-g.
(with-eval-after-load 'transient
  (keymap-set transient-map "<escape>" #'transient-quit-one))

;; Commit message window: , , = finish (commit)  , k = cancel.
;; (Same as C-c C-c / C-c C-k.)
(with-eval-after-load 'with-editor
  (evil-define-key 'normal with-editor-mode-map
    (kbd "<localleader>,") #'with-editor-finish
    (kbd "<localleader>k") #'with-editor-cancel))

;; Colored bars in the margin for added/changed/deleted lines (like gitsigns).
;; flydiff = also for unsaved changes.
(use-package diff-hl
  :hook ((magit-pre-refresh  . diff-hl-magit-pre-refresh)
         (magit-post-refresh . diff-hl-magit-post-refresh))
  :config
  (global-diff-hl-mode 1)
  (diff-hl-flydiff-mode 1))

(defun my/magit-diff-branch-vs-main ()
  "Show all changes of this branch compared to main."
  (interactive)
  (magit-diff-range "main...HEAD"))

(provide 'init-git)
