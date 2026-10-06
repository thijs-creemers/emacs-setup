;;; init-packages.el --- Package archives and use-package  -*- lexical-binding: t; -*-

(require 'package)
;; GNU/NonGNU via a GitHub mirror: elpa.gnu.org timed out (2026-10-06). The mirror has
;; no signature files. Revert to the defaults + melpa once elpa.gnu.org works again.
(setq package-archives
      '(("gnu"    . "https://raw.githubusercontent.com/d12frosted/elpa-mirror/master/gnu/")
        ("nongnu" . "https://raw.githubusercontent.com/d12frosted/elpa-mirror/master/nongnu/")
        ("melpa"  . "https://melpa.org/packages/"))
      package-check-signature nil)
(package-initialize)

;; use-package is built in since Emacs 29.
;; :ensure t on every package = auto-install when missing.
(require 'use-package)
(setq use-package-always-ensure t)

(provide 'init-packages)
