;;; init-spell.el --- Spell checking for prose (jinx, English + Dutch)  -*- lexical-binding: t; -*-

;; Text only: Markdown, AsciiDoc, Org (Linear), commit messages; not code.
;; Vim keys: z= suggestions (also "save word"), ]s / [s next / previous mistake.
;; Needs: brew install enchant pkgconf (Dutch dictionary is aspell's "nl").
(use-package jinx
  :hook (text-mode . jinx-mode)
  :custom (jinx-languages "en_US nl")
  :config
  (evil-define-key 'normal jinx-mode-map
    (kbd "z=") #'jinx-correct
    (kbd "]s") #'jinx-next
    (kbd "[s") #'jinx-previous))

(provide 'init-spell)
