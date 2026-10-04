;;; init-python.el --- Python (+ Django)  -*- lexical-binding: t; -*-

;; LSP: pyright (types, completion) + ruff (lint, quick fixes, imports, SPC c f)
;; together via rass. A project's .venv is used automatically (init-env.el).
;; Colors: tree-sitter (python-ts-mode); grammar compiled once (needs cc).
(require 'treesit)
(add-to-list 'treesit-language-source-alist
             '(python "https://github.com/tree-sitter/tree-sitter-python" "v0.21.0"))

(when (and (treesit-available-p)
           (or (treesit-language-available-p 'python)
               (ignore-errors (treesit-install-language-grammar 'python))))
  (add-to-list 'major-mode-remap-alist '(python-mode . python-ts-mode)))

(use-package python
  :ensure nil
  :hook (python-base-mode . (lambda () (my/eglot-if "pyright-langserver")))
  :custom
  (python-indent-offset 4)
  (python-shell-interpreter "python3")
  :config
  (with-eval-after-load 'eglot
    (add-to-list 'eglot-server-programs
                 `((python-mode python-ts-mode)
                   . ,(if (and (executable-find "rass") (executable-find "ruff"))
                          '("rass" "--" "pyright-langserver" "--stdio" "--" "ruff" "server")
                        '("pyright-langserver" "--stdio"))))))

;; Tests: same keys as Clojure (, t c / n / a / f). Runs pytest from the project root.
(use-package python-pytest
  :commands (python-pytest python-pytest-file python-pytest-function
             python-pytest-last-failed python-pytest-repeat))

;; ---- Django: find manage.py upwards from this file ----
(defun my/django-root ()
  (or (locate-dominating-file default-directory "manage.py")
      (user-error "No manage.py found above %s" default-directory)))

;; Full path of the project's Python (.venv), looked up in this buffer: helpers
;; like process-lines run in a temp buffer without the buffer-local venv path.
(defun my/django-python ()
  (or (executable-find "python") (executable-find "python3")))

(defun my/django-manage ()
  "Pick a manage.py command. runserver opens in a terminal, the rest in a compile buffer."
  (interactive)
  (let* ((python (my/django-python))
         (default-directory (my/django-root))
         (commands (seq-remove #'string-blank-p
                               (process-lines python "manage.py" "help" "--commands")))
         (command (completing-read "manage.py: " (mapcar #'string-trim commands))))
    (if (string-prefix-p "runserver" command)
        (my/django-runserver)
      (compile (format "%s manage.py %s" (shell-quote-argument python) command) t))))   ; t = input works (prompts)

(defun my/django-runserver ()
  "Run the dev server in a terminal at the bottom."
  (interactive)
  (let* ((python (my/django-python))
         (root (my/django-root))
         (name (format "*runserver %s*" (file-name-nondirectory (directory-file-name root))))
         (new (not (get-buffer name))))
    (save-window-excursion (my/vterm-in root name))
    (display-buffer name '((display-buffer-in-side-window) (side . bottom) (window-height . 0.25)))
    (when new (with-current-buffer name (vterm-send-string (format "%s manage.py runserver\n" (shell-quote-argument python)))))))

(defun my/django-shell ()
  "Django shell (manage.py shell) as the Python REPL: , e e etc. go there."
  (interactive)
  (let ((python (my/django-python))
        (default-directory (my/django-root)))
    (run-python (format "%s manage.py shell -i python" (shell-quote-argument python)) nil t)))

;; Templates: {% %} / {{ }} highlighting in templates/**/*.html, Emmet works there.
(use-package web-mode
  :mode ("/templates/.*\\.html\\'" . web-mode)
  :hook (web-mode . emmet-mode)
  :custom
  (web-mode-engines-alist '(("django" . "/templates/.*\\.html\\'")))
  (web-mode-markup-indent-offset 2)
  (web-mode-code-indent-offset 2))

;; "," = Python commands, same layout as Clojure.
(with-eval-after-load 'python
  (evil-define-key 'normal python-base-mode-map
    (kbd "<localleader>cj") '("Start REPL" . run-python)                    ; start REPL
    (kbd "<localleader>ee") '("Eval statement" . python-shell-send-statement)   ; current statement
    (kbd "<localleader>er") '("Eval function / class" . python-shell-send-defun)       ; function / class
    (kbd "<localleader>eb") '("Eval buffer" . python-shell-send-buffer)
    (kbd "<localleader>lg") '("Go to REPL" . python-shell-switch-to-shell)
    (kbd "<localleader>tc") '("Test at cursor" . python-pytest-function)        ; test at cursor
    (kbd "<localleader>tn") '("Tests in file" . python-pytest-file)            ; this file
    (kbd "<localleader>ta") '("pytest menu" . python-pytest)                 ; all (menu)
    (kbd "<localleader>tf") '("Rerun failed tests" . python-pytest-last-failed)
    (kbd "<localleader>tr") '("Repeat last run" . python-pytest-repeat)
    (kbd "<localleader>dm") '("manage.py command" . my/django-manage)
    (kbd "<localleader>dr") '("Run dev server" . my/django-runserver)
    (kbd "<localleader>ds") '("Django shell" . my/django-shell))
  (evil-define-key 'visual python-base-mode-map
    (kbd "<localleader>ee") '("Eval selection" . python-shell-send-region)))

(provide 'init-python)
