;; -*- lexical-binding: t; -*-


;; Setup a custom file to store local customizations from customize commands.
(setq custom-file (locate-user-emacs-file "custom.el"))
(unless (file-exists-p custom-file)
  (make-empty-file custom-file))
(load custom-file nil t)


(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
(package-initialize)
(unless package-archive-contents
  (package-refresh-contents))

(use-package exec-path-from-shell
  :ensure t
  :init (exec-path-from-shell-initialize))

(use-package dimmer
  :ensure t
  :custom
  (dimmer-fraction 0.25)
  (dimmer-use-colorspace :cielab)
  :config
  (dimmer-configure-magit)
  (dimmer-configure-which-key)
  (add-to-list 'dimmer-buffer-exclusion-regexps "^ \\*corfu")
  (dimmer-mode 1))


(use-package spacious-padding
  :ensure t
  :custom
  (spacious-padding-widths '(:internal-border-width 16 :right-divider-width 16 :fringe-width 16 :mode-line-width 4))
  (spacious-padding-subtle-mode-line t)
  :config
  (spacious-padding-mode 1))

(use-package simple-modeline
  :ensure t
  :init (simple-modeline-mode))

(use-package magit
  :ensure t)

(use-package vertico
  :ensure t
  :init
  (vertico-mode 1))

(use-package eat
  :ensure t)

(use-package eglot
  :ensure nil
  :hook
  ((c-mode c-ts-mode c++-mode c++-ts-mode) . eglot-ensure)
  :custom
  (eglot-ignored-server-capabilities '(:documentOnTypeFormattingProvider)))

(use-package corfu
  :ensure t
  :bind (:map corfu-map ("RET" . nil))
  :init
  (global-corfu-mode 1)
  (corfu-popupinfo-mode 1)
  :custom
  (corfu-auto t)
  (corfu-auto-delay 0.2)
  (corfu-auto-prefix 2)
  (corfu-quit-at-boundary nil)
  (corfu-quit-no-match t)
  (corfu-popupinfo-delay '(2.0 . 0.0)))

(use-package dirvish
  :ensure t
  :config
  (dirvish-override-dired-mode))

(use-package orderless
  :ensure t
  :custom
  (completion-styles '(orderless basic))
  (orderless-matching-styles '(orderless-literal orderless-regexp orderless-flex))
  (completion-category-overrides '((eglot (styles orderless))
				   (eglot-capf (styles orderless)))))

(use-package consult
  :ensure t)

(use-package affe
  :ensure t)

(use-package doom-themes
  :ensure t)

(load-theme 'doom-gruvbox t)
(setq-default tab-width 4)

(global-display-line-numbers-mode 1)
;; Enable auto pairing
(electric-pair-mode 1)
;; Savehist mode makes vertico work better.
(savehist-mode 1)
;; Enable default windmove bindings.
(windmove-default-keybindings)

(setq whitespace-line-column 120)
(setq whitespace-style '(face trailing lines-tail newline space-mark tab-mark newline-mark))
(global-whitespace-mode 1)


(add-hook 'prog-mode-hook (lambda ()
			    (setq truncate-lines t
				  truncate-partial-width-windows nil)))
