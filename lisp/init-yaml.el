;;; init-yaml.el --- YAML  -*- lexical-binding: t; -*-

;; LSP server: npm install -g yaml-language-server
(use-package yaml-mode
  :mode ("\\.ya?ml\\'" . yaml-mode)
  :hook (yaml-mode . (lambda ()
                       (display-line-numbers-mode 1)  ; yaml is not prog-mode
                       (my/eglot-if "yaml-language-server"))))

(provide 'init-yaml)
