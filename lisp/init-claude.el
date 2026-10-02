;;; init-claude.el --- Claude Code CLI inside Emacs (claude-code-ide.el)  -*- lexical-binding: t; -*-

;; Claude runs in a side window and talks to Emacs over MCP: it sees the file
;; and selection you are on, opens diffs in ediff, and can use xref/imenu/LSP.
;; Keys under SPC a (same as claudecode.nvim). Menu with everything: SPC a m
(use-package claude-code-ide
  :vc (:url "https://github.com/manzaltu/claude-code-ide.el" :rev :newest)
  :commands (claude-code-ide claude-code-ide-menu claude-code-ide-toggle)
  :custom
  (claude-code-ide-terminal-backend 'vterm)
  (claude-code-ide-window-side 'right)
  (claude-code-ide-window-width 90)
  :config
  (claude-code-ide-emacs-tools-setup))   ; give Claude xref, imenu, project tools

(defun my/claude-toggle ()
  "Show/hide Claude for this project; start it when not running."
  (interactive)
  (require 'claude-code-ide)
  (condition-case nil
      (claude-code-ide-toggle)
    (user-error (claude-code-ide))))

;; Diffs open in ediff. Accept / deny from anywhere instead of q + y/n.
(defun my/claude-diff-quit (accept)
  (let ((control (seq-find (lambda (b) (eq (buffer-local-value 'major-mode b) 'ediff-mode))
                           (buffer-list))))
    (unless control (user-error "No Claude diff open"))
    (with-current-buffer control
      (cl-letf (((symbol-function 'y-or-n-p)       ; "Quit?" -> yes, "Accept?" -> ACCEPT
                 (lambda (prompt &rest _) (if (string-match-p "Accept" prompt) accept t))))
        (ediff-quit nil)))))

(defun my/claude-accept-diff () "Accept Claude's change." (interactive) (my/claude-diff-quit t))
(defun my/claude-deny-diff ()   "Reject Claude's change." (interactive) (my/claude-diff-quit nil))

(provide 'init-claude)
