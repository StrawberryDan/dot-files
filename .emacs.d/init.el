;; -*- lexical-binding: t; -*-


;;==========================================================
;; Emacs Base Configuration
;;==========================================================
(use-package emacs
  :preface
  (defconst my/help-buffer-list
    '(help-mode Man-mode Info-mode))
  (defun my/help-buffer-p (buf _action)
    (with-current-buffer buf
      (or
       (derived-mode-p my/help-buffer-list)
       (string-match "\\*Man.*?\\*" buf))))
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


  :init
  ;; Setup keybindings
  (keymap-global-set "C-c m" my/mark-map)
  ;; Put F9 to C-c for additional invoke.
  (keymap-set key-translation-map "<f9>" "C-c")

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
        `(((derived-mode prog-mode)
           (display-buffer-same-window display-buffer-reuse-mode-window)
           (mode . prog-mode))
          (my/help-buffer-p
           . ((display-buffer-in-side-window
               display-buffer-reuse-mode-window)
              . ((side . right) (slot . 0) (window-width . 0.25)
                 (mode . ,my/help-buffer-list) (preserve-size . (t . t)))))
           ((derived-mode compilation-mode)
            (display-buffer-in-side-window display-buffer-reuse-window)
            (side . bottom) (slot . -1) (window-height . 20) (mode . compilation-mode) (preserve-size . (t . t))) ))
  ;; I don't like tabs
  (setq-default indent-tabs-mode nil)

  ;; Configure compile mode
  (setq compilation-scroll-output 'first-error
        compilation-skip-threshold 2)

  :config
  (global-display-line-numbers-mode 1)
  ;; Enable auto pairing
  (electric-pair-mode 1)
  ;; Savehist mode makes vertico work better.
  (savehist-mode 1)
  ;; Enable default windmove bindings.
  (windmove-default-keybindings)

  (repeat-mode +1)
  :hook
  ( (prog-mode . my/prog-mode-hook) ))


(when (memq system-type '(darwin gnu gnu/linux gnu/freebsd))
  (use-package exec-path-from-shell
    :ensure t
    :demand t
    :config
    (exec-path-from-shell-initialize)))


;;==========================================================
;; Language Support
;;==========================================================
(use-package treesit
  :ensure nil
  :demand t
  :preface
  (defun my/treesit-c++-indent-override-rules ()
    (setq treesit-simple-indent-override-rules
          '((cpp
             ((n-p-gp "declaration_list" "namespace_definition" nil) parent 0)
             ((n-p-gp "}" "declaration_list" "namespace_definition") parent 0)
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


(use-package eglot
  :ensure nil
  :demand t
  :hook
  ((c-mode c-ts-mode c++-mode c++-ts-mode) . eglot-ensure)
  :custom
  (eglot-server-programs '(((c-mode c++-mode c-ts-mode c++-ts-mode) . ("clangd"))))
  (eglot-ignored-server-capabilities '(:documentOnTypeFormattingProvider)))


;;==========================================================
;; Navigation
;;==========================================================
(use-package winner
  :ensure nil
  :init
  (winner-mode 1))


(use-package avy
  :ensure t
  :demand t
  :bind
  ( :map my/goto-map
    ("g" . avy-goto-char-timer)
    ("l" . avy-goto-line)
    ("w" . avy-goto-word-1)))

(use-package ace-window
  :ensure t
  :config
  (setq aw-keys '(?a ?s ?d ?f ?j ?k ?l ?l)
        aw-dispatch-alist '((?m aw-swap-window "Swap")
                            (?M aw-move-window "Move")
                            (?x aw-delete-window "Kill")
                            (?? aw-show-dispatch-help)))
  :bind
  (("C-c w" . ace-window)))


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
  ( :map my/find-map
    ("l" . consult-line) ))


(use-package consult-imenu
  :bind
  ( :map my/goto-map
    ("f" . consult-imenu) ))


(use-package consult-eglot
  :ensure t
  :bind
  ( :map my/find-map
    ("s" . consult-eglot-symbols)))


(use-package affe
  :ensure t
  :bind
  ( :map my/find-map
    ("f" . affe-find)
    ("F" . affe-grep)))


(use-package dirvish
  :ensure t
  :config
  (dirvish-override-dired-mode))


;;==========================================================
;; Appearence
;;==========================================================
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


;;==========================================================
;; Competion
;;==========================================================
(use-package cape
  :ensure t)


(use-package vertico
  :ensure t
  :config
  (vertico-mode 1))


(use-package marginalia
  :ensure t
  :config
  (marginalia-mode 1))


(use-package corfu
  :ensure t
  :preface
  (defun my/corfu-prog-mode-hook ()
    (corfu-mode +1)
    (corfu-popupinfo-mode +1))
  :config
  (setq corfu-auto t
        corfu-auto-delay 0.4
        corfu-auto-prefix 2)
  :hook
  ( (prog-mode . my/corfu-prog-mode-hook)
    (eval-expression-minibuffer-setup . corfu-mode) ))


;;==========================================================
;; Programming
;;==========================================================
(use-package magit
  :ensure t
  :demand t
  :config
  (setq magit-display-buffer-function 'display-buffer)
  (add-to-list 'display-buffer-alist
               '((derived-mode magit-status-mode)
                 (display-buffer-in-side-window display-buffer-reuse-mode-window)
                 (side . left) (slot . 0) (window-width . 0.33) (mode . magit-status-mode) (preserve-size . (t . t)))))


(use-package diff-hl
  :ensure t
  :demand t
  :config
  (global-diff-hl-mode +1)
  (diff-hl-flydiff-mode +1)
  :hook
  ((dired-mode . diff-hl-dired-mode)))


(use-package expreg
  :ensure t
  :bind
  ( :map my/mark-map
    ("e" . expreg-expand)
    ("E" . expreg-contract)
    :repeat-map my/mark-map-repeat
    ("e" . expreg-expand)
    ("E" . expreg-contract) ))


;;==========================================================
;; Terminal Emulator
;;==========================================================
(use-package eat
  :ensure t
  :preface
  ;; Eat's bundled terminfo is compiled by a newer ncurses than macOS ships,
  ;; so eat-truecolor/eat-256color are unreadable and zsh treats the terminal
  ;; as unknown (e.g. backspace prints a space).  Recompile with the system tic.
  (defvar my/eat-terminfo-directory
    (expand-file-name "eat-terminfo" user-emacs-directory))
  (defun my/eat-compile-terminfo ()
    "Compile eat.ti with the system tic when missing or out of date."
    (let ((source (expand-file-name "eat.ti"
                                    (file-name-directory (locate-library "eat"))))
          (target (expand-file-name "65/eat-truecolor" my/eat-terminfo-directory)))
      (when (and (file-exists-p source)
                 (executable-find "tic")
                 (file-newer-than-file-p source target))
        (make-directory my/eat-terminfo-directory t)
        (unless (zerop (call-process "tic" nil nil nil "-x" "-o"
                                     my/eat-terminfo-directory source))
          (message "eat: failed to compile terminfo from %s" source)))))
  :config
  (add-to-list 'display-buffer-alist
               '((derived-mode eat-mode) (display-buffer-in-side-window display-buffer-reuse-mode-window)
                 (side . bottom) (slot . 1) (window-height . 20) (mode . eat-mode) (preserve-size . (t . t))))
  (when (eq system-type 'darwin)
    (my/eat-compile-terminfo)
    (setq eat-term-terminfo-directory my/eat-terminfo-directory)))


