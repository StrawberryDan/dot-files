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
    ;; Setup better scrolling
    (setq-local scroll-conservatively 5
                scroll-margin         5
                hscroll-margin        10
                hscroll-step          0.33
                hscroll-margin        8)
    ;; Enable line truncation
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
  ;; Allow package to upgrade built in packages too.
  (setq package-install-upgrade-built-in t)
  ;; Initialise package library
  (package-initialize)
  (unless package-archive-contents
    (package-refresh-contents))
  ;; No silly tab sizes
  (setq-default tab-width 4)
  ;; I don't like tabs
  (setq-default indent-tabs-mode nil)
  ;; Setup display buffer alist
  (setq display-buffer-alist
        `(((derived-mode prog-mode) .
           ((display-buffer-same-window display-buffer-reuse-mode-window) .
            ((mode . prog-mode))))

          (my/help-buffer-p .
           ((display-buffer-in-side-window display-buffer-reuse-mode-window) .
                ((side . right) (slot . 0) (window-width . 0.25) (mode . ,my/help-buffer-list) (preserve-size . (t . t)))))

           ((derived-mode compilation-mode) .
            ((display-buffer-in-side-window display-buffer-reuse-mode-window) .
             ((side . bottom) (slot . -1) (window-height . 20) (mode . compilation-mode) (preserve-size . (t . t)))))
           ))

  ;; Setup cache directories
  (let* ((cache-dir (expand-file-name "emacs/" (or (getenv "XDG_CACHE_HOME") "~/.cache")))
         (backup-dir (expand-file-name "backups/" cache-dir))
         (auto-save-dir (expand-file-name "auto-saves/" cache-dir))
         (lock-dir (expand-file-name "locks/" cache-dir)))
    (dolist (dir (list backup-dir auto-save-dir lock-dir))
      (make-directory dir t))
    (setq backup-directory-alist `(("." . ,backup-dir))
          auto-save-file-name-transforms `((".*" ,auto-save-dir t))
          lock-file-name-transforms      `((".*" ,lock-dir t))
          auto-save-list-file-prefix     (expand-file-name "sessions/.saves-" cache-dir)))

  ;; Configure compile mode
  (setq compilation-scroll-output 'first-error
        compilation-skip-threshold 2)

  ;; Set repeat mode timeout
  (setq repeat-exit-timeout 1.0)
  ;; Set repeat mode exit get
  (setq repeat-exit-key "<RET>")


  :config
  ;; Disable toolbar
  (tool-bar-mode -1)
  ;; Disable menu bar
  (menu-bar-mode -1)
  ;; Display line numbers globally
  (global-display-line-numbers-mode 1)
  ;; Enable auto pairing
  (electric-pair-mode 1)
  ;; Savehist mode makes vertico work better.
  (savehist-mode 1)
  ;; Enable default windmove bindings.
  (windmove-default-keybindings)
  ;; Enable repeat mode
  (repeat-mode +1)

  :hook
  (prog-mode . my/prog-mode-hook))


(use-package whitespace
  :ensure nil
  :demand t
  :init
  ;; Whitespace styling
  (setq whitespace-line-column 80
        whitespace-style '(face trailing tabs spaces lines-char newline space-mark tab-mark newline-mark))
  :hook
  ( (prog-mode . whitespace-mode) ))


(when (memq system-type '(darwin gnu gnu/linux gnu/freebsd))
  (use-package exec-path-from-shell
    :ensure t
    :demand t
    :config
    (exec-path-from-shell-initialize)))


(use-package tramp
  :ensure t
  :demand t)


;; Position miniframe in middle of screen
(use-package mini-frame
  :ensure t
  :init
  (setq mini-frame-show-parameters '((top . 0.6)
                                     (left . 0.5)
                                     (width . 0.6)
                                     (child-frame-border-width . 6))
        mini-frame-internal-border-color "#c42b6e"
        mini-frame-resize t)
  :config
  (mini-frame-mode 1))


;;==========================================================
;; Language Support
;;==========================================================
(use-package treesit
  :ensure nil
  :demand t
  :preface
  (defun my/treesit-c++-indent-override-rules ()
    (setopt treesit-simple-indent-override-rules
            '((cpp
               ((n-p-gp "declaration_list" "namespace_definition" nil) parent 0)
               ((n-p-gp "}" "declaration_list" "namespace_definition") parent 0)
               ((n-p-gp nil "declaration_list" "namespace_definition") grand-parent c-ts-indent-offset)

               ((n-p-gp "field_declaration_list" nil nil) parent 0)
               ((n-p-gp "access_specifier" "field_declaration_list" nil) parent 0)
               ((n-p-gp "}" "field_declaration_list" nil) parent 0)
               ((n-p-gp nil "field_declaration_list" nil) grand-parent c-ts-indent-offset)
               ((n-p-gp nil "field_declaration_list" nil) grand-parent 0) ))))
  :config
  ;; Setup support for cmake files
  (add-to-list 'auto-mode-alist
               '("CMakeLists\\.txt\\'" . cmake-ts-mode))

  (setopt treesit-language-source-alist
        '((cpp "https://github.com/tree-sitter/tree-sitter-cpp")
          (c   "https://github.com/tree-sitter/tree-sitter-c")))
  (dolist (map '((c-mode   . c-ts-mode)
                 (c++-mode . c++-ts-mode)
                 (rust-mode . rust-ts-mode)))
    (add-to-list 'major-mode-remap-alist map))
  (setopt c-ts-indent-offset 4)
  (setopt c-ts-mode-indent-style 'bsd)
  :hook (c++-ts-mode . my/treesit-c++-indent-override-rules))


(use-package eglot
  :ensure nil
  :demand t
  :hook
  ((c-mode c-ts-mode c++-mode c++-ts-mode rust-mode rust-ts-mode) . eglot-ensure)
  :config
  (setq eglot-server-programs '(((c-mode c++-mode c-ts-mode c++-ts-mode) .
                                 ("clangd"
                                  "--function-arg-placeholders=1"
                                  "--completion-style=detailed"
                                  "--header-insertion=iwyu"
                                  "--clang-tidy"))))
  (setq eglot-ignored-server-capabilities '(:documentOnTypeFormattingProvider))
  :bind
  ( :map my/code-map
    ("a" . eglot-code-actions)
    ("r" . eglot-rename)) )


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
  :config
  (setq avy-all-windows nil
        avy-all-windows-alt t
        avy-style 'at
        avy-background t)
  (with-eval-after-load 'pulsar
    (add-to-list 'pulsar-pulse-functions 'avy-goto-word-1)
    (add-to-list 'pulsar-pulse-functions 'avy-goto-line)
    (add-to-list 'pulsar-pulse-functions 'avy-goto-char-timer))
  :bind
  ( :map my/goto-map
    ("g" . avy-goto-char-timer)
    ("l" . avy-goto-line)
    ("w" . avy-goto-word-1)))


