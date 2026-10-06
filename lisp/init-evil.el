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
  (kbd "<leader>as") '("Send selection to Claude" . claude-code-ide-insert-at-mentioned))  ; selection -> Claude

(evil-define-key 'normal 'global
  ;; find (same keys as Telescope in nvim)
  (kbd "<leader>ff") '("Find file in project" . my/find-file-in-project)
  (kbd "<leader>fF") '("Find file by path" . find-file)
  (kbd "<leader>fg") '("Search text in project" . consult-ripgrep)
  (kbd "<leader>fb") '("Switch buffer" . consult-buffer)
  (kbd "<leader>fr") '("Recent files" . consult-recent-file)
  (kbd "<leader>fh") '("Help on symbol" . describe-symbol)
  (kbd "<leader>fd") '("Find problems" . consult-flymake)
  (kbd "<leader>fs") '("Functions / headings in file" . consult-imenu)
  (kbd "<leader>/")  '("Search in buffer" . consult-line)
  ;; buffers
  (kbd "<leader>bb") '("Switch buffer" . consult-buffer)
  (kbd "<leader>bd") '("Close buffer" . my/kill-buffer)
  (kbd "<leader>bs") '("Save" . save-buffer)
  (kbd "<leader>bi") '("Buffer list (bulk close)" . ibuffer)
  (kbd "<leader>bn") '("Next buffer" . next-buffer)
  (kbd "<leader>bp") '("Previous buffer" . previous-buffer)
  (kbd "]b")         #'next-buffer
  (kbd "[b")         #'previous-buffer
  (kbd "L")          #'next-buffer                    ; as in nvim (S-l)
  (kbd "H")          #'previous-buffer                ; as in nvim (S-h)
  ;; project
  (kbd "<leader>pf") '("Find file in project" . my/find-file-in-project)
  (kbd "<leader>pp") '("Switch project" . project-switch-project)
  (kbd "<leader>pe") '("Reload .env" . my/reload-project-dotenv)
  (kbd "<leader>pd") '("Remove project from list" . project-forget-project)        ; remove one from the list
  (kbd "<leader>pc") '("Clean up project list" . my/project-cleanup)            ; remove gone / temp / package dirs
  ;; windows
  (kbd "<leader>wv") '("Split side by side" . split-window-right)
  (kbd "<leader>ws") '("Split below" . split-window-below)
  (kbd "<leader>wd") '("Close window" . delete-window)
  (kbd "<leader>ww") '("Next window" . other-window)
  ;; code (LSP)
  (kbd "<leader>ca") '("Quick fix / code action" . eglot-code-actions)
  (kbd "<leader>cr") '("Rename symbol" . eglot-rename)
  (kbd "<leader>cf") '("Format file" . eglot-format-buffer)
  (kbd "<leader>cd") '("List problems" . flymake-show-buffer-diagnostics)
  (kbd "<leader>cu") '("Find usages" . xref-find-references)
  (kbd "<leader>cs") '("Functions / headings in file" . consult-imenu)
  (kbd "]d")         #'flymake-goto-next-error
  (kbd "[d")         #'flymake-goto-prev-error
  ;; git
  (kbd "<leader>gg") '("Git status" . magit-status)
  (kbd "<leader>gb") '("Blame" . magit-blame-addition)
  (kbd "<leader>gf") '("File history" . magit-log-buffer-file)          ; file history
  (kbd "<leader>gV") '("Diff branch vs main" . my/magit-diff-branch-vs-main)
  (kbd "<leader>gw") '("Worktrees" . magit-worktree)
  (kbd "<leader>gs") '("Stage hunk" . diff-hl-stage-dwim)             ; stage hunk
  (kbd "<leader>gr") '("Revert hunk" . diff-hl-revert-hunk)
  (kbd "<leader>gp") '("Preview hunk" . diff-hl-show-hunk)              ; preview hunk
  ;; GitHub (Forge + gh)
  (kbd "<leader>gP") '("Pull requests" . forge-list-pullreqs)            ; PRs of this repo
  (kbd "<leader>gI") '("Issues" . forge-list-issues)
  (kbd "<leader>gn") '("New pull request" . forge-create-pullreq)           ; new PR from this branch
  (kbd "<leader>go") '("Open in browser" . forge-browse)                   ; open in browser
  (kbd "<leader>gc") '("CI checks (live)" . my/gh-pr-checks)                ; CI status (live)
  (kbd "]h")         #'diff-hl-next-hunk
  (kbd "[h")         #'diff-hl-previous-hunk
  ;; open / tasks
  (kbd "<leader>ot") '("Terminal (project root)" . my/vterm-project)               ; terminal in project root
  (kbd "<leader>oT") '("Terminal (this folder)" . my/vterm-here)                  ; terminal here
  (kbd "<leader>od") '("Files: this folder" . dired-jump)                     ; folder of this file
  (kbd "<leader>oD") '("Files: project root" . my/dired-project-root)
  (kbd "<leader>op") '("Project tree (show/hide)" . my/project-tree)
  (kbd "<leader>ou") '("Open URL" . browse-url)                     ; open URL (default: at cursor)
  (kbd "<leader>tb") '("Run bb task" . my/bb-task)
  ;; Claude Code
  (kbd "<leader>ac") '("Claude: show / hide" . my/claude-toggle)                    ; start / show / hide
  (kbd "<leader>af") '("Focus Claude" . claude-code-ide-switch-to-buffer)    ; focus Claude
  (kbd "<leader>ap") '("Prompt Claude" . claude-code-ide-send-prompt)         ; prompt from minibuffer
  (kbd "<leader>am") '("Claude menu" . claude-code-ide-menu)                ; all commands
  (kbd "<leader>ar") '("Resume conversation" . claude-code-ide-resume)              ; resume old conversation
  (kbd "<leader>aC") '("Continue last conversation" . claude-code-ide-continue)            ; continue last one
  (kbd "<leader>ae") '("Interrupt Claude" . claude-code-ide-send-escape)         ; interrupt Claude
  (kbd "<leader>aq") '("Stop Claude" . claude-code-ide-stop)
  (kbd "<leader>ax") '("Drop file/selection from context" . claude-code-ide-clear-selection)  ; drop file/selection from prompt
  (kbd "<leader>aa") '("Accept change" . my/claude-accept-diff)
  (kbd "<leader>ad") '("Reject change" . my/claude-deny-diff)
  ;; Tickets: Linear or Jira, per project (SPC l b)
  (kbd "<leader>ll") '("My issues" . my/tickets-my-issues)
  (kbd "<leader>lp") '("Project board" . my/tickets-board)
  (kbd "<leader>ln") '("New issue" . my/tickets-new)
  (kbd "<leader>ls") '("Find ticket" . my/tickets-find)               ; find + view one ticket
  (kbd "<leader>lc") '("Comment on ticket" . my/tickets-comment)      ; comment on a ticket
  (kbd "<leader>lb") '("Choose Linear / Jira" . my/tickets-choose-backend)
  ;; ui
  (kbd "<leader>ut") '("Theme: light / dark / auto" . my/theme-choose)
  (kbd "<leader>up") '("Presentation mode on/off" . my/presentation-mode)
  ;; help
  (kbd "<leader>hk") '("Cheatsheet (KEYS.md)" . my/open-keys-cheatsheet)
  (kbd "<leader>hr") '("Reload config" . my/reload-config)
  (kbd "<leader>hf") '("Describe function" . describe-function)
  (kbd "<leader>hv") '("Describe variable" . describe-variable)
  (kbd "<leader>hb") '("What does this key do?" . describe-key)
  ;; quit
  (kbd "<leader>qq") '("Quit" . save-buffers-kill-terminal))

(provide 'init-evil)
