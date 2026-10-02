;;; init-packages.el --- Package archives and use-package  -*- lexical-binding: t; -*-

(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
(package-initialize)

;; use-package is built in since Emacs 29.
;; :ensure t on every package = auto-install when missing.
(require 'use-package)
(setq use-package-always-ensure t)

(provide 'init-packages)
