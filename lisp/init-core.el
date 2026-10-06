;;; init-core.el --- General editor behaviour  -*- lexical-binding: t; -*-

;; Keep backup and autosave files out of project folders.
(setq backup-directory-alist `(("." . ,(expand-file-name "backups" user-emacs-directory)))
      auto-save-file-name-transforms `((".*" ,(expand-file-name "auto-save-list/" user-emacs-directory) t))
      create-lockfiles nil)

(setq-default indent-tabs-mode nil   ; spaces, not tabs
              tab-width 4
              fill-column 100)

(setq ring-bell-function 'ignore
      use-short-answers t            ; y/n instead of yes/no
      require-final-newline t)

(global-auto-revert-mode 1)          ; reload files changed on disk
(save-place-mode 1)                  ; reopen files at last position
(savehist-mode 1)                    ; remember minibuffer history
(recentf-mode 1)                     ; track recent files
(electric-pair-mode 1)               ; auto close brackets/quotes
(delete-selection-mode 1)

;; URLs: gx opens the one under the cursor in the default browser (vim style).
;; Make them visible and clickable in code comments/strings and text files.
(add-hook 'prog-mode-hook #'goto-address-prog-mode)
(add-hook 'text-mode-hook #'goto-address-mode)

;; macOS: Cmd = Meta, Option stays Option (for special chars).
(when (eq system-type 'darwin)
  (setq mac-command-modifier 'meta
        mac-option-modifier 'none))

;; Cmd-V paste / Cmd-C copy selection, like other Mac apps (also in prompts).
(keymap-global-set "M-v" #'yank)
(keymap-global-set "M-c" #'kill-ring-save)

;; Secrets (Linear key, GitHub token for Forge) live in the macOS Keychain as
;; *internet* passwords: Emacs matches -s (server) and -a (account) there.
;; (For generic passwords it matches -c, so `add-generic-password -s` isn't found.)
(setq auth-sources '(macos-keychain-internet "~/.authinfo.gpg"))

;; GUI Emacs and the daemon on macOS do not see your shell PATH; this fixes it.
;; Needed to find pandoc, clojure-lsp, pyright, etc. (all in /opt/homebrew/bin).
(use-package exec-path-from-shell
  :if (eq system-type 'darwin)
  :config (exec-path-from-shell-initialize))

;; Reload every lisp/init-*.el without restarting (also in daemon).
;; Bound to SPC h r. Removed settings stay active until restart.
(defun my/reload-config ()
  "Reload all config files in lisp/."
  (interactive)
  (dolist (file (directory-files (expand-file-name "lisp" user-emacs-directory) t "^init-.*\\.el$"))
    (load file nil 'nomessage))
  (message "Config reloaded"))

;; SPC b d. Previews (eww) and terminals also close their window; Claude is only hidden.
;; Killing a markdown/asciidoc file closes its preview too.
(defun my/kill-buffer-and-window (buffer)
  (dolist (window (get-buffer-window-list buffer nil t))
    (ignore-errors (delete-window window)))   ; fails only on the last window
  (kill-buffer buffer))

(defun my/kill-buffer ()
  "Kill current buffer, closing any related preview."
  (interactive)
  (when (derived-mode-p 'markdown-mode 'adoc-mode)
    (dolist (buffer (buffer-list))
      (when (eq (buffer-local-value 'major-mode buffer) 'eww-mode)
        (my/kill-buffer-and-window buffer))))
  (cond
   ((bound-and-true-p claude-code-ide--session)    ; Claude: only hide, keep it running
    (dolist (window (get-buffer-window-list nil nil t))
      (unless (ignore-errors (delete-window window) t)
        (switch-to-prev-buffer window 'bury))))
   ((derived-mode-p 'eww-mode)
    (my/kill-buffer-and-window (current-buffer)))
   ((derived-mode-p 'vterm-mode 'eat-mode)         ; terminal: no confirm prompt
    (when-let ((process (get-buffer-process (current-buffer))))
      (set-process-query-on-exit-flag process nil))
    (my/kill-buffer-and-window (current-buffer)))
   (t (kill-current-buffer))))

(provide 'init-core)
