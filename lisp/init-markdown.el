;;; init-markdown.el --- Markdown  -*- lexical-binding: t; -*-

;; README.md opens in GitHub flavor (gfm-mode): tables, task lists, ```code```.
;; Preview uses pandoc. LSP (optional): brew install marksman
(use-package markdown-mode
  :mode (("README\\.md\\'" . gfm-mode)
         ("\\.md\\'" . gfm-mode)
         ("\\.markdown\\'" . markdown-mode))
  :hook ((markdown-mode . visual-line-mode)          ; wrap long lines at words
         (markdown-mode . (lambda () (my/eglot-if "marksman"))))
  :custom
  (markdown-command "pandoc -f gfm -t html5 --standalone")
  (markdown-fontify-code-blocks-natively t)          ; colored code in ``` blocks
  (markdown-header-scaling t)                        ; bigger headings
  (markdown-enable-wiki-links t)
  :config
  ;; "," = Markdown commands.
  (evil-define-key 'normal markdown-mode-map
    (kbd "<localleader>p") '("Preview" . markdown-live-preview-mode)  ; preview side by side
    (kbd "<localleader>o") '("Preview in browser (GitHub look)" . my/preview-browser)
    (kbd "<localleader>h") '("Hide / show markup" . markdown-toggle-markup-hiding)
    (kbd "<localleader>l") '("Insert link" . markdown-insert-link)
    (kbd "<localleader>t") '("Align table" . markdown-table-align)
    (kbd "<localleader>x") '("Toggle checkbox" . markdown-toggle-gfm-checkbox)
    (kbd "<localleader>i") '("Jump to heading" . consult-imenu)               ; jump to heading
    (kbd "TAB")        #'markdown-cycle              ; fold / unfold heading
    (kbd "gx")         #'markdown-follow-thing-at-point)) ; also [text](url) links

(provide 'init-markdown)
