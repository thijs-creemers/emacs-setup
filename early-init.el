;;; early-init.el --- Runs before the GUI and packages load  -*- lexical-binding: t; -*-

;; Faster startup: delay garbage collection (reset in init.el).
(setq gc-cons-threshold most-positive-fixnum)

;; Hide UI clutter before the first frame is drawn.
(push '(menu-bar-lines . 0) default-frame-alist)
(push '(tool-bar-lines . 0) default-frame-alist)
(push '(vertical-scroll-bars) default-frame-alist)

(setq inhibit-startup-screen t)
