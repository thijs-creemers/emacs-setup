;;; init-lsp.el --- LSP via eglot (built into Emacs)  -*- lexical-binding: t; -*-

;; Language servers used (install with Homebrew / npm):
;;   clojure-lsp, pyright, yaml-language-server, vscode-css-language-server
;; Eglot only starts when the server binary is on PATH (see each lang file).

;; Start eglot only when SERVER is installed, else stay quiet.
(defun my/eglot-if (server)
  (when (executable-find server)
    (eglot-ensure)))

;; Tailwind / daisyUI class completion: rass (uv tool install rassumfrassum)
;; runs Tailwind's server next to the normal one (eglot: one server per file).
;; CSS only for now; Clojure is parked (rass gives up on slow clojure-lsp).
(defun my/with-tailwind (command)
  "Return COMMAND, wrapped with rass + Tailwind's server when installed."
  (if (and (executable-find "rass") (executable-find "tailwindcss-language-server"))
      `("rass" "--" ,@command "--" "tailwindcss-language-server" "--stdio")
    command))

;; Eglot from ELPA: the built-in 1.17 lacks pull diagnostics, which TypeScript 7's
;; server needs (errors never showed). use-package can't upgrade built-ins itself.
(unless (package-installed-p 'eglot '(1 20))
  (let ((package-install-upgrade-built-in t))
    (unless (assq 'eglot package-archive-contents) (package-refresh-contents))
    (package-install 'eglot)))

(use-package eglot
  :ensure nil
  :custom
  ;; clojure-lsp needs ~9 s to start on a big project. Connect in the
  ;; background (no 3 s freeze) and keep servers running in the daemon.
  (eglot-sync-connect nil)
  (eglot-autoshutdown nil)            ; stop manually: M-x eglot-shutdown
  (eglot-events-buffer-config '(:size 0)) ; no event logging = faster
  :config
  (add-to-list 'eglot-server-programs
               '((yaml-mode yaml-ts-mode) . ("yaml-language-server" "--stdio")))
  ;; provideFormatter: the CSS server only formats when asked at startup.
  (add-to-list 'eglot-server-programs
               `((css-mode css-ts-mode scss-mode)
                 . (,@(my/with-tailwind '("vscode-css-language-server" "--stdio"))
                    :initializationOptions (:provideFormatter t)))))

;; Eglot's glob parser rejects patterns like {a,b.*.c}; Tailwind sends two of
;; those (old JS config files) and then gives up. Keep only readable patterns.
(with-eval-after-load 'eglot
  (define-advice eglot-register-capability (:around (orig server method id &rest args) skip-bad-globs)
    (when (eq method 'workspace/didChangeWatchedFiles)
      (setq args (plist-put (copy-sequence args) :watchers
                            (vconcat (seq-filter
                                      (lambda (w) (ignore-errors
                                                    (eglot--glob-compile (plist-get w :globPattern) t t)
                                                    t))
                                      (plist-get args :watchers))))))
    (apply orig server method id args)))

;; Settings sent to the servers. CSS: allow Tailwind's @theme etc.
;; tailwindCSS: ready for hiccup (:class "..." and [:div.flex]) once resumed.
(setq-default eglot-workspace-configuration
              '(:css  (:lint (:unknownAtRules "ignore"))
                :scss (:lint (:unknownAtRules "ignore"))
                :tailwindCSS
                (:includeLanguages (:clojure "html")
                 :experimental
                 (:classRegex [":class\\s+\"([^\"]*)\""
                               ["\\[:[a-z][a-z0-9-]*((?:\\.[a-zA-Z0-9_:/-]+)+)"
                                "\\.([a-zA-Z0-9_:/-]+)"]]))))

(provide 'init-lsp)
