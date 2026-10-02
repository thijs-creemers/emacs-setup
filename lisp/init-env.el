;;; init-env.el --- Load .env from the project root per buffer  -*- lexical-binding: t; -*-

;; Opening a file in a project with a .env sets those vars for that buffer only.
;; Everything started from it gets them: cider-jack-in, eglot, run-python, shell.
;; Edited .env? New buffers pick it up; SPC p e updates open ones.
;; Vars from .env that Emacs ignores (meant for Docker, break local tools).
(defvar my/dotenv-skip-vars '("JAVA_OPTS"))

(defun my/parse-dotenv (file)
  "Return KEY=VALUE strings from FILE. Supports comments, quotes, `export'."
  (with-temp-buffer
    (insert-file-contents file)
    (let (vars)
      (while (re-search-forward
              "^[ \t]*\\(?:export[ \t]+\\)?\\([A-Za-z_][A-Za-z0-9_]*\\)[ \t]*=[ \t]*\\(.*\\)$" nil t)
        (let ((key (match-string 1))
              (value (string-trim (match-string 2))))
          (setq value (if (string-match "\\`\\([\"']\\)\\(.*\\)\\1" value)
                          (match-string 2 value)                       ; quoted
                        (replace-regexp-in-string "[ \t]+#.*\\'" "" value))) ; strip comment
          (unless (member key my/dotenv-skip-vars)
            (push (concat key "=" value) vars))))
      (nreverse vars))))

(defvar my/dotenv-cache (make-hash-table :test 'equal)
  "Directory -> .env file of its project (or :none). Avoids project lookups.")

(defvar my/dotenv-file-cache (make-hash-table :test 'equal)
  ".env file -> (modification-time . vars). Re-read when the file changes.")

(defun my/dotenv-vars (file)
  (let ((mtime (file-attribute-modification-time (file-attributes file)))
        (cached (gethash file my/dotenv-file-cache)))
    (if (equal mtime (car cached))
        (cdr cached)
      (let ((vars (my/parse-dotenv file)))
        (puthash file (cons mtime vars) my/dotenv-file-cache)
        vars))))

(defun my/dotenv-for-directory (dir)
  (let ((file (gethash dir my/dotenv-cache)))
    (unless file
      (let ((project (project-current nil dir)))
        (setq file (or (and project (expand-file-name ".env" (project-root project))) :none))
        (puthash dir file my/dotenv-cache)))
    (when (and (stringp file) (file-readable-p file))
      (my/dotenv-vars file))))

(defun my/load-project-dotenv ()
  "Set this buffer's environment from .env in its project root."
  (unless (string-prefix-p " " (buffer-name))      ; skip internal temp buffers
    (when-let ((vars (my/dotenv-for-directory default-directory)))
      (setq-local process-environment
                  (append vars (default-value 'process-environment))))))

(defun my/reload-project-dotenv ()
  "Re-read .env and apply it to all open buffers of the current project."
  (interactive)
  (clrhash my/dotenv-cache)
  (clrhash my/dotenv-file-cache)
  (dolist (buffer (project-buffers (project-current t)))
    (with-current-buffer buffer (my/load-project-dotenv)))
  (message "Reloaded .env for project"))

;; Runs for every buffer (files, REPLs, *compilation*), not only files.
;; CIDER sets the REPL's directory after its mode, so also run on connect.
(add-hook 'after-change-major-mode-hook #'my/load-project-dotenv)
(add-hook 'cider-connected-hook #'my/load-project-dotenv)

(provide 'init-env)
