;;; init-preview.el --- Markdown/AsciiDoc previews that look like GitHub  -*- lexical-binding: t; -*-

;; , o (Markdown, AsciiDoc): browser preview with GitHub's own CSS (preview/), light or
;; dark like macOS. Every save re-renders it; the page reloads itself (scroll stays).
;; , p (eww inside Emacs) ignores CSS: the shr faces below only bring it closer to GitHub.

(require 'url-util)

(defvar my/preview-css-dir (expand-file-name "preview/" user-emacs-directory))
(defvar my/preview-out-dir (expand-file-name "emacs-preview/" temporary-file-directory))
(defvar-local my/preview-browser-live nil "Re-render the browser preview on save.")

(defun my/preview--url (file) (concat "file://" (url-hexify-string file url-path-allowed-chars)))

(defun my/preview--out (ext)
  "Output file for this buffer, e.g. /tmp/emacs-preview/1a2b3c4d-README.html."
  (expand-file-name (format "%s-%s.%s" (substring (md5 buffer-file-name) 0 8)
                            (file-name-base buffer-file-name) ext)
                    my/preview-out-dir))

(defun my/preview--body (adoc)
  "HTML body of this buffer (also unsaved text), as GitHub renders it."
  (let ((cmd (if adoc
                 `("asciidoctor" "-s" "-a" "showtitle" "-a" "source-highlighter=rouge"
                   "-a" "rouge-css=class" "-B" ,default-directory "-o" "-" "-")
               '("pandoc" "-f" "gfm" "-t" "html5" "--syntax-highlighting=pygments")))
        (src (current-buffer))
        (coding-system-for-read 'utf-8)
        (coding-system-for-write 'utf-8))
    (with-temp-buffer
      (let ((out (current-buffer)))
        (with-current-buffer src
          (save-restriction
            (widen)
            (apply #'call-process-region (point-min) (point-max) (car cmd) nil (list out nil) nil (cdr cmd)))))
      (unless adoc (my/preview--github-classes))
      (buffer-string))))

(defun my/preview--github-classes ()
  "Rename pandoc's alert and task list classes to the ones GitHub's CSS styles."
  (goto-char (point-min))
  (while (re-search-forward "<div class=\"\\(note\\|tip\\|important\\|warning\\|caution\\)\">\n<div class=\"title\">\n<p>\\([^<]*\\)</p>\n</div>" nil t)
    (replace-match "<div class=\"markdown-alert markdown-alert-\\1\">\n<p class=\"markdown-alert-title\">\\2</p>" t))
  (goto-char (point-min))
  (while (search-forward "<ul class=\"task-list\">" nil t) (replace-match "<ul class=\"contains-task-list\">" t t))
  (goto-char (point-min))
  (while (search-forward "<li><label><input type=\"checkbox\"" nil t)
    (replace-match "<li class=\"task-list-item\"><label><input type=\"checkbox\" class=\"task-list-item-checkbox\" disabled=\"\"" t t)))

(defun my/preview--page (title body css stamp stamp-js)
  (concat
   "<!DOCTYPE html>\n<html><head><meta charset=\"utf-8\">\n"
   (format "<base href=\"%s\">\n<title>%s</title>\n" (my/preview--url default-directory) title)
   (mapconcat (lambda (f) (format "<link rel=\"stylesheet\" href=\"%s\">\n"
                                  (my/preview--url (expand-file-name f my/preview-css-dir))))
              css "")
   ;; Page frame like github.com: 980px column; dark page when macOS is dark.
   "<style>body{box-sizing:border-box;min-width:200px;max-width:980px;margin:0 auto;padding:45px}"
   "@media (max-width:767px){body{padding:15px}}"
   "@media (prefers-color-scheme:dark){body{background:#0d1117}}</style>\n"
   "</head><body><article class=\"markdown-body\">\n" body "\n</article>\n"
   ;; Live reload: poll the stamp file; a new stamp means Emacs saved, so reload.
   (format "<script>(function(){var loaded=%s;window.myPreviewStamp=function(s){if(s!==loaded)location.reload();};
setInterval(function(){var el=document.createElement('script');el.src='%s?'+Date.now();
el.onload=el.onerror=function(){el.remove();};document.head.appendChild(el);},1000);})();</script>\n"
           stamp (my/preview--url stamp-js))
   "</body></html>\n"))

(defun my/preview--render ()
  "Write the GitHub-style HTML for this buffer; return its file name."
  (make-directory my/preview-out-dir t)
  (let* ((adoc (derived-mode-p 'adoc-mode))
         (html (my/preview--out "html"))
         (stamp-js (my/preview--out "js"))
         (stamp (format-time-string "%s%3N"))
         (css (if adoc '("github-markdown.css" "rouge-github.css" "asciidoc-extra.css")
                '("github-markdown.css" "pandoc-highlight.css")))
         (page (my/preview--page (file-name-nondirectory buffer-file-name)
                                 (my/preview--body adoc) css stamp stamp-js))
         (coding-system-for-write 'utf-8))
    (with-temp-file html (insert page))
    (with-temp-file stamp-js (insert (format "myPreviewStamp(%s);\n" stamp)))  ; after the html
    html))

(defun my/preview--on-save () (when my/preview-browser-live (my/preview--render)))

(defun my/preview-browser ()
  "Show this Markdown/AsciiDoc file in the browser like GitHub; refreshes on save."
  (interactive)
  (unless buffer-file-name (user-error "Save the file first"))
  (setq my/preview-browser-live t)
  (add-hook 'after-save-hook #'my/preview--on-save nil t)
  (browse-url-of-file (my/preview--render)))

;; eww (, p): GitHub-like sizes and font as far as it goes (no CSS, no boxes).
(with-eval-after-load 'shr
  (setq shr-max-width 100)                                   ; ~ github.com column
  (set-face-attribute 'shr-text nil :family "Helvetica Neue")
  (set-face-attribute 'shr-code nil :inherit '(fixed-pitch hl-line))
  (dolist (spec '((shr-h1 2.0) (shr-h2 1.5) (shr-h3 1.25) (shr-h4 1.0) (shr-h5 0.875) (shr-h6 0.85)))
    (set-face-attribute (car spec) nil :height (cadr spec) :weight 'semi-bold)))

(provide 'init-preview)
