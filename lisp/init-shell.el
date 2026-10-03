;;; init-shell.el --- Bash / sh / Zsh scripts  -*- lexical-binding: t; -*-

;; Bash/sh: tree-sitter colors (variables in strings, commands), LSP with
;; ShellCheck checks, completion, K docs, SPC c f formatting (shfmt).
;; Zsh (.zshrc, .zsh): sh-mode colors only; no tree-sitter/ShellCheck for zsh.
(setq treesit-language-source-alist
      '((bash "https://github.com/tree-sitter/tree-sitter-bash" "v0.21.0")))

;; Compile the bash grammar once into ~/.emacs.d/tree-sitter/ (needs cc).
(defun my/ensure-bash-grammar ()
  (or (treesit-language-available-p 'bash)
      (ignore-errors (treesit-install-language-grammar 'bash))))

(when (and (treesit-available-p) (my/ensure-bash-grammar))
  (add-to-list 'auto-mode-alist '("\\.\\(sh\\|bash\\)\\'" . bash-ts-mode))
  (add-to-list 'interpreter-mode-alist '("\\(ba\\|da\\)?sh" . bash-ts-mode)))

(use-package sh-script
  :ensure nil
  :hook (bash-ts-mode . (lambda () (my/eglot-if "bash-language-server"))))

(provide 'init-shell)
