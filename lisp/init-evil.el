;;; init-evil.el --- Vim keybindings and leader key  -*- lexical-binding: t; -*-

(use-package evil
  :init
  (setq evil-want-keybinding nil      ; required by evil-collection
        evil-want-C-u-scroll t
        evil-undo-system 'undo-redo)  ; C-r redo, built-in
  :config
  (evil-mode 1))

;; Vim keys for magit, dired, help, cider, etc.
;; REPLs: RET in insert mode evaluates (CIDER: see init-clojure.el).
(use-package evil-collection
  :after evil
  :init
  (setq evil-collection-binding-overrides '((repl-submit  :state insert)
                                            (repl-newline :state normal)))
  :config (evil-collection-init))

;; gc = comment (like vim-commentary).
(use-package evil-commentary
  :after evil
  :config (evil-commentary-mode 1))

;; Cmd-/ (= M-/, Cmd is Meta): toggle comment on this line or the selected
;; lines, like other editors. Cursor stays put. Works in every state.
(defun my/toggle-comment ()
  "Comment or uncomment the current line, or all lines in the selection."
  (interactive)
  (let* ((region (use-region-p))
         (beg (if region (region-beginning) (point)))
         (end (if region (region-end) (point))))
    (save-excursion
      ;; A line selection ends at the start of the next line: don't include it.
      (when (and region (> end beg) (save-excursion (goto-char end) (bolp)))
        (setq end (1- end)))
      (comment-or-uncomment-region (progn (goto-char beg) (line-beginning-position))
                                   (progn (goto-char end) (line-end-position))))))

