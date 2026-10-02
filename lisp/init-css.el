;;; init-css.el --- CSS / SCSS  -*- lexical-binding: t; -*-

;; LSP: vscode-css-language-server (npm i -g vscode-langservers-extracted).
;; Completion, hover docs (K), errors as you type, formatting (SPC c f).
;; Server command + Tailwind settings live in init-lsp.el.
(use-package css-mode
  :ensure nil
  :hook ((css-mode scss-mode) . (lambda ()
                                  (setq-local tab-width 2)   ; formatter uses tab-width
                                  (my/eglot-if "vscode-css-language-server")))
  :custom (css-indent-offset 2))

;; Show color values in their own color: #ff8800, rgb(...), hsl(...).
(use-package rainbow-mode
  :hook (css-mode scss-mode))

;; Emmet: type an abbreviation, press C-j (insert mode) to expand.
;; CSS: d:f -> display: flex;  m10 -> margin: 10px;  HTML: div.card>p*3
(use-package emmet-mode
  :hook (css-mode scss-mode html-mode mhtml-mode)
  :config
  (evil-define-key 'insert emmet-mode-keymap (kbd "C-j") #'emmet-expand-line))

(provide 'init-css)
