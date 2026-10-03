;;; init-clojure.el --- Clojure, ClojureScript, EDN + CIDER  -*- lexical-binding: t; -*-

(use-package clojure-mode
  :hook ((clojure-mode clojurescript-mode clojurec-mode)
         . (lambda () (my/eglot-if "clojure-lsp")))
  :config
  ;; "," = Clojure commands, same keys as Conjure in nvim.
  (evil-define-key 'normal clojure-mode-map
    ;; connect
    (kbd "<localleader>cj") #'cider-jack-in-clj    ; start REPL
    (kbd "<localleader>cJ") #'cider-jack-in-cljs
    (kbd "<localleader>cs") #'cider-connect-clj    ; connect to running nREPL
    (kbd "<localleader>cd") #'cider-quit
    ;; eval
    (kbd "<localleader>ee") #'cider-eval-list-at-point     ; current form
    (kbd "<localleader>er") #'cider-eval-defun-at-point    ; root (top-level) form
    (kbd "<localleader>ew") #'cider-eval-sexp-at-point     ; word
    (kbd "<localleader>eb") #'cider-eval-buffer
    (kbd "<localleader>en") #'cider-eval-ns-form
    ;; log / REPL window
    (kbd "<localleader>lg") #'cider-switch-to-repl-buffer
    (kbd "<localleader>lq") #'my/cider-close-repl-window
    ;; refresh (runs cider-ns-refresh-before/after-fn from .dir-locals.el)
    (kbd "<localleader>rr") #'cider-ns-refresh
    (kbd "<localleader>ra") #'my/cider-refresh-all
    (kbd "<localleader>rc") #'my/cider-refresh-clear
    ;; Integrant system in user ns
    (kbd "<localleader>rs") #'my/system-reset
    (kbd "<localleader>rg") #'my/system-go
    (kbd "<localleader>rh") #'my/system-halt
    ;; tests
    (kbd "<localleader>tc") #'cider-test-run-test          ; test at cursor
    (kbd "<localleader>tn") #'cider-test-run-ns-tests
    (kbd "<localleader>ta") #'cider-test-run-project-tests
    (kbd "<localleader>tf") #'cider-test-rerun-failed-tests
    ;; parinfer
    (kbd "<localleader>pt") #'parinfer-rust-toggle-disable
    (kbd "<localleader>pm") #'parinfer-rust-switch-mode
    ;; format (cljfmt via clojure-lsp); whole file: SPC c f
    (kbd "<localleader>=") #'my/clojure-format-form
    ;; docs
    (kbd "K") #'cider-doc)
  (evil-define-key 'visual clojure-mode-map
    (kbd "<localleader>=") #'eglot-format))           ; format selection

;; , = : format only the top-level form under the cursor (cljfmt rules),
;; so the rest of the file stays untouched.
(defun my/clojure-format-form ()
  "Format the top-level form at point via the LSP server."
  (interactive)
  (save-excursion
    (let ((end (progn (end-of-defun) (point)))
          (beg (progn (beginning-of-defun) (point))))
      (eglot-format beg end))))

(defun my/cider-refresh-all ()   (interactive) (cider-ns-refresh 'refresh-all))
(defun my/cider-refresh-clear () (interactive) (cider-ns-refresh 'clear))
(defun my/system-reset () (interactive) (cider-interactive-eval "(user/reset)"))
(defun my/system-go ()    (interactive) (cider-interactive-eval "(user/go)"))
(defun my/system-halt ()  (interactive) (cider-interactive-eval "(user/halt)"))

;; RET in the REPL: evaluate only when the form is complete AND the cursor
;; is at the end. Otherwise new line + indent (parens are auto-closed).
(defun my/cider-repl-return ()
  (interactive)
  (if (looking-at-p "[[:space:]]*\\'")
      (cider-repl-return)
    (cider-repl-newline-and-indent)))

(defun my/cider-close-repl-window ()
  "Close the window showing the CIDER REPL (REPL keeps running)."
  (interactive)
  (when-let ((repl (cider-current-repl)))
    (dolist (window (get-buffer-window-list repl nil t))
      (ignore-errors (delete-window window)))))

;; Parinfer: indentation drives the parens (same as nvim-parinfer).
;; Library (arm64 .so) downloads once to ~/.emacs.d/parinfer-rust/.
;; Modes: "indent" (as nvim), "smart", "paren". Toggle: , p t
(use-package parinfer-rust-mode
  :hook ((clojure-mode clojurescript-mode clojurec-mode)
         . (lambda ()
             (electric-pair-local-mode -1)   ; conflicts with parinfer
             (parinfer-rust-mode 1)))
  :init
  (setq parinfer-rust-auto-download t
        parinfer-rust-library-directory (expand-file-name "parinfer-rust/" user-emacs-directory)
        parinfer-rust-library (expand-file-name "parinfer-rust/parinfer-rust-darwin.so" user-emacs-directory))
  :custom
  (parinfer-rust-preferred-mode "indent"))

;; REPL client. Start it with , c j (cider-jack-in).
(use-package cider
  :hook (cider-repl-mode . (lambda () (evil-local-set-key 'insert (kbd "RET") #'my/cider-repl-return)))
  :custom
  (cider-repl-display-help-banner nil)
  (cider-repl-pop-to-buffer-on-connect 'display-only)
  (cider-eldoc-display-for-symbol-at-point nil)) ; let LSP do eldoc

;; Trust these .dir-locals.el values (Integrant reloaded workflow),
;; so Emacs stops asking "may not be safe" when opening project files.
(dolist (pair '((cider-ns-refresh-before-fn . "integrant.repl/halt")
                (cider-ns-refresh-after-fn  . "integrant.repl/go")))
  (add-to-list 'safe-local-variable-values pair))

(provide 'init-clojure)
