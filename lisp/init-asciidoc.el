;;; init-asciidoc.el --- AsciiDoc  -*- lexical-binding: t; -*-

;; Headings for SPC f s / , i: adoc-mode's nested index returns nothing, so
;; use its flat list, indented per level to show the structure.
(defun my/adoc-imenu-index ()
  (mapcar (lambda (item)
            (cons (concat (make-string (* 2 (adoc--imenu-heading-level nil (cdr item))) ?\s)
                          (substring-no-properties (car item)))
                  (cdr item)))
          (adoc-imenu-create-index)))

;; Rendering uses asciidoctor / asciidoctor-pdf (brew install asciidoctor).
(use-package adoc-mode
  :mode ("\\.a\\(?:sc\\)?doc\\'" . adoc-mode)
  :hook (adoc-mode . (lambda ()
                       (visual-line-mode 1)       ; wrap long lines at words
                       (display-line-numbers-mode 1)
                       (setq-local imenu-create-index-function #'my/adoc-imenu-index)
                       (add-hook 'after-save-hook #'my/adoc-refresh-preview nil t)))
  :config
  ;; "," = AsciiDoc commands.
  (evil-define-key 'normal adoc-mode-map
    (kbd "<localleader>p") '("Preview" . my/adoc-preview)          ; preview side by side
    (kbd "<localleader>o") '("Preview in browser (GitHub look)" . my/preview-browser)
    (kbd "<localleader>P") '("Export PDF" . my/adoc-export-pdf)
    (kbd "<localleader>i") '("Jump to heading" . consult-imenu)))          ; jump to heading

;; Render to HTML in /tmp. data-uri embeds images, so they still show.
(defun my/adoc-render-html ()
  (let ((out (expand-file-name (concat (file-name-base buffer-file-name) ".html")
                               temporary-file-directory)))
    (call-process "asciidoctor" nil nil nil "-a" "data-uri" "-o" out buffer-file-name)
    out))

(defun my/adoc-show-preview ()
  "Render and show the HTML in a window on the right."
  (let ((html (my/adoc-render-html)))
    (save-selected-window
      (select-window (or (get-buffer-window "*eww*") (split-window-right)))
      (eww-open-file html))))

(defun my/adoc-preview ()
  "Save and show preview. After this, every save refreshes it."
  (interactive)
  (save-buffer)
  (unless (get-buffer-window "*eww*")
    (my/adoc-show-preview)))

;; Runs on save: update the preview only when it is visible.
(defun my/adoc-refresh-preview ()
  (when (get-buffer-window "*eww*")
    (my/adoc-show-preview)))

(defun my/adoc-export-pdf ()
  "Export to a PDF next to the source file and open it."
  (interactive)
  (save-buffer)
  (let ((pdf (concat (file-name-sans-extension buffer-file-name) ".pdf")))
    (call-process "asciidoctor-pdf" nil nil nil buffer-file-name)
    (browse-url-of-file pdf)))

(provide 'init-asciidoc)
