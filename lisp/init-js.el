;;; init-js.el --- JavaScript / TypeScript / JSON  -*- lexical-binding: t; -*-

;; Colors: built-in tree-sitter modes; grammars compiled once (needs cc).
;; LSP: TypeScript 7's own server (`tsc --lsp`, npm i -g typescript), JS too.
;; JSON: vscode-json-language-server (vscode-langservers-extracted).
(require 'treesit)
(dolist (source '((javascript "https://github.com/tree-sitter/tree-sitter-javascript" "v0.21.4")
                  (typescript "https://github.com/tree-sitter/tree-sitter-typescript" "v0.21.2" "typescript/src")
                  (tsx "https://github.com/tree-sitter/tree-sitter-typescript" "v0.21.2" "tsx/src")
                  (jsdoc "https://github.com/tree-sitter/tree-sitter-jsdoc" "v0.21.0")
                  (json "https://github.com/tree-sitter/tree-sitter-json" "v0.21.0")))
  (add-to-list 'treesit-language-source-alist source))

(defun my/js-grammars-ready-p ()
  (seq-every-p (lambda (lang) (or (treesit-language-available-p lang)
                                  (ignore-errors (treesit-install-language-grammar lang))))
               '(javascript typescript tsx jsdoc json)))

(when (and (treesit-available-p) (my/js-grammars-ready-p))
  (add-to-list 'auto-mode-alist '("\\.[cm]?jsx?\\'" . js-ts-mode))
  (add-to-list 'auto-mode-alist '("\\.[cm]?ts\\'" . typescript-ts-mode))
  (add-to-list 'auto-mode-alist '("\\.tsx\\'" . tsx-ts-mode))
  (add-to-list 'auto-mode-alist '("\\.json\\'" . json-ts-mode))
  (dolist (remap '((js-mode . js-ts-mode) (javascript-mode . js-ts-mode) (js-json-mode . json-ts-mode)))
    (add-to-list 'major-mode-remap-alist remap)))

(setq js-indent-level 2
      typescript-ts-mode-indent-offset 2
      json-ts-mode-indent-offset 2)

(defun my/js-setup ()
  (setq-local tab-width 2)                       ; formatter (SPC c f) uses tab-width
  (my/eglot-if "tsc"))

(add-hook 'js-ts-mode-hook #'my/js-setup)
(add-hook 'typescript-ts-mode-hook #'my/js-setup)
(add-hook 'tsx-ts-mode-hook #'my/js-setup)
(add-hook 'json-ts-mode-hook (lambda () (my/eglot-if "vscode-json-language-server")))
(add-hook 'tsx-ts-mode-hook #'emmet-mode)        ; div.card + C-j in JSX
(add-hook 'js-ts-mode-hook #'emmet-mode)

(with-eval-after-load 'eglot
  (add-to-list 'eglot-server-programs
               '((js-ts-mode typescript-ts-mode tsx-ts-mode) . ("tsc" "--lsp" "--stdio"))))

;; ---- "," menu (same layout as Clojure/Python) ----
;; Node REPL via js-comint. Node 22.18+ runs .ts files directly (strips types),
;; but its REPL doesn't know types: in TS, , e b runs the file instead.
(use-package js-comint
  :commands (js-comint-repl js-comint-start-or-switch-to-repl js-comint-send-last-sexp
             js-comint-send-region js-comint-send-buffer))

(defun my/js--root ()
  (or (locate-dominating-file default-directory "package.json") default-directory))

(defun my/js--package ()
  "package.json of this project as an alist (nil if none)."
  (let ((file (expand-file-name "package.json" (my/js--root))))
    (when (file-readable-p file)
      (with-temp-buffer (insert-file-contents file) (json-parse-buffer :object-type 'alist)))))

(defun my/js-run-file ()
  "Run this file with node (TypeScript too)."
  (interactive)
  (save-buffer)
  (compile (concat "node " (shell-quote-argument buffer-file-name)) t))

(defun my/js-eval-buffer ()
  "JS: send the buffer to the Node REPL. TS: run the file."
  (interactive)
  (if (derived-mode-p 'typescript-ts-base-mode) (my/js-run-file) (js-comint-send-buffer)))

(defun my/js-test (&optional this-file)
  "Run tests with the project's runner: Vitest, Jest, else node --test."
  (let* ((pkg (my/js--package))
         (deps (append (alist-get 'devDependencies pkg) (alist-get 'dependencies pkg)))
         (file (and this-file (shell-quote-argument (file-relative-name buffer-file-name (my/js--root)))))
         (default-directory (my/js--root)))
    (compile (cond ((assq 'vitest deps) (concat "npx vitest run " file))
                   ((assq 'jest deps) (concat "npx jest " file))
                   (file (concat "node --test " file))
                   ((alist-get 'test (alist-get 'scripts pkg)) "npm test")
                   (t "node --test"))
             t)))

(defun my/js-test-file () "Run the tests in this file." (interactive) (my/js-test t))
(defun my/js-test-all () "Run all tests." (interactive) (my/js-test))

(with-eval-after-load 'evil
  (dolist (map '(js-base-mode-map typescript-ts-base-mode-map))
    (with-eval-after-load (if (eq map 'js-base-mode-map) 'js 'typescript-ts-mode)
      (evil-define-key 'normal (symbol-value map)
        (kbd "<localleader>cj") '("Start Node REPL" . js-comint-start-or-switch-to-repl)
        (kbd "<localleader>ee") '("Eval expression" . js-comint-send-last-sexp)
        (kbd "<localleader>eb") '("Eval buffer (TS: run file)" . my/js-eval-buffer)
        (kbd "<localleader>lg") '("Go to REPL" . js-comint-start-or-switch-to-repl)
        (kbd "<localleader>rr") '("Run this file" . my/js-run-file)
        (kbd "<localleader>tn") '("Tests in this file" . my/js-test-file)
        (kbd "<localleader>ta") '("All tests" . my/js-test-all)
        (kbd "<localleader>o") '("Organize imports" . eglot-code-action-organize-imports)
        (kbd "<localleader>n") '("Run npm script" . my/npm-script))
      (evil-define-key 'visual (symbol-value map)
        (kbd "<localleader>ee") '("Eval selection" . js-comint-send-region)))))

;; SPC t n: pick an npm script from the nearest package.json and run it.
(defun my/npm-script ()
  "Choose and run a script from package.json."
  (interactive)
  (let* ((root (or (locate-dominating-file default-directory "package.json")
                   (user-error "No package.json found above %s" default-directory)))
         (default-directory root)
         (scripts (with-temp-buffer
                    (insert-file-contents (expand-file-name "package.json" root))
                    (alist-get 'scripts (json-parse-buffer :object-type 'alist))))
         (completion-extra-properties
          `(:annotation-function ,(lambda (s) (concat "  " (alist-get (intern s) scripts))))))
    (unless scripts (user-error "No scripts in package.json"))
    (compile (concat "npm run " (completing-read "npm script: " (mapcar (lambda (s) (symbol-name (car s))) scripts) nil t))
             t)))

(provide 'init-js)
