;;; init-tabs.el --- One tab (workspace) per project  -*- lexical-binding: t; -*-

;; SPC p p opens a project in its own tab, with its own windows and buffer list;
;; SPC b b then shows only that tab's buffers (SPC b B: all). gt / gT switch tabs.
;; The tab bar only appears with 2+ tabs.
(use-package tabspaces
  :demand t
  :custom
  (tabspaces-use-filtered-buffers-as-default t)
  (tabspaces-project-switch-opens-workspace t)        ; SPC p p -> project tab
  (tabspaces-default-tab "Default")
  (tabspaces-remove-to-default t)
  (tabspaces-include-buffers '("*scratch*" "*Messages*"))
  (tabspaces-initialize-project-with-todo nil)         ; don't create project-todo.org
  (tabspaces-initialize-project-with-vc nil)
  (tabspaces-session nil)
  (tabspaces-keymap-prefix nil)
  (tab-bar-show 1)
  (tab-bar-close-button-show nil)
  (tab-bar-new-button-show nil)
  :config
  (tabspaces-mode 1)
  (setq consult-buffer-list-function #'tabspaces-local-buffer-list))

(defun my/consult-buffer-all ()
  "Switch to any buffer, from all tabs."
  (interactive)
  (let ((consult-buffer-list-function #'buffer-list))
    (consult-buffer)))

(provide 'init-tabs)
