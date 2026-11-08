;; -*- lexical-binding: t; -*-


;;==========================================================
;; Emacs Base Configuration
;;==========================================================
(use-package emacs
  :preface
  (defconst my/help-buffer-list
    '(help-mode Man-mode Info-mode apropos-mode))

  (defun my/help-buffer-p (buf _action)
    (with-current-buffer buf
      (or
       (derived-mode-p my/help-buffer-list)
       (string-match "\\*Man.*?\\*" buf))))

  (defun my/prog-mode-hook ()
    ;; Setup better scrolling
    (setq-local scroll-conservatively           5
                scroll-margin                   5
                hscroll-margin                  10
                hscroll-step                    0.33
                hscroll-margin                  8
                scroll-preserve-screen-position t)
    ;; Enable line truncation
    (setq-local truncate-lines t)
    ;; Display line numbers
    (display-line-numbers-mode +1)
    ;; Enable auto pairing
    (electric-pair-mode +1))

  ;; Setup keybindings
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
  (defvar-keymap my/window-map
    :name "Window Map"
    :doc "Windowing Commands"
    :prefix t
    "t" #'tab-window-detach)
  (keymap-global-set "C-c w" my/window-map)

  :init
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

  (defun my/frame-monitor-dpi (&optional frame)
    (let* ((frame    (or frame (selected-frame)))
           (attrs    (frame-monitor-attributes))
           (mm-width (nth 1 (assq 'mm-size attrs)))
           (px-width (nth 3 (assq 'geometry attrs))))
      (/ px-width (/ mm-width 25.4))))

  (defun my/frame-monitor-text-height (&optional frame)
    (let* ((dpi (my/frame-monitor-dpi frame))
           (ref-dpi 109.0)
           (base 90.0)
           (h (round (* base (/ dpi ref-dpi)))))
      h
      ))

  (defun my/adjust-text-size-for-monitor (&optional frame)
      (custom-theme-set-faces 'user
                              `(default ((t . (:height ,(my/frame-monitor-text-height frame)))))))

  ;; Set font from list of prefered fonts.
  (if-let* ((font-list (list (font-spec :family "Iosevka Term"
                                        :weight 'bold
                                        :width 'expanded)))
            (found-font (seq-find #'find-font font-list)))
      (custom-theme-set-faces 'user
                              `(default ((t . (:font ,found-font)))))
    (warn "Failed to find any of the prefered fonts (%s)!" font-list))

  ;; Initialise font size
  (my/adjust-text-size-for-monitor)
  ;; Adjust every time frame moves
  (add-hook 'move-frame-functions #'my/adjust-text-size-for-monitor)


  ;; Always preserver scroll screen position
  (setq-default scroll-preserve-screen-position t)
  ;; No silly tab sizes
  (setq-default tab-width 4)
  ;; I don't like tabs
  (setq-default indent-tabs-mode nil)
  ;; Setup display buffer alist
  (setq display-buffer-alist
        `(((derived-mode . prog-mode) .
           ((display-buffer-same-window display-buffer-reuse-mode-window) .
            ((mode . prog-mode))))

          (my/help-buffer-p .
           ((display-buffer-reuse-mode-window display-buffer-in-side-window) .
                ((side . right) (slot . 0) (window-width . 75) (mode . ,my/help-buffer-list) (preserve-size . (t . t)))))

           ((derived-mode . compilation-mode) .
            ((display-buffer-reuse-mode-window display-buffer-in-side-window) .
             ((side . bottom) (slot . -1) (window-height . 12) (mode . compilation-mode) (preserve-size . (t . t)))))

           ("\\*xref\\*" .
            ((display-buffer-in-side-window) . ((side . right) (slot . 1))))
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
  (setq repeat-exit-timeout 1.5)
  ;; Set repeat mode exit get
  (setq repeat-exit-key "<RET>")

  ;; Prevent the use of UI dialog boxes
  (setq use-dialog-box nil)


  ;; Use preferred cursor type
  (setq-default cursor-type '(hbar . 4))
  ;; Stop cursor blinks from stopping
  (setq blink-cursor-blinks 0)
  ;; Have a longer time before the cursor starts blinking.
  (setopt blink-cursor-delay 2.0)
  ;; Cursor blinking switches between normal and box mode.
  (setq blink-cursor-alist `((,cursor-type . box)))
  ;; Stop cursor from displaying in non selected windows
  (setq-default cursor-in-non-selected-windows 'box)


  :config
  ;; Disable toolbar
  (tool-bar-mode -1)
  ;; Disable menu bar
  (menu-bar-mode -1)
  ;; Disable scroll bars
  (scroll-bar-mode -1)
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
  (setq mini-frame-show-parameters '((top . 0.1)
                                     (left . 0.5)
                                     (width . 0.33)
                                     (child-frame-border-width . 6))
        mini-frame-internal-border-color "#c42b6e"
        mini-frame-resize t)
  :config
  (mini-frame-mode 1))


(use-package transient
  :config
  (setq transient-display-buffer-action
        '((display-buffer-below-selected)
          . ((dedicated . t)))))


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
                 (rust-mode . rust-ts-mode)
                 (java-mode . java-ts-mode)
                 (python-mode . python-ts-mode)))
    (add-to-list 'major-mode-remap-alist map))
  (setopt c-ts-indent-offset 4)
  (setopt c-ts-mode-indent-style 'bsd)
  :hook (c++-ts-mode . my/treesit-c++-indent-override-rules))


(use-package find-file
  :demand t
  :bind
  ( :map my/goto-map
    ("o" . ff-find-other-file)))


(use-package flymake
  :demand t
  :bind
  ( :map my/code-map
    ("d" . flymake-show-buffer-diagnostics)
    ("D" . flymake-show-project-diagnostics)))


(use-package eglot
  :preface
  (defun my/eglot-managed-mode-hook ()
    ;; No inlay hints by default
    (eglot-inlay-hints-mode -1))
  :ensure nil
  :demand t
  :config
  ;; Setup language servers explicitly
  (setq eglot-server-programs '(((c-mode c++-mode c-ts-mode c++-ts-mode) .
                                 ("clangd"
                                  "--query-driver=/usr/bin/*"
                                  "--function-arg-placeholders=1"
                                  "--completion-style=detailed"
                                  "--header-insertion=iwyu"
                                  "--clang-tidy"))
                                ((java-mode java-ts-mode) .
                                 ("jdtls"))
                                ((python-mode python-ts-mode) .
                                 ("rass" "python"))))
  ;; Disable on type formatting
  (setq eglot-ignored-server-capabilities '(:documentOnTypeFormattingProvider))
  :hook
  (( c-mode c-ts-mode
     c++-mode c++-ts-mode
     rust-mode rust-ts-mode
     python-mode python-ts-mode
     java-mode java-ts-mode )
   . eglot-ensure)
  (eglot-managed-mode . my/eglot-managed-mode-hook)
  :bind
  ( :map my/code-map
    ("a" . eglot-code-actions)
    ("r" . eglot-rename))
  ( :map my/find-map
    ("i" . eglot-find-implementation)))


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
        avy-background t
        avy-case-fold-search nil
        avy-keys '(?a ?s ?d ?f ?g ?h ?j ?k ?l ?\;))
  (with-eval-after-load 'pulsar
    (add-to-list 'pulsar-pulse-functions 'avy-goto-word-1)
    (add-to-list 'pulsar-pulse-functions 'avy-goto-line)
    (add-to-list 'pulsar-pulse-functions 'avy-goto-char-timer))
  :bind
  ( :map my/goto-map
    ("g" . avy-goto-char-timer)
    ("l" . avy-goto-line)
    ("w" . avy-goto-word-1)
    ("c" . avy-goto-char)
    ("C" . avy-goto-char-in-line)))


(use-package ace-window
  :ensure t
  :preface
  (defun my/ace-move-window ()
    (interactive)
    (require 'ace-window)
    (aw-select "Ace - Move Window"
               #'aw-move-window))
  :config
  (setq aw-dispatch-always t
        aw-keys '(?a ?s ?d ?f ?j ?k ?l ?q ?w ?e ?r ?t ?y ?u ?i ?o ?p)
        aw-dispatch-alist nil)
  (custom-theme-set-faces 'user
                          '(aw-leading-char-face
                            ((t . ( :foreground "#FF0000"
                                    :height 4.0)))))
  :bind
  ( :map my/window-map
    ("w" . ace-select-window)
    ("m" . my/ace-move-window)
    ("M" . ace-swap-window)
    ("c" . ace-copy-window)
    ("k" . ace-delete-window)
    ("K" . ace-delete-other-windows)))


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


(use-package multiple-cursors
  :ensure t
  :demand t
  :bind
  ( :map my/mark-map
    ("n" . mc/mark-next-like-this)
    ("N" . mc/unmark-next-like-this)
    ("C-n" . mc/mark-next-word-like-this)
    ("M-n" . mc/mark-next-symbol-like-this)
    :repeat-map my/mark-map-repeat
    ("n" . mc/mark-next-like-this)
    ("N" . mc/unmark-next-like-this)
    ("C-n" . mc/mark-next-word-like-this)
    ("M-n" . mc/mark-next-symbol-like-this)))


;;==========================================================
;; Appearence
;;==========================================================
(use-package pulsar
  :ensure t
  :demand t
  :config
  (pulsar-global-mode +1)
  :hook (focus-in . pulsar-pulse-line))


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
        corfu-auto-delay 0.33
        corfu-auto-prefix 3
        corfu-auto-trigger ".>:")
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
               '((derived-mode . magit-status-mode)
                 . ((display-buffer-reuse-mode-window
                     display-buffer-in-direction)
                    . ((direction . left)
                       (window . main)
                       (window-width . 75)
                       (mode . magit-status-mode)
                       (preserve-size . (t . t))))))
  (magit-wip-mode +1))


(use-package magit-todos
  :ensure t
  :demand t
  :after magit
  :config
  (add-to-list 'display-buffer-alist
               '((derived-mode . magit-todos-list-mode) .
                 ((display-buffer-reuse-mode-window display-buffer-in-side-window) .
                  ((side . left) (slot . 1) (window-width . 75) (preserve_size . (t . t)) (mode . magit-todos-list-mode))))))


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
  (defun my/eat-mode-hook ()
    (setq-local scroll-conservatively 101))
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
               '((derived-mode . eat-mode) .
                 ((display-buffer-in-side-window display-buffer-reuse-mode-window) .
                  ((side . bottom) (slot . 1) (window-height . 10) (mode . eat-mode) (preserve-size . (t . t)) (dedicated . side)))))
  (when (eq system-type 'darwin)
    (my/eat-compile-terminfo)
    (setq eat-term-terminfo-directory my/eat-terminfo-directory))
  :hook
  ((eat-mode . my/eat-mode-hook)))