(global-set-key (kbd "M-/") #'my/toggle-comment)
(with-eval-after-load 'evil
  (evil-define-key '(normal visual insert) 'global (kbd "M-/") #'my/toggle-comment))

;; ys / cs / ds to add, change, delete surroundings.
(use-package evil-surround
  :after evil
  :config (global-evil-surround-mode 1))

(defun my/open-keys-cheatsheet ()
  "Open KEYS.md, the keybinding reference."
  (interactive)
  (find-file (expand-file-name "KEYS.md" user-emacs-directory)))

;; Next/previous buffer (H/L) only visit files, not *Messages*, Magit, etc.
(setq switch-to-prev-buffer-skip (lambda (_window buffer _bury) (not (buffer-file-name buffer))))

;; ---- Leader key: SPC in normal/visual mode ----
;; Language specific keys live under SPC m (see init-clojure.el).
(evil-set-leader '(normal visual) (kbd "SPC"))

;; Local leader "," = commands for the current language (same as nvim).
;; Each lang file binds its own, e.g. ", e e" eval form in Clojure.
(evil-set-leader '(normal visual) (kbd ",") t)

(evil-define-key 'visual 'global
  (kbd "<leader>as") #'claude-code-ide-insert-at-mentioned)  ; selection -> Claude

(evil-define-key 'normal 'global
  ;; find (same keys as Telescope in nvim)
  (kbd "<leader>ff") #'my/find-file-in-project
  (kbd "<leader>fF") #'find-file
  (kbd "<leader>fg") #'consult-ripgrep
  (kbd "<leader>fb") #'consult-buffer
  (kbd "<leader>fr") #'consult-recent-file
  (kbd "<leader>fh") #'describe-symbol
  (kbd "<leader>fd") #'consult-flymake
  (kbd "<leader>fs") #'consult-imenu
  (kbd "<leader>/")  #'consult-line
  ;; buffers
  (kbd "<leader>bb") #'consult-buffer
  (kbd "<leader>bd") #'my/kill-buffer
  (kbd "<leader>bs") #'save-buffer
  (kbd "<leader>bn") #'next-buffer
  (kbd "<leader>bp") #'previous-buffer
  (kbd "]b")         #'next-buffer
  (kbd "[b")         #'previous-buffer
  (kbd "L")          #'next-buffer                    ; as in nvim (S-l)
  (kbd "H")          #'previous-buffer                ; as in nvim (S-h)
  ;; project
  (kbd "<leader>pf") #'my/find-file-in-project
  (kbd "<leader>pp") #'project-switch-project
  (kbd "<leader>pe") #'my/reload-project-dotenv
  ;; windows
  (kbd "<leader>wv") #'split-window-right
  (kbd "<leader>ws") #'split-window-below
  (kbd "<leader>wd") #'delete-window
  (kbd "<leader>ww") #'other-window
  ;; code (LSP)
  (kbd "<leader>ca") #'eglot-code-actions
  (kbd "<leader>cr") #'eglot-rename
  (kbd "<leader>cf") #'eglot-format-buffer
  (kbd "<leader>cd") #'flymake-show-buffer-diagnostics
  (kbd "<leader>cu") #'xref-find-references
  (kbd "]d")         #'flymake-goto-next-error
  (kbd "[d")         #'flymake-goto-prev-error
  ;; git
  (kbd "<leader>gg") #'magit-status
  (kbd "<leader>gb") #'magit-blame-addition
  (kbd "<leader>gf") #'magit-log-buffer-file          ; file history
  (kbd "<leader>gV") #'my/magit-diff-branch-vs-main
  (kbd "<leader>gw") #'magit-worktree
  (kbd "<leader>gs") #'diff-hl-stage-dwim             ; stage hunk
  (kbd "<leader>gr") #'diff-hl-revert-hunk
  (kbd "<leader>gp") #'diff-hl-show-hunk              ; preview hunk
  ;; GitHub (Forge + gh)
  (kbd "<leader>gP") #'forge-list-pullreqs            ; PRs of this repo
  (kbd "<leader>gI") #'forge-list-issues
  (kbd "<leader>gn") #'forge-create-pullreq           ; new PR from this branch
  (kbd "<leader>go") #'forge-browse                   ; open in browser
  (kbd "<leader>gc") #'my/gh-pr-checks                ; CI status (live)
  (kbd "]h")         #'diff-hl-next-hunk
  (kbd "[h")         #'diff-hl-previous-hunk
  ;; open / tasks
  (kbd "<leader>ot") #'my/vterm-project               ; terminal in project root
  (kbd "<leader>oT") #'my/vterm-here                  ; terminal here
  (kbd "<leader>od") #'dired-jump                     ; folder of this file
  (kbd "<leader>oD") #'my/dired-project-root
  (kbd "<leader>ou") #'browse-url                     ; open URL (default: at cursor)
  (kbd "<leader>tb") #'my/bb-task
  ;; Claude Code
  (kbd "<leader>ac") #'my/claude-toggle                    ; start / show / hide
  (kbd "<leader>af") #'claude-code-ide-switch-to-buffer    ; focus Claude
  (kbd "<leader>ap") #'claude-code-ide-send-prompt         ; prompt from minibuffer
  (kbd "<leader>am") #'claude-code-ide-menu                ; all commands
  (kbd "<leader>ar") #'claude-code-ide-resume              ; resume old conversation
  (kbd "<leader>aC") #'claude-code-ide-continue            ; continue last one
  (kbd "<leader>ae") #'claude-code-ide-send-escape         ; interrupt Claude
  (kbd "<leader>aq") #'claude-code-ide-stop
  (kbd "<leader>ax") #'claude-code-ide-clear-selection  ; drop file/selection from prompt
  (kbd "<leader>aa") #'my/claude-accept-diff
  (kbd "<leader>ad") #'my/claude-deny-diff
  ;; Linear
  (kbd "<leader>ll") #'linear-emacs-list-issues
  (kbd "<leader>lp") #'linear-emacs-list-issues-by-project
  (kbd "<leader>ln") #'linear-emacs-new-issue
  (kbd "<leader>ls") #'my/linear-show-ticket          ; find + view one ticket
  (kbd "<leader>lc") #'my/linear-add-comment          ; comment on a ticket
  ;; help
  (kbd "<leader>hk") #'my/open-keys-cheatsheet
  (kbd "<leader>hr") #'my/reload-config
  (kbd "<leader>hf") #'describe-function
  (kbd "<leader>hv") #'describe-variable
  (kbd "<leader>hb") #'describe-key
  ;; quit
  (kbd "<leader>qq") #'save-buffers-kill-terminal)

(provide 'init-evil)
