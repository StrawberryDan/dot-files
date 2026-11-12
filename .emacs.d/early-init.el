;; -*- lexical-binding: t; -*-

;; Disable garbage collection on startup
(setq gc-cons-threshold most-positive-fixnum)

;; Restore the gc threshold to a sensible value after starup finishes
(defun my/restore-gc-threshold ()
  (setq gc-cons-threshold (* 128 1024 1024)))
(add-hook 'emacs-startup-hook #'my/restore-gc-threshold)
