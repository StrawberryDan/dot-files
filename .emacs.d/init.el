;; -*- lexical-binding: t; -*-


;;==========================================================
;;
;;==========================================================
(use-package emacs
  :preface
  (defconst my/help-buffer-list
    '(help-mode Man-mode Info-mode))
  (defun my/help-buffer-p (buf _action)
    (with-current-buffer buf
      (derived-mode-p my/help-buffer-list)))
  (defun my/prog-mode-hook ()
    (whitespace-mode 1)
    (setq-local truncate-lines t))

  (defvar-keymap my/code-map
    :name "Code Map"
    :doc "Code Commands"
    :prefix t)
  (keymap-global-set "C-c c" my/code-map)
  (defvar-keymap my/find-map
    :name "Find Map"
    :doc "Find Commands"
    :prefix t)
  (keymap-global-set "C-c f" my/find-map)
  (defvar-keymap my/goto-map
    :name "Goto Map"
    :doc "Find Commands"
    :prefix t)
  (keymap-global-set "C-c g" my/goto-map)
  (defvar-keymap my/mark-map
    :name "Mark Map"
    :doc "Mark Commands"
    :prefix t
    "b" #'mark-whole-buffer)
  (keymap-global-set "C-c m" my/mark-map)

  :init
  ;; Setup a custom file to store local customizations from customize commands.
  (setq custom-file (locate-user-emacs-file "custom.el"))
  (unless (file-exists-p custom-file)
    (make-empty-file custom-file))
  (load custom-file nil t)
  ;; Setup package library
  (require 'package)
  (add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
  (package-initialize)
  (unless package-archive-contents
    (package-refresh-contents))
  ;; No silly tab sizes
  (setq-default tab-width 4)
  ;; Whitespace styling
  (setq whitespace-style '(face trailing lines-tail newline space-mark tab-mark newline-mark))
  ;; Setup scrolling
  (setq scroll-conservatively 5
        scroll-margin         5
        hscroll-margin        10
        hscroll-step          0.33
        hscroll-margin        8)
  ;; Setup display buffer alist
  (setq display-buffer-alist
        `( ("\\*claude-code"
            . ((display-buffer-in-side-window)
               . ((side . right) (slot . 1) (window-width . 0.25))))
           (my/help-buffer-p
            . ((display-buffer-in-side-window
                display-buffer-reuse-mode-window)
               . ((side . right) (slot . 0) (window-width . 0.25)
                  (mode . ,my/help-buffer-list)))) ))
  :config
  (global-display-line-numbers-mode 1)
  ;; Enable auto pairing
  (electric-pair-mode 1)
  ;; Savehist mode makes vertico work better.
  (savehist-mode 1)
  ;; Enable default windmove bindings.
  (windmove-default-keybindings)
  ;; I don't like tabs
  (indent-tabs-mode -1)

  (repeat-mode +1)
  :hook
  ( (prog-mode . my/prog-mode-hook) ))


(use-package darcula-theme
  :ensure t
  :demand t
  :config
  (load-theme 'darcula t)
  ;; Darcula doesn't style Customize buttons; without these spacious-padding
  ;; leaves them unstyled and indistinguishable from plain text.
  (custom-theme-set-faces
   'darcula
   '(default               ((t (:height 160))))
   '(custom-button         ((t (:background "#4C5052" :foreground "#BBBBBB"))))
   '(custom-button-mouse   ((t (:background "#5C6164" :foreground "#BBBBBB"))))
   '(custom-button-pressed ((t (:background "#365880" :foreground "#BBBBBB")))))
  (enable-theme 'darcula))


(when (memq system-type '(darwin gnu gnu/linux gnu/freebsd))
  (use-package exec-path-from-shell
    :ensure t
    :demand t
    :config
    (exec-path-from-shell-initialize)))


(use-package vterm
  :ensure t)


(use-package claude-code-ide
  :ensure t
  :after vterm
  :vc (:url "https://github.com/manzaltu/claude-code-ide.el" :rev :newest)
  :config
  (claude-code-ide-emacs-tools-setup)
  (setq claude-code-ide-terminal-backend 'vterm))

(use-package treesit
  :ensure nil
  :preface
  (defun my/treesit-c++-indent-override-rules ()
  (setq treesit-simple-indent-override-rules
		'((cpp
		   ((n-p-gp "declaration_list" "namespace_definition" nil) parent 0)
		   ((n-p-gp nil "declaration_list" "namespace_definition") grand-parent c-ts-indent-offset)))))
  :config
  (setq treesit-language-source-alist
        '((cpp "https://github.com/tree-sitter/tree-sitter-cpp")
          (c   "https://github.com/tree-sitter/tree-sitter-c")))
  (dolist (map '((c-mode   . c-ts-mode)
                 (c++-mode . c++-ts-mode)))
    (add-to-list 'major-mode-remap-alist map))
  (setq c-ts-indent-offset 4)
  (setq c-ts-mode-indent-style 'bsd)
  :hook (c++-ts-mode . my/treesit-c++-indent-override-rules))

(use-package spacious-padding
  :ensure t
  :custom
  (spacious-padding-widths
   '( :internal-border-width 4
      :right-divider-width 4
      :mode-line-width 4))
  (spacious-padding-subtle-mode-line t)
  :config
  (spacious-padding-mode 1))


(use-package cape
  :ensure t)


(use-package magit
  :ensure t)

(use-package vertico
  :ensure t
  :config
  (vertico-mode 1))

(use-package eat
  :ensure t)

(use-package eglot
  :ensure nil
  :demand t
  :hook
  ((c-mode c-ts-mode c++-mode c++-ts-mode) . eglot-ensure)
  :custom
  (eglot-server-programs '(((c-mode c++-mode c-ts-mode c++-ts-mode) . ("clangd"))))
  (eglot-ignored-server-capabilities '(:documentOnTypeFormattingProvider))
  )

(use-package corfu
  :ensure t
  :preface
  (defun my/corfu-prog-mode-hook ()
    (corfu-mode +1)
    (corfu-popupinfo-mode +1))
  :custom
  (corfu-auto t)
  (corfu-auto-delay 1.0)
  (corfu-auto-prefix 2)
  :hook
  ( (prog-mode . my/corfu-prog-mode-hook)
    (eval-expression-minibuffer-setup . corfu-mode) ))


(use-package dirvish
  :ensure t
  :config
  (dirvish-override-dired-mode))

(use-package orderless
  :ensure t
  :after cape
  :custom
  ( completion-styles '(orderless) )
  ( completion-category-defaults nil )
  ( orderless-matching-styles '(orderless-literal orderless-regexp orderless-prefixes )))

(use-package consult
  :ensure t
  :bind
  ( :map my/goto-map
    ("l" . consult-line) ))

(use-package consult-imenu
  :bind
  ( :map my/goto-map
    ("f" . consult-imenu) ))

(use-package affe
  :ensure t)

(use-package expreg
  :ensure t
  :bind
  ( :map my/mark-map
    ("e" . expreg-expand)
    ("E" . expreg-contract)
    :repeat-map my/mark-map-repeat
    ("e" . expreg-expand)
    ("E" . expreg-contract) ))


