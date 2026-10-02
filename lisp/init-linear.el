;;; init-linear.el --- Linear.app issues in Org  -*- lexical-binding: t; -*-

;; API key lives in the macOS Keychain, never in this config. Add it once:
;;   security add-generic-password -a apikey -s api.linear.app -w <KEY>
;; SPC l l = my open issues (Org file). Edit TODO state there to update Linear.
(setq auth-sources '(macos-keychain-generic "~/.authinfo.gpg"))

(use-package linear-emacs
  :vc (:url "https://github.com/anegg0/linear-emacs" :rev :newest)
  :commands (linear-emacs-list-issues linear-emacs-list-issues-by-project
             linear-emacs-new-issue linear-emacs-test-connection)
  :init
  (setq linear-emacs-org-file-path (expand-file-name "~/org/linear.org"))
  :config
  (let ((key (auth-source-pick-first-password :host "api.linear.app" :user "apikey")))
    (if key
        (setq linear-emacs-api-key key)
      (message "Linear: no API key in Keychain (see lisp/init-linear.el)")))
  (linear-emacs-enable-org-sync))   ; TODO state changes in the Org file sync back

(provide 'init-linear)