(use-package ace-window
  :ensure t
  :config
  (setq aw-dispatch-always t
        aw-keys '(?a ?s ?d ?f ?j ?k ?l ?l)
        aw-dispatch-alist '((?m aw-swap-window "Swap")
                            (?M aw-move-window "Move")
                            (?x aw-delete-window "Kill")
                            (?? aw-show-dispatch-help)))
  :bind
  (("C-c w" . ace-window)))


(use-package orderless
  :ensure t
  :demand t
  :config
  (setq completion-styles '(orderless)
        completion-category-defaults nil))


(use-package consult
  :ensure t
  :demand t
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
    ("g" . affe-grep)))


(use-package dirvish
  :ensure t
  :config
  (dirvish-override-dired-mode))


;;==========================================================
;; Appearence
;;==========================================================
(use-package pulsar
  :ensure t
  :demand t
  :config
  (pulsar-global-mode +1))


(use-package darcula-theme
  :ensure t
  :demand t
  :config
  (load-theme 'darcula t))


;;==========================================================
;; Competion
;;==========================================================
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
    (eval-expression-minibuffer-setup . my/corfu-prog-mode-hook) ))


;;==========================================================
;; Programming
;;==========================================================
(use-package ediff
  :ensure t
  :config
  (setq ediff-window-setup-function #'ediff-setup-windows-plain
        ediff-split-window-function #'split-window-horizontally)
  (custom-theme-set-faces 'user
                          '(ediff-even-diff-A ((t . (:background "#282323"))))
                          '(ediff-even-diff-B ((t . (:background "#232823"))))
                          '(ediff-even-diff-C ((t . (:background "#232328"))))
                          '(ediff-odd-diff-A  ((t . (:background "#1e1b1b"))))
                          '(ediff-odd-diff-B  ((t . (:background "#1b1e1b"))))
                          '(ediff-odd-diff-C  ((t . (:background "#1b1b1e"))))))


(use-package magit
  :ensure t
  :demand t
  :config
  (setq magit-display-buffer-function 'display-buffer)
  (setq magit-diff-refine-hunk 'all
        magit-diff-refine-ignore-whitespace t)
  (add-to-list 'display-buffer-alist
               '((derived-mode magit-status-mode) .
                 ((display-buffer-in-side-window display-buffer-reuse-mode-window) .
                  ((side . left) (slot . 0) (window-width . 0.25) (mode . magit-status-mode) (preserve-size . (t . t)) (dedicated . side)))))
  (magit-wip-mode +1))


(use-package magit-todos
  :ensure t
  :demand t
  :after magit
  :config
  (add-to-list 'display-buffer-alist
               '((derived-mode magit-todos-list-mode) .
                 ((display-buffer-in-side-window) .
                  ((side . left) (slot . 1) (window-width . 0.25) (preserve_size . (t . t)))))))


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
               '((derived-mode eat-mode) .
                 ((display-buffer-in-side-window display-buffer-reuse-mode-window) .
                  ((side . bottom) (slot . 1) (window-height . 20) (mode . eat-mode) (preserve-size . (t . t))))))
  (when (eq system-type 'darwin)
    (my/eat-compile-terminfo)
    (setq eat-term-terminfo-directory my/eat-terminfo-directory)))

