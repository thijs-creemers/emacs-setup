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

;; Forge: GitHub PRs and issues inside Magit (@ in Magit for its menu).
;; Token: Keychain internet password, server api.github.com, account "<user>^forge".
;; Per repo once: M-x forge-add-repository (pulls PRs/issues into a local db).
(use-package forge
  :after magit)

;; SPC g c: live CI status of this branch's PR, as on GitHub (gh in vterm).
(defun my/gh-pr-checks ()
  "Show `gh pr checks --watch' for the current branch in a bottom window."
  (interactive)
  (let* ((root (project-root (project-current t)))
         (name (format "*gh checks %s*" (file-name-nondirectory (directory-file-name root))))
         (new (not (get-buffer name)))
         (buf (progn (save-window-excursion (my/vterm-in root name)) (get-buffer name))))
    (display-buffer buf '((display-buffer-in-side-window) (side . bottom) (window-height . 0.3)))
    (when new
      (with-current-buffer buf (vterm-send-string "gh pr checks --watch\n")))))

(provide 'init-git)
