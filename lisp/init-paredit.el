;;; init-paredit.el --- Structural editing for Clojure (keys as nvim-paredit)  -*- lexical-binding: t; -*-

;; Only paredit's commands are used, not paredit-mode (parinfer handles typing).
;; "Form" = the list around the cursor. "Element" = the thing under the cursor.
(use-package paredit
  :commands (paredit-forward-slurp-sexp paredit-forward-barf-sexp
             paredit-backward-slurp-sexp paredit-backward-barf-sexp
             paredit-raise-sexp paredit-splice-sexp))

(defun my/goto-element-start ()
  (when-let ((bounds (bounds-of-thing-at-point 'sexp)))
    (goto-char (car bounds))))

(defun my/goto-form-start ()
  (unless (looking-at-p "[([{]")
    (backward-up-list 1 t t)))

;; ---- drag: move element / form left or right ----
(defun my/drag-forward ()
  (forward-sexp 1) (transpose-sexps 1) (backward-sexp 1))

(defun my/drag-backward ()
  (transpose-sexps 1) (backward-sexp 2))

(defun my/drag-element-forward ()  (interactive) (my/goto-element-start) (my/drag-forward))
(defun my/drag-element-backward () (interactive) (my/goto-element-start) (my/drag-backward))
(defun my/drag-form-forward ()     (interactive) (my/goto-form-start) (my/drag-forward))
(defun my/drag-form-backward ()    (interactive) (my/goto-form-start) (my/drag-backward))

;; ---- raise: replace the parent form with this form / element ----
(defun my/raise-form ()    (interactive) (my/goto-form-start) (paredit-raise-sexp))
(defun my/raise-element () (interactive) (my/goto-element-start) (paredit-raise-sexp))

;; ---- text objects: af / if (form), ae / ie (element) ----
(with-eval-after-load 'evil
  (evil-define-text-object my/a-form (count &optional _beg _end _type)
    (save-excursion (my/goto-form-start) (list (point) (progn (forward-sexp) (point)))))
  (evil-define-text-object my/inner-form (count &optional _beg _end _type)
    (save-excursion (my/goto-form-start) (list (1+ (point)) (progn (forward-sexp) (1- (point))))))
  (evil-define-text-object my/an-element (count &optional _beg _end _type)
    (let ((bounds (bounds-of-thing-at-point 'sexp))) (list (car bounds) (cdr bounds)))))

;; Run these in parinfer "paren" mode, so parinfer keeps the new parens.
(with-eval-after-load 'parinfer-rust-mode
  (dolist (cmd '(paredit-backward-slurp-sexp paredit-backward-barf-sexp
                 paredit-raise-sexp paredit-splice-sexp
                 my/drag-element-forward my/drag-element-backward
                 my/drag-form-forward my/drag-form-backward
                 my/raise-form my/raise-element))
    (add-to-list 'parinfer-rust-treat-command-as (cons cmd "paren"))))

(with-eval-after-load 'clojure-mode
  (evil-define-key 'normal clojure-mode-map
    (kbd ">)") #'paredit-forward-slurp-sexp
    (kbd "<)") #'paredit-forward-barf-sexp
    (kbd ">(") #'paredit-backward-barf-sexp
    (kbd "<(") #'paredit-backward-slurp-sexp
    (kbd ">e") #'my/drag-element-forward
    (kbd "<e") #'my/drag-element-backward
    (kbd ">f") #'my/drag-form-forward
    (kbd "<f") #'my/drag-form-backward
    (kbd "<localleader>o") '("Raise form" . my/raise-form)
    (kbd "<localleader>O") '("Raise element" . my/raise-element)
    (kbd "<localleader>@") '("Splice (remove parens)" . paredit-splice-sexp))
  (evil-define-key '(visual operator) clojure-mode-map
    "af" #'my/a-form   "if" #'my/inner-form
    "ae" #'my/an-element "ie" #'my/an-element))

(provide 'init-paredit)
