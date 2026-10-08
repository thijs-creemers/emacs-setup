;;; init.el --- Entry point: loads one file per topic from lisp/  -*- lexical-binding: t; -*-

(add-to-list 'load-path (expand-file-name "lisp" user-emacs-directory))

;; Customize writes its junk here, not in init.el.
(setq custom-file (expand-file-name "custom.el" user-emacs-directory))
(load custom-file 'noerror)

(require 'init-packages)    ; package archives + use-package
(require 'init-core)        ; sane defaults, backups, macOS
(require 'init-env)         ; .env from project root per buffer
(require 'init-ui)          ; theme, font, line numbers
(require 'init-evil)        ; vim keys + leader key (SPC)
(require 'init-buffers)     ; buffer groups, close a whole group
(require 'init-completion)  ; vertico, consult, corfu
(require 'init-lsp)         ; eglot (built-in LSP client)
(require 'init-clojure)     ; clojure-mode + cider + parinfer
(require 'init-paredit)     ; slurp/barf/drag/raise (nvim-paredit keys)
(require 'init-python)      ; python + pyright
(require 'init-yaml)        ; yaml-mode
(require 'init-shell)       ; bash/zsh: tree-sitter, LSP, ShellCheck
(require 'init-preview)     ; GitHub-style previews (browser + eww)
(require 'init-markdown)    ; markdown-mode + preview
(require 'init-asciidoc)    ; adoc-mode + preview/pdf
(require 'init-css)         ; css/scss + LSP + color preview
(require 'init-js)          ; javascript/typescript/json
(require 'init-git)         ; magit + diff-hl
(require 'init-dired)       ; file manager: move, rename, delete
(require 'init-tree)        ; project tree sidebar (treemacs)
(require 'init-tabs)        ; one tab (workspace) per project
(require 'init-spell)       ; spell checking for prose (jinx)
(require 'init-term)        ; vterm terminal + bb tasks
(require 'init-linear)      ; Linear issues in Org
(require 'init-jira)        ; Jira Cloud issues in Org
(require 'init-tickets)     ; SPC l: Linear or Jira per project
(require 'init-claude)      ; Claude Code CLI (claude-code-ide)

;; Back to a normal GC threshold after startup.
(setq gc-cons-threshold (* 16 1024 1024))
