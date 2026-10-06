;;; init-ui.el --- Look and feel  -*- lexical-binding: t; -*-

;; Same theme as nvim. Flavors: mocha (dark), macchiato, frappe, latte (light).
(use-package catppuccin-theme
  :custom (catppuccin-flavor 'mocha)
  :config (load-theme 'catppuccin t))

;; Font: first installed one from this list wins (same as Ghostty).
;; Size 150 = 15pt.
(defvar my/fonts '("JetBrainsMono Nerd Font" "JetBrains Mono" "MesloLGS NF" "Fira Code" "Menlo"))
(defvar my/font-size 150)

(defun my/set-font (&optional frame)
  (with-selected-frame (or frame (selected-frame))
    (when-let ((font (seq-find (lambda (f) (find-font (font-spec :family f))) my/fonts)))
      (set-face-attribute 'default nil :family font :height my/font-size))))

;; Daemon has no GUI at start, so also set font on each new frame.
(my/set-font)
(add-hook 'after-make-frame-functions #'my/set-font)

(setq-default display-line-numbers-type 'relative)  ; handy with vim motions
(add-hook 'prog-mode-hook #'display-line-numbers-mode)

(column-number-mode 1)
(global-hl-line-mode 1)
(show-paren-mode 1)

;; Status bar: vim mode, file, git branch, LSP, errors, REPL.
;; Icons need a Nerd Font (Symbols Nerd Font is installed).
(use-package doom-modeline
  :custom
  (doom-modeline-height 28)
  (doom-modeline-bar-width 4)
  (doom-modeline-modal-icon nil)                 ; show NORMAL / INSERT as text
  (doom-modeline-buffer-file-name-style 'relative-from-project)
  (doom-modeline-vcs-max-length 30)              ; long branch names
  (doom-modeline-buffer-encoding nil)            ; hide UTF-8 / LF noise
  :config
  (setq evil-normal-state-tag   " NORMAL "  evil-insert-state-tag  " INSERT "
        evil-visual-state-tag   " VISUAL "  evil-replace-state-tag " REPLACE "
        evil-operator-state-tag " PENDING " evil-motion-state-tag  " MOTION "
        evil-emacs-state-tag    " EMACS ")
  (doom-modeline-mode 1))

;; Colored nested parens, very useful in Clojure.
(use-package rainbow-delimiters
  :hook (prog-mode . rainbow-delimiters-mode))

;; Shows possible next keys after a prefix (built-in since Emacs 30).
;; Popup on the right; falls back to bottom when the frame is too narrow.
(use-package which-key
  :ensure nil
  :custom
  (which-key-idle-delay 0.3)
  (which-key-side-window-max-width 0.33)
  :config
  (which-key-setup-side-window-right-bottom)
  (which-key-add-key-based-replacements
    "SPC b" "buffer"  "SPC c" "code"     "SPC f" "find"  "SPC h" "help"
    "SPC p" "project" "SPC q" "quit"     "SPC w" "window"
    "SPC g" "git"     "SPC o" "open"     "SPC t" "tasks" "SPC l" "tickets"
    "SPC a" "claude")
  ;; "," group names differ per language, so set them per mode.
  (dolist (mode '(clojure-mode clojurescript-mode clojurec-mode python-mode python-ts-mode))
    (which-key-add-major-mode-key-based-replacements mode
      ", c" "connect"   ", e" "eval"   ", l" "log/repl"
      ", r" "refresh"   ", t" "test"   ", p" "parinfer"   ", d" "django"))
  (which-key-mode 1))

(provide 'init-ui)
