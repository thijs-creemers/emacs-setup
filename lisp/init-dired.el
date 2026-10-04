;;; init-dired.el --- Dired: file manager (move, rename, delete)  -*- lexical-binding: t; -*-

;; Open: SPC o d (folder of this file), SPC o D (project root). Keys: KEYS.md.
;; Two Dired windows side by side: R (move) / C (copy) target the other one.
(use-package dired
  :ensure nil
  :hook (dired-mode . dired-hide-details-mode)           ; ( shows details
  :custom
  (insert-directory-program (or (executable-find "gls") "ls"))  ; GNU ls (macOS ls lacks options)
  (dired-listing-switches "-alh --group-directories-first")
  (dired-dwim-target t)
  (dired-kill-when-opening-new-dired-buffer t)            ; one Dired buffer, not one per folder
  (dired-recursive-copies 'always)
  (dired-recursive-deletes 'top)                          ; ask once per folder
  (delete-by-moving-to-trash t)                           ; D goes to the macOS Trash
  (dired-auto-revert-buffer t))

;; i = edit file names as text (rename many at once); , , apply, , k cancel.
(use-package wdired
  :ensure nil
  :custom (wdired-allow-to-change-permissions t)
  :config
  (evil-define-key 'normal wdired-mode-map
    (kbd "<localleader>,") '("Apply renames" . wdired-finish-edit)
    (kbd "<localleader>k") '("Cancel" . wdired-abort-changes)))

;; File and folder icons (Nerd Font).
(use-package nerd-icons-dired
  :hook (dired-mode . nerd-icons-dired-mode))

(defun my/dired-project-root ()
  "Dired at the project root."
  (interactive)
  (dired (project-root (project-current t))))

(provide 'init-dired)
