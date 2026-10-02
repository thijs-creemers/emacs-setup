;;; init-python.el --- Python  -*- lexical-binding: t; -*-

;; LSP server: pyright (brew install pyright).
(use-package python
  :ensure nil
  :hook (python-mode . (lambda () (my/eglot-if "pyright-langserver")))
  :custom
  (python-indent-offset 4)
  (python-shell-interpreter "python3"))

;; "," = Python commands, same layout as Clojure.
(with-eval-after-load 'python
  (evil-define-key 'normal python-mode-map
    (kbd "<localleader>cj") #'run-python                    ; start REPL
    (kbd "<localleader>ee") #'python-shell-send-statement   ; current statement
    (kbd "<localleader>er") #'python-shell-send-defun       ; function / class
    (kbd "<localleader>eb") #'python-shell-send-buffer
    (kbd "<localleader>lg") #'python-shell-switch-to-shell)
  (evil-define-key 'visual python-mode-map
    (kbd "<localleader>ee") #'python-shell-send-region))

(provide 'init-python)
