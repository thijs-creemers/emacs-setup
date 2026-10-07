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

;; ---- Claude window: Claude's own keys win (Esc, C-c, S-Tab, C-r, C-o, ...) ----
;; Only C-z / C-\ are kept for Emacs: vim normal mode, so SPC a c, C-w h,
;; SPC b d work again; i goes back to typing to Claude. A header line says so.
(defvar my/claude-passthrough-keys
  '("C-c" "C-d" "C-r" "C-o" "C-t" "C-l" "C-v" "C-b" "C-g" "C-j" "C-k" "C-u" "C-y"
    "C-a" "C-e" "C-w" "C-n" "C-p" "C-f" "C-s" "C-_" "TAB" "M-p" "M-t" "M-b" "M-f")
  "Keys sent straight to Claude in its window (besides Esc and Shift-Tab).")

(defun my/claude-send-key ()
  "Send the key that invoked this command to the Claude terminal."
  (interactive)
  (vterm--self-insert))

(defun my/claude-send-shift-tab () (interactive) (vterm-send-key "<tab>" t))

(define-minor-mode my/claude-term-mode
  "Claude window: send Claude's shortcuts to Claude, keep only C-\\ for Emacs."
  :keymap (make-sparse-keymap))

(with-eval-after-load 'evil
  (dolist (key my/claude-passthrough-keys)
    (evil-define-key 'insert my/claude-term-mode-map (kbd key) #'my/claude-send-key))
  (evil-define-key 'insert my/claude-term-mode-map
    (kbd "<escape>") #'vterm-send-escape
    (kbd "<backtab>") #'my/claude-send-shift-tab
    (kbd "C-z") #'evil-normal-state
    (kbd "C-\\") #'evil-normal-state))

;; The package sets up every new Claude window here; switch our mode on too.
(defun my/claude-term-setup (&rest _)
  (when (derived-mode-p 'vterm-mode)
    (my/claude-term-mode 1)
    (setq header-line-format
          " Ctrl-Z: Emacs keys  ·  then SPC a c hide · C-w h other window · SPC b d hide (keeps running) · i back to Claude")
    (evil-normalize-keymaps)))

(advice-add 'claude-code-ide--setup-terminal-keybindings :after #'my/claude-term-setup)

;; Scrollback: Claude redraws with "clear screen" (ESC[2J). libvterm erases the
;; screen, so earlier output was lost; real terminals push it into scrollback.
;; Do the same in Claude windows: scroll the screen up first, drop ESC[3J.
;; Uses the terminal's own height: claude-code-ide skips height-only resizes, so
;; the window height can differ, and too many blank lines left the window empty.
(defvar-local my/claude-term-rows nil "Terminal rows as vterm last set them.")
(defun my/claude-note-rows (_term rows _cols) (setq my/claude-term-rows rows))
(defun my/claude-note-new-rows (rows &rest _) (setq my/claude-term-rows rows))

(defun my/claude-keep-scrollback (orig proc input)
  (let ((buf (process-buffer proc)))
    (when (and (buffer-live-p buf) (string-prefix-p "*claude-code[" (buffer-name buf))
               (string-search "\033[" input))
      (let* ((win (get-buffer-window buf t))      ; window height only for older sessions
             (rows (or (buffer-local-value 'my/claude-term-rows buf) (and win (window-body-height win)) 0))
             (scroll-up (concat (format "\033[%d;1H" rows) (make-string rows ?\n) "\033[H")))
        (setq input (string-replace "\033[3J" "" input))
        (when (> rows 0)
          (setq input (string-replace "\033[2J" scroll-up input)))))
    (funcall orig proc input)))

(with-eval-after-load 'vterm
  (advice-add 'vterm--set-size :after #'my/claude-note-rows)
  (advice-add 'vterm--new :after #'my/claude-note-new-rows)
  ;; depth -90: run before claude-code-ide's anti-flicker advice queues the output
  (advice-add 'vterm--filter :around #'my/claude-keep-scrollback '((depth . -90))))

;; SPC a R: blank or garbled Claude window -> resize the terminal by one column and
;; back. Claude gets two resize signals and repaints everything at the right size.
(defun my/claude-redraw ()
  "Make Claude repaint its window."
  (interactive)
  (let* ((win (or (seq-find (lambda (w) (string-prefix-p "*claude-code[" (buffer-name (window-buffer w))))
                            (window-list nil 'never))
                  (user-error "No Claude window visible")))
         (buf (window-buffer win))
         (proc (get-buffer-process buf))
         (rows (window-body-height win))
         (cols (max vterm-min-window-width (window-body-width win))))
    (cl-flet ((resize (c) (with-current-buffer buf
                            (let ((inhibit-read-only t)) (vterm--set-size vterm--term rows c))
                            (set-process-window-size proc rows c))))
      (resize (1- cols))
      (run-at-time 0.15 nil (lambda () (when (process-live-p proc) (resize cols)))))))

(provide 'init-claude)
