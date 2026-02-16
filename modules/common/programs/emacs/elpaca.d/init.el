;; -*- lexical-binding: t; -*-

(require 'cl-lib)
(require 'custom)

(defvar elpaca-installer-version 0.11)
(defvar elpaca-directory (expand-file-name "elpaca/" user-emacs-directory))
(defvar elpaca-builds-directory (expand-file-name "builds/" elpaca-directory))
(defvar elpaca-repos-directory (expand-file-name "repos/" elpaca-directory))
(defvar elpaca-order '(elpaca :repo "https://github.com/progfolio/elpaca.git"
                       :pre-build ("git" "remote" "set-url" "origin" "git@github.com:progfolio/elpaca.git")
                       :ref nil :depth 1 :inherit ignore
                       :files (:defaults "elpaca-test.el" (:exclude "extensions"))
                       :build (:not elpaca--activate-package)))

(setq elpaca-core-date '(20260215)) ;; Fix for Emacs 31 development builds

(defun +filter-messages (orig-fun format-string &rest args)
  "Wrapper for `message' to hide spammy deprecation warnings.
ORIG-FUN is the original `message' function.
FORMAT-STRING and ARGS are the arguments passed to `message'."
  (if (null format-string)
      (apply orig-fun nil nil)
    (let ((output (apply #'format-message format-string args)))
      (unless (or (string-match ".*when-let.*" output)
                  (string-match ".*if-let.*" output))
        (apply orig-fun format-string args)))))

(advice-add 'message :around #'+filter-messages)

(let* ((repo  (expand-file-name "elpaca/" elpaca-repos-directory))
       (build (expand-file-name "elpaca/" elpaca-builds-directory))
       (order (cdr elpaca-order))
       (default-directory repo))
  (add-to-list 'load-path (if (file-exists-p build) build repo))
  (unless (file-exists-p repo)
    (make-directory repo t)
    (when (<= emacs-major-version 28) (require 'subr-x))
    (condition-case-unless-debug err
        (if-let* ((buffer (pop-to-buffer-same-window "*elpaca-bootstrap*"))
                  ((zerop (apply #'call-process `("git" nil ,buffer t "clone"
                                                  ,@(when-let* ((depth (plist-get order :depth)))
                                                      (list (format "--depth=%d" depth) "--no-single-branch"))
                                                  ,(plist-get order :repo) ,repo))))
                  ((zerop (call-process "git" nil buffer t "checkout"
                                        (or (plist-get order :ref) "--"))))
                  (emacs (concat invocation-directory invocation-name))
                  ((zerop (call-process emacs nil buffer nil "-Q" "-L" "." "--batch"
                                        "--eval" "(byte-recompile-directory \".\" 0 'force)")))
                  ((require 'elpaca))
                  ((elpaca-generate-autoloads "elpaca" repo)))
            (progn (message "%s" (buffer-string)) (kill-buffer buffer))
          (error "%s" (with-current-buffer buffer (buffer-string))))
      ((error) (warn "%s" err) (delete-directory repo 'recursive))))
  (unless (require 'elpaca-autoloads nil t)
    (require 'elpaca)
    (elpaca-generate-autoloads "elpaca" repo)
    (let ((load-source-file-function nil)) (load "./elpaca-autoloads"))))
(add-hook 'after-init-hook #'elpaca-process-queues)
(elpaca `(,@elpaca-order))

;; Install use-package support
(elpaca elpaca-use-package
        (require 'elpaca-use-package)
        (elpaca-use-package-mode)
        (setq use-package-always-ensure t))

(defmacro use-feature (name &rest args)
  "`use-package' for packages which do not require installation.
  See `use-package' for NAME and ARGS."
  (declare (indent defun))
  `(use-package ,name
     :ensure nil
     ,@args))

;; Wait for interactive setup to complete
(elpaca-wait)

(use-package dash)
(use-package s)

(setq initial-buffer-choice t)

(if debug-on-error
    (setq use-package-verbose t
          use-package-expand-minimally nil
          use-package-compute-statistics t)
  (setq use-package-verbose nil
        use-package-expand-minimally t))

(let ((default-directory "~/.emacs.d/lisp/"))
  (when (file-exists-p default-directory)
    (normal-top-level-add-to-load-path '("."))
    (normal-top-level-add-subdirs-to-load-path)))

;;(load (expand-file-name "~/.config/config-nix.el"))

(setq split-width-threshold 200
      split-height-threshold 40)

(defun +min-margin-left (&optional window)
  (let ((current (-> (window-margins window) car (or 0))))
    (if (and (> current 0)
             (not (display-graphic-p (window-frame window))))
        1 0)))

(defun split-window-prefer-horizontal (&optional window)
  "Modified version of `split-window-sensibly' that splits horizontally
   by default when allowed."
  (interactive)
  (let ((window (or window (selected-window))))
    (if (< (frame-width (window-frame window))
           split-width-threshold)
        ;; use the default behavior if the frame isn't wide enough to
        ;; support two full-size horizontal windows
        (split-window-sensibly window)
      (set-window-margins window (+min-margin-left window) 0)
      (or (and (window-splittable-p window t)
               ;; Split window horizontally.
               (with-selected-window window
                 (split-window-right)))
          (and (window-splittable-p window)
               ;; Split window vertically.
               (with-selected-window window
                 (split-window-below)))
          (and
           ;; If WINDOW is the only usable window on its frame (it is
           ;; the only one or, not being the only one, all the other
           ;; ones are dedicated) and is not the minibuffer window, try
           ;; to split it vertically disregarding the value of
           ;; `split-height-threshold'.
           (let ((frame (window-frame window)))
             (or
              (eq window (frame-root-window frame))
              (catch 'done
                (walk-window-tree (lambda (w)
                                    (unless (or (eq w window)
                                                (window-dedicated-p w))
                                      (throw 'done nil)))
                                  frame nil 'nomini)
                t)))
           (not (window-minibuffer-p window))
           (let ((split-height-threshold 0))
             (when (window-splittable-p window)
               (with-selected-window window
                 (split-window-below)))))))))

(setq split-window-preferred-function 'split-window-prefer-horizontal)

(defun --window-system-available () (< 0 (length (getenv "DISPLAY"))))
(defun --wayland-available () (< 0 (length (getenv "WAYLAND_DISPLAY"))))
(defun graphical? () (cl-some #'display-graphic-p (frame-list)))
(defun mac? () (eql system-type 'darwin))
(defun asahi? () (s-matches? "aarch64.*linux" system-configuration))
(defun gui-mac-std? () (eql window-system 'ns))
(defun gui-emacs-mac? () (eql window-system 'mac))
(defun gui-mac? () (or (gui-mac-std?) (gui-emacs-mac?)))

(when (mac?)
  (setq mac-command-modifier 'meta
        mac-right-command-modifier 'left
        mac-option-modifier 'super
        mac-right-option-modifier 'left))

(defun --get-font-spec (&optional variable? modeline?)
  (if nil ;; modeline?
      nil
    (apply 'font-spec
           :family (if variable? "Inter" "JetBrainsMono Nerd Font")
           :size (+ 12
                    (if variable? 0 0)
                    (if modeline? 0 0)
                    (if (mac?) 1 0))
           :weight (if variable?
                       'medium
                     (if (mac?)
                         (if modeline? 'bold 'semibold)
                       (if modeline? 'extrabold 'bold)))
           nil)))

(progn
  (set-face-font 'default (--get-font-spec))
  (set-face-font 'variable-pitch (--get-font-spec t nil))
  (dolist (ml '(mode-line mode-line-active mode-line-inactive))
    (set-face-font ml (--get-font-spec nil t)))
  (copy-face 'default 'fixed-pitch))

;; transparency for terminal
;; (set-face-background 'default "#00000000" frame)
;; (set-face-background 'hl-line "#00000000" frame)

(setq user-full-name "Jeff Workman"
      user-mail-address "jeff.workman@gmail.com"
      display-line-numbers-type t
      confirm-kill-processes t
      large-file-warning-threshold (* 10 1000 1000))

;; Make sure this gets set in terminal or server processes
(setq interprogram-cut-function 'gui-select-text
      interprogram-paste-function 'gui-selection-value)

(defun +forward-paragraph-center ()
  (interactive)
  (forward-paragraph)
  (recenter nil t))

(defun +backward-paragraph-center ()
  (interactive)
  (backward-paragraph)
  (recenter nil t))

(use-package general
  :ensure (:wait t)
  :demand t
  :config
  (general-override-mode)
  (general-auto-unbind-keys)

  (general-define-key
   :keymaps 'override
   :states '(insert normal hybrid motion visual operator emacs)
   :prefix-map '+prefix-map
   :prefix-command '+prefix-map
   :prefix "SPC"
   :global-prefix "S-SPC")

  (general-create-definer global-definer
    :wk-full-keys nil
    :keymaps '+prefix-map)

  (general-create-definer global-override
    :states '(insert normal hybrid motion visual operator emacs)
    :keymaps 'override)

  (defun +evil-jump-backward-center ()
    (interactive)
    (evil-jump-backward)
    (recenter nil t))

  (global-override
   "C-e" 'evil-end-of-line
   "M-." 'evil-goto-definition
   "M-," '+evil-jump-backward-center
   "C-f" 'forward-sexp
   "C-b" 'backward-sexp
   "C-<up>" '+backward-paragraph-center
   "C-<down>" '+forward-paragraph-center
   "C-M-w" 'split-window-prefer-horizontal)

  (general-create-definer general-def-evil-all
    :states '(insert normal hybrid motion visual operator emacs))

  (general-create-definer global-leader
    :keymaps 'override
    :states '(insert normal hybrid motion visual operator)
    :prefix "SPC m"
    :non-normal-prefix "S-SPC m"
    "" '( :ignore t
          :which-key
          (lambda (arg)
            (cons (cadr (split-string (car arg) " "))
                  (replace-regexp-in-string "-mode$" "" (symbol-name major-mode))))))

  (global-definer
    "/"   'occur
    "!"   'shell-command
    ":"   'eval-expression
    ";"   'execute-extended-command
    "."   'projectile-find-file
    ","   'switch-to-buffer
    "h"   (general-simulate-key "C-h" :which-key "help")
    "z"   '((lambda (local) (interactive "p")
              (unless repeat-mode (repeat-mode))
              (let ((local current-prefix-arg)
                    (current-prefix-arg nil))
                (call-interactively (if local #'text-scale-adjust #'global-text-scale-adjust))))
            :which-key "zoom"))

  (defmacro +general-global-menu! (name prefix-key &rest body)
    "Create a definer named +general-global-NAME wrapping global-definer.
  Create prefix map: +general-global-NAME-map. Prefix bindings in BODY with PREFIX-KEY."
    (declare (indent 2))
    (let* ((n (concat "+general-global-" name))
           (prefix-map (intern (concat n "-map"))))
      `(progn
         (general-create-definer ,(intern n)
           :wrapping global-definer
           :prefix-map (quote ,prefix-map)
           :prefix ,prefix-key
           :wk-full-keys nil
           "" '(:ignore t :which-key ,name))
         (,(intern n) ,@body))))

  (+general-global-menu! "application" "a"
    "p" '(:ignore t "elpaca")
    "pb" 'elpaca-browse
    "pr"  '((lambda () (interactive)
              (let ((current-prefix-arg (not current-prefix-arg))
                    (this-command 'elpaca-rebuild))
                (call-interactively #'elpaca-rebuild)))
            :which-key "rebuild")
    "pm" 'elpaca-manager
    "pl" 'elpaca-log
    "pi" 'elpaca-info
    "pI" '((lambda () (interactive) (info "Elpaca"))
           :which-key "elpaca-info")
    "ps" 'elpaca-status
    "pt" 'elpaca-try
    "pv" 'elpaca-visit)

  (+general-global-menu! "buffer" "b"
    "d"  'kill-current-buffer
    "o" '((lambda () (interactive) (switch-to-buffer nil))
          :which-key "other-buffer")
    "p"  'previous-buffer
    "r"  'rename-buffer
    "R"  'revert-buffer
    "M" '((lambda () (interactive) (switch-to-buffer "*Messages*"))
          :which-key "messages-buffer")
    "n"  'next-buffer
    "s"  'scratch-buffer
    "TAB" '((lambda () (interactive) (switch-to-buffer nil))
            :which-key "other-buffer"))

  (+general-global-menu! "eval" "e"
    "b" 'eval-buffer
    "d" 'eval-defun
    "e" 'eval-expression
    "p" 'pp-eval-last-sexp
    "s" 'eval-last-sexp)

  (+general-global-menu! "file" "f"
    "d"   '((lambda (&optional arg)
              (interactive "P")
              (let ((buffer (when arg (current-buffer))))
                (diff-buffer-with-file buffer))) :which-key "diff-with-file")
    "e"   '(:ignore t :which-key "edit")
    "ed"  '((lambda () (interactive) (find-file-existing literate-file) (widen))
            :which-key "dotfile")
    "f"   'find-file
    "l"   '((lambda (&optional arg)
              (interactive "P")
              (call-interactively (if arg #'find-library-other-window #'find-library)))
            :which-key "+find-library")
    "p"   'find-function-at-point
    "P"   'find-function
    "R"   'rename-file-and-buffer
    "s"   'save-buffer
    "v"   'find-variable-at-point
    "V"   'find-variable)

  (+general-global-menu! "frame" "F"
    "D" 'delete-other-frames
    "F" 'select-frame-by-name
    "O" 'other-frame-prefix
    "c" '(:ingore t :which-key "color")
    "cb" 'set-background-color
    "cc" 'set-cursor-color
    "cf" 'set-foreground-color
    "f" 'set-frame-font
    "m" 'make-frame-on-monitor
    "n" 'next-window-any-frame
    "o" 'other-frame
    "p" 'previous-window-any-frame
    "r" 'set-frame-name)

  (+general-global-menu! "git/version-control" "g")

  (+general-global-menu! "link" "l")

  (+general-global-menu! "narrow" "n"
    "d" 'narrow-to-defun
    "p" 'narrow-to-page
    "r" 'narrow-to-region
    "w" 'widen)

  (+general-global-menu! "project" "p"
    "b" '(:ignore t :which-key "buffer"))

  (+general-global-menu! "quit" "q"
    "q" 'save-buffers-kill-emacs
    "r" 'restart-emacs
    "Q" 'kill-emacs)

  (+general-global-menu! "spelling" "s")

  (+general-global-menu! "text" "x"
    "i" 'insert-char
    "I" (general-simulate-key "C-x 8" :which-key "iso"))

  (+general-global-menu! "tab" "t")

  (+general-global-menu! "toggle" "T"
    "d" '(:ignore t :which-key "debug")
    "de" 'toggle-debug-on-error
    "dq" 'toggle-debug-on-quit
    "s" '(:ignore t :which-key "spelling"))

  (+general-global-menu! "window" "w"
    "?" 'split-window-vertically
    "=" 'balance-windows
    "/" 'split-window-horizontally
    "O" 'delete-other-windows
    "X" '((lambda () (interactive) (call-interactively #'other-window) (kill-buffer-and-window))
          :which-key "kill-other-buffer-and-window")
    "d" 'delete-window
    "h" 'windmove-left
    "j" 'windmove-down
    "k" 'windmove-up
    "l" 'windmove-right
    "o" 'other-window
    "t" 'window-toggle-side-windows
    "."  '(:ingore :which-key "resize")
    ".h" '((lambda () (interactive)
             (call-interactively (if (window-prev-sibling) #'enlarge-window-horizontally
                                   #'shrink-window-horizontally)))
           :which-key "divider left")
    ".l" '((lambda () (interactive)
             (call-interactively (if (window-next-sibling) #'enlarge-window-horizontally
                                   #'shrink-window-horizontally)))
           :which-key "divider right")
    ".j" '((lambda () (interactive)
             (call-interactively (if (window-next-sibling) #'enlarge-window #'shrink-window)))
           :which-key "divider up")
    ".k" '((lambda () (interactive)
             (call-interactively (if (window-prev-sibling) #'enlarge-window #'shrink-window)))
           :which-key "divider down")
    "x" 'kill-buffer-and-window)

  (general-create-definer completion-def
    :prefix "C-x"))

(use-package ace-window
  :after (general)
  :general
  (global-override
   "C-o" 'other-window
   "C-M-o" 'ace-window))

(defmacro +pushnew! (place &rest items)
  (let ((i (make-symbol "item")))
    `(dolist (,i ',items)
       (unless (member ,i ,place)
         (push ,i ,place)))))
;; (setq asd '(1))
;; (+pushnew! asd 2 3 4)

(use-package copilot
  :after (corfu)
  :defer 2
  :commands copilot-mode
  :hook ((prog-mode . copilot-mode)
         (conf-mode . copilot-mode))
  :config
  (unless (file-exists-p (copilot-server-executable))
    (copilot-install-server))

  (setq copilot-idle-delay 0
        copilot-max-char 100000
        copilot-indent-offset-warning-disable t)

  (defun +copilot-complete-or-next ()
    (interactive)
    (if (copilot--overlay-visible)
        (copilot-next-completion)
      (copilot-complete)))

  (defun +copilot-show-or-accept ()
    (interactive)
    (if (copilot--overlay-visible)
        (copilot-accept-completion)
      (copilot-complete)))

  (+pushnew! copilot-clear-overlay-ignore-commands
             '+copilot-show-or-accept
             '+copilot-complete-or-next
             'corfu-next
             'corfu-previous
             'corfu-scroll-down
             'corfu-scroll-up
             'corfu-first
             'corfu-last
             'corfu-insert-separator
             'corfu-complete)

  (+pushnew! warning-suppress-types '(copilot copilot-exceeds-max-char))

  :general
  (general-def-evil-all
   :keymaps 'copilot-mode-map
   "TAB" '+copilot-show-or-accept
   "M-TAB" '+copilot-complete-or-next
   "S-TAB" 'copilot-accept-completion-by-line
   "C-TAB" 'copilot-accept-completion-by-word)

  (general-def-evil-all
   :keymaps 'copilot-completion-map
   "TAB" 'copilot-accept-completion)

  ;; unset conflicting bindings
  (general-def-evil-all
   :keymaps 'corfu-map
   "TAB" nil
   "S-TAB" nil))

(use-package diff-hl)

(use-package disable-mouse
  :defer 2
  :if (asahi?)
  :config
  (global-disable-mouse-mode +1)
  (mapc #'disable-mouse-in-keymap
        (list evil-motion-state-map
              evil-normal-state-map
              evil-visual-state-map
              evil-insert-state-map)))

(use-package editorconfig)

(use-package envrc
  :hook (prog-mode . envrc-mode)
  :config
  (setq envrc-show-setup-in-mode-line nil))

(use-feature eglot
  :hook (rust-ts-mode . eglot-ensure)
  :config
  (add-hook 'eglot-managed-mode-hook #'eglot-inlay-hints-mode)
  (defun +eglot--completion-field ()
    "Return the current completion field string for sorting, or nil."
    (when (bound-and-true-p completion-in-region--data)
      (pcase-let ((`(,beg ,end ,_table ,_pred . ,_) completion-in-region--data))
        (buffer-substring-no-properties beg end))))

  (defun +eglot--candidate-name (candidate)
    "Extract a stable name from CANDIDATE for sorting."
    (let* ((item (get-text-property 0 'eglot--lsp-item candidate))
           (label (or (plist-get item :label) candidate))
           (raw (if (stringp label) label (format "%s" label))))
      (car (split-string raw "[[:space:](]" t))))

  (defun +eglot--candidate-sort-text (candidate)
    "Return LSP sortText for CANDIDATE when available."
    (let ((item (get-text-property 0 'eglot--lsp-item candidate)))
      (plist-get item :sortText)))

  (defun +eglot--corfu-sort (candidates)
    "Sort CANDIDATES to prefer exact name matches, then LSP sortText."
    (let* ((field (or (+eglot--completion-field) ""))
           (field (replace-regexp-in-string "\\`[.:]+" "" field))
           (field (if (stringp field) field "")))
      (cl-stable-sort (copy-sequence candidates)
                      (lambda (a b)
                        (let* ((name-a (+eglot--candidate-name a))
                               (name-b (+eglot--candidate-name b))
                               (exact-a (and name-a (string= name-a field)))
                               (exact-b (and name-b (string= name-b field))))
                          (cond
                           ((and exact-a (not exact-b)) t)
                           ((and exact-b (not exact-a)) nil)
                           ((and name-a name-b)
                            (let* ((sort-a (+eglot--candidate-sort-text a))
                                   (sort-b (+eglot--candidate-sort-text b)))
                              (cond
                               ((and sort-a sort-b (not (string= sort-a sort-b)))
                                (string-lessp sort-a sort-b))
                               ((and sort-a (null sort-b)) t)
                               ((and sort-b (null sort-a)) nil)
                               (t (string-lessp name-a name-b)))))
                           (t (string-lessp (or name-a "") (or name-b "")))))))))

  (defun +eglot--corfu-sort-setup-h ()
    (when (boundp 'corfu-sort-override-function)
      (setq-local corfu-sort-override-function #'+eglot--corfu-sort)))

  (add-hook 'eglot-managed-mode-hook #'+eglot--corfu-sort-setup-h)
  :custom
  (eglot-workspace-configuration
   '((:rust-analyzer . (:completion (:limit 5000)
                        :inlayHints (:typeHints (:enable t)
                                     :parameterHints (:enable t)
                                     :chainingHints (:enable t)))))))

(use-package evil
  :demand t
  :preface (setq evil-want-keybinding nil)
  :custom
  (evil-ex-visual-char-range t "limit text replacement in visual selections")
  (evil-symbol-word-search t "search by symbol with * and #.")
  (evil-shift-width 2 "Same behavior for vim's '<' and '>' commands")
  (evil-complete-all-buffers nil)
  (evil-want-integration t)
  (evil-want-C-i-jump t)
  (evil-search-module 'evil-search "use vim-like search instead of 'isearch")
  (evil-undo-system 'undo-redo)
  :hook
  (lisp-interaction-mode . (lambda () (setq-local evil-lookup-func #'+evil-lookup-elisp-symbol)))
  (emacs-lisp-mode . (lambda () (setq-local evil-lookup-func #'+evil-lookup-elisp-symbol)))
  :config
  (defun +evil-lookup-elisp-symbol ()
    "Lookup elisp symbol at point."
    (if-let* ((symbol (thing-at-point 'symbol)))
        (describe-symbol (intern symbol))
      (user-error "No symbol at point")))
  (+general-global-window
    "H" 'evil-window-move-far-left
    "J" 'evil-window-move-very-bottom
    "K" 'evil-window-move-very-top
    "L" 'evil-window-move-far-right)
  (+general-global-menu! "quit" "q"
    ":" 'evil-command-window-ex
    "/" 'evil-command-window-search-forward
    "?" 'evil-command-window-search-backward)
  ;;I want Emacs regular mouse click behavior
  (define-key evil-motion-state-map [down-mouse-1] nil)
  (evil-mode))

(use-package evil-anzu
  :after (evil anzu))

(use-package evil-collection
  :ensure ( :depth 1
                   :remotes ("origin"
                             ("fork" :repo "progfolio/evil-collection")))
  :after (evil)
  :config
  (setq evil-collection-mode-list (remq 'elpaca evil-collection-mode-list))
  (evil-collection-init)
  :init (setq evil-collection-setup-minibuffer t)
  :custom
  (evil-collection-elpaca-want-g-filters nil)
  (evil-collection-ement-want-auto-retro t))

(use-package anzu
  :defer 10
  :config (global-anzu-mode))

(use-feature simple
  :general
  (+general-global-toggle
    "f" 'auto-fill-mode)
  :custom
  (eval-expression-debug-on-error nil)
  (fill-column 100 "Wrap at 100 columns."))

(use-feature autorevert
  :defer 2
  :custom
  (auto-revert-interval 0.01 "Instantaneously revert")
  :config
  (global-auto-revert-mode t))

(use-package auto-tangle-mode
  :ensure (auto-tangle-mode
           :host github
           :repo "progfolio/auto-tangle-mode.el"
           :local-repo "auto-tangle-mode")
  :commands (auto-tangle-mode))

(use-feature bookmark
  :custom (bookmark-fontify nil)
  :general
  (+general-global-bookmark
   "j" 'bookmark-jump
   "s" 'bookmark-set
   "r" 'bookmark-rename))

;; Buttercup is a behavior-driven development framework for testing Emacs Lisp code.
(use-package buttercup
  :commands (buttercup-run-at-point))

(use-feature calc
  :general
  (+general-global-menu! "calc" "c"
    "c" 'quick-calc
    "C" 'calc
    "f" 'full-calc))

;; Completion At Point Extensions
(use-package cape
  :commands (cape-file)
  :init
  (add-hook 'prog-mode-hook (lambda () (add-to-list 'completion-at-point-functions #'cape-dabbrev t)))
  (add-hook 'prog-mode-hook (lambda () (add-to-list 'completion-at-point-functions #'cape-file t)))
  (add-hook 'text-mode-hook (lambda () (add-to-list 'completion-at-point-functions #'cape-dabbrev t)))
  :general
  (general-define-key
   :keymaps '(insert)
   "C-x C-f" #'cape-file
   "C-x C-l" #'cape-line))

(use-package catppuccin-theme
  :init
  (setq catppuccin-flavor 'frappe)
  :config
  (load-theme 'catppuccin t))

(use-package clojure-mode)

(use-package cider
  :after (clojure-mode)
  :hook (clojure-mode . cider-mode)
  :config
  (setq cider-repl-use-pretty-printing t)
  (setq cider-repl-display-in-current-window t))

(use-feature compile
  :commands (compile recompile)
  :custom (compilation-scroll-output 'first-error)
  :config
  (defun +compilation-colorize ()
    "Colorize from `compilation-filter-start' to `point'."
    (require 'ansi-color)
    (let ((inhibit-read-only t))
      (ansi-color-apply-on-region (point-min) (point-max))))
  (add-hook 'compilation-filter-hook #'+compilation-colorize))

;; Consulting completing-read
(use-package consult
  :after (general)
  :demand t
  :custom (consult-buffer-list-function #'consult--frame-buffer-list)
  :config
  ;;Credit to @alphapapa
  (defun +consult-info-emacs ()
    "Search through Emacs info pages."
    (interactive)
    (consult-info "emacs" "efaq" "elisp" "cl"))
  '(consult-customize
    consult-recent-file
    consult--source-recent-file
    consult--source-buffer
    consult--source-bookmark
    consult-buffer
    :preview-key nil)

  (defvar +consult-source-shell
    (list :name "$"
          :category 'command
          :narrow ?s ;; for "shell"
          :hidden t
          :action (lambda (command) (start-process-shell-command command nil command))
          :new (lambda (command) (start-process-shell-command command nil command))
          :items (lambda () (delete-dups (mapcar #'string-trim shell-command-history)))))
  (add-to-list 'consult-buffer-sources '+consult-source-shell 'append)

  (global-leader
    :major-modes '(org-mode)
    :keymaps     '(org-mode-map)
    "/" 'consult-org-heading)
  (global-definer "/" 'consult-line)
  (+general-global-buffer "b" 'consult-buffer)
  (+general-global-project "a" 'consult-grep)
  (+general-global-file
    ;;"f" 'consult-file
    "r" 'consult-recent-file))

;; Completion Overlay Region FUnction
;; "Corfu enhances completion at point with a small completion popup."
(use-package corfu
  :ensure (corfu :host github :repo "minad/corfu" :files (:defaults "extensions/*"))
  :defer 1
  :custom
  (corfu-auto t)
  (corfu-auto-delay 0.2)
  (corfu-auto-prefix 2)
  (corfu-cycle t)
  (corfu-separator ?\s)
  (corfu-min-width 70)
  (corfu-max-width 110)
  (corfu-bar-width 0.2)
  (corfu-left-margin-width 0.5)
  (corfu-right-margin-width 0.5)
  (corfu-preview-current t)
  (corfu-preselect 'prompt)
  (corfu-popupinfo-delay '(1.0 . 0.5))
  (corfu-popupinfo-resize nil)
  (corfu-popupinfo-hide t)
  (corfu-popupinfo-min-height 4)
  (corfu-popupinfo-max-height 15)
  (corfu-popupinfo-min-width 30)
  (corfu-popupinfo-max-width 80)
  :config
  (global-corfu-mode)
  (corfu-history-mode)
  (corfu-popupinfo-mode)
  (add-hook 'evil-insert-state-exit-hook #'corfu-quit)
  (with-eval-after-load 'evil
    (setq evil-complete-next-func (lambda (_) (completion-at-point))))
  (general-def-evil-all
   :keymaps 'corfu-mode-map
   "C-." 'complete-symbol
   "C-x C-o" 'complete-symbol)
  (general-def-evil-all
   :keymaps 'corfu-map
   "RET" 'corfu-complete))

(use-package nerd-icons-corfu
  :after (corfu)
  :config
  (add-to-list 'corfu-margin-formatters #'nerd-icons-corfu-formatter))

(use-feature cus-edit
  :custom
  (custom-file null-device "Don't store customizations"))

(use-feature dictionary
  :defer t
  :general
  (global-definer "W" 'dictionary-lookup-definition)
  (+general-global-application "D" 'dictionary-search)
  (+general-global-text "d" 'dictionary-search)
  :custom
  (dictionary-create-buttons nil)
  (dicitonary-use-single-buffer t))

(use-feature dired
  :commands (dired)
  :custom
  (dired-mouse-drag-files t)
  (dired-listing-switches "-alh" "Human friendly file sizes.")
  (dired-kill-when-opening-new-dired-buffer t)
  (dired-omit-files "\\(?:\\.+[^z-a]*\\)")
  :hook (dired-mode-hook . dired-omit-mode)
  :general
  (+general-global-application "d" 'dired))

;; doct is a function that provides an alternative, declarative syntax for describing Org capture templates.
(use-package doct
  :ensure (doct :branch "development" :protocol ssh :depth nil :autoloads nil)
  :commands (doct))

(use-package doom-modeline
  :defer 2
  :config
  (set-face-font 'doom-modeline (--get-font-spec nil t))

  (doom-modeline-mode)
  :custom
  (doom-modeline-height 29)
  (doom-modeline-time-analogue-clock nil)
  (doom-modeline-time-icon nil)
  (doom-modeline-unicode-fallback nil)
  (doom-modeline-buffer-encoding 'nondefault)
  (display-time-load-average nil)
  (doom-modeline-icon t "Show icons in the modeline"))

(use-package doom-themes :defer t)

(use-feature edebug
  :config
  (global-leader
    :major-modes '(emacs-lisp-mode lisp-interaction-mode t)
    :keymaps     '(emacs-lisp-mode-map lisp-interaction-mode-map)
    "d" '(:ignore t :which-key "debug")
    "dA" 'edebug-all-defs
    "db" '(:ignore t :which-key "breakpoint")
    "dbU"  'edebug-unset-breakpoints
    "dbc"  'edebug-set-conditional-breakpoint
    "dbg"  'edebug-set-global-break-condition
    "dbn"  'edebug-next-breakpoint
    "dbs"  'edebug-set-breakpoint
    "dbt"  'edebug-toggle-disable-breakpoint
    "dbu"  'edebug-unset-breakpoint
    "dw" 'edebug-where))

(use-feature ediff
  :defer t
  :custom
  (ediff-window-setup-function #'ediff-setup-windows-plain)
  (ediff-split-window-function #'split-window-horizontally)
  :config
  (add-hook 'ediff-quit-hook #'winner-undo))

(use-feature elisp-mode
  :init
  (setq lisp-indent-offset nil)
  :config
  (global-leader
    :major-modes '(emacs-lisp-mode lisp-interaction-mode t)
    :keymaps     '(emacs-lisp-mode-map lisp-interaction-mode-map)
    "e"  '(:ignore t :which-key "eval")
    "eb" 'eval-buffer
    "ed" 'eval-defun
    "ee" 'eval-expression
    "ep" 'pp-eval-last-sexp
    "es" 'eval-last-sexp
    "i"  'elisp-index-search))

;; These settings defined in C code, so we use the ~emacs~ pseudo-package to set them.
(use-feature emacs
  :demand t
  :custom
  (scroll-conservatively 101)
  (enable-recursive-minibuffers t "Allow minibuffer commands in minibuffer")
  (frame-title-format '(buffer-file-name "%f" ("%b"))
                      "Make frame title current file's name.")
  (find-library-include-other-files nil)
  (indent-tabs-mode nil "Use spaces, not tabs")
  (inhibit-startup-screen t)
  (history-delete-duplicates t "Don't clutter history")
  (pgtk-use-im-context-on-new-connection nil "Prevent GTK from stealing Shift + Space")
  (sentence-end-double-space nil "Double space sentence demarcation breaks sentence navigation in Evil")
  (tab-stop-list (number-sequence 2 120 2))
  (tab-width 2 "Shorter tab widths")
  (completion-styles '(flex basic partial-completion emacs22))
  (report-emacs-bug-no-explanations t)
  (report-emacs-bug-no-confirmation t))

;; MPV integration
(use-package emp
  :ensure (emp :host github :repo "progfolio/emp")
  :config
  :general
  (+general-global-application
    "v"  '(:ignore t :which-key "video/audio")
    "vQ" 'emp-kill
    "vf" '(:ignore t :which-key "frame")
    "vfb" 'emp-frame-back-step
    "vff" 'emp-frame-step
    "vi" 'emp-insert-playback-time
    "vo" 'emp-open
    "vO" 'emp-cycle-osd
    "v SPC" 'emp-pause
    "vs" 'emp-seek
    "vr" 'emp-revert-seek
    "vt" 'emp-seek-absolute
    "vv" 'emp-set-context
    "vS" 'emp-speed-set))

(use-feature files
  ;;:hook
  ;;(before-save . delete-trailing-whitespace)
  :config
  ;; source: http://steve.yegge.googlepages.com/my-dot-emacs-file
  (defun rename-file-and-buffer (new-name)
    "Renames both current buffer and file it's visiting to NEW-NAME."
    (interactive "sNew name: ")
    (let ((name (buffer-name))
          (filename (buffer-file-name)))
      (if (not filename)
          (message "Buffer '%s' is not visiting a file." name)
        (if (get-buffer new-name)
            (message "A buffer named '%s' already exists." new-name)
          (progn
            (rename-file filename new-name 1)
            (rename-buffer new-name)
            (set-visited-file-name new-name)
            (set-buffer-modified-p nil))))))
  :custom
  (trusted-content (list "~/.emacs.d/elpaca/"))
  (require-final-newline t "Automatically add newline at end of file")
  (backup-by-copying t)
  (backup-directory-alist `((".*" . ,(expand-file-name
                                      (concat user-emacs-directory "backups"))))
                          "Keep backups in their own directory")
  (auto-save-file-name-transforms `((".*" ,(concat user-emacs-directory "autosaves/") t)))
  (delete-old-versions t)
  (kept-new-versions 10)
  (kept-old-versions 5)
  (version-control t)
  (safe-local-variable-values
   '()
   "Store safe local variables here instead of in emacs-custom.el"))

(use-feature display-fill-column-indicator
  :custom
  (display-fill-column-indicator-character
   (plist-get '( triple-pipe  ?┆
                 double-pipe  ?╎
                 double-bar   ?║
                 solid-block  ?█
                 empty-bullet ?◦)
              'triple-pipe))
  :general
  (+general-global-toggle
    "F" '(:ignore t :which-key "fill-column-indicator")
    "FF" 'display-fill-column-indicator-mode
    "FG" 'global-display-fill-column-indicator-mode))

(use-package flycheck
  :commands (flycheck-mode)
  :custom (flycheck-emacs-lisp-load-path 'inherit "necessary with alternatives to package.el"))

(use-feature flymake
  :general
  (global-leader
    :major-modes '(emacs-lisp-mode lisp-interaction-mode t)
    :keymaps     '(emacs-lisp-mode-map lisp-interaction-mode-map)
    "f" '(:ignore t :which-key "flymake")
    "ff" '((lambda () (interactive) (flymake-mode 'toggle)) :which-key "toggle flymake-mode")
    "fn" 'flymake-goto-next-error
    "fp" 'flymake-goto-prev-error)
  :hook (flymake-mode . (lambda () (or (ignore-errors flymake-show-project-diagnostics)
                                       (flymake-show-buffer-diagnostics))))
  :config
  (add-to-list 'display-buffer-alist
               '("\\`\\*[Ff]lymake.*?\\*\\'"
                 display-buffer-in-side-window
                 (side . bottom)
                 (window-height . 0.125)
                 ;; (window-parameters . ((no-other-window . t)))
                 ))

  (defun +flymake-elpaca-bytecomp-load-path ()
    "Augment `elisp-flymake-byte-compile-load-path' to support Elpaca."
    (setq-local elisp-flymake-byte-compile-load-path
                `("./" ,@(mapcar #'file-name-as-directory
                                 (nthcdr 2 (directory-files (expand-file-name "builds" elpaca-directory) 'full))))))
  (add-hook 'flymake-mode-hook #'+flymake-elpaca-bytecomp-load-path))

(use-package flymake-guile
  :defer t
  :hook (scheme-mode . flymake-guile))

(use-package flyover)

(use-feature flyspell
  :commands (flyspell-mode flyspell-prog-mode)
  :general
  (+general-global-toggle
    "ss" 'flyspell-mode
    "sp" 'flyspell-prog-mode)
  (+general-global-spelling
    "n" 'flyspell-goto-next-error
    "b" 'flyspell-buffer
    "w" 'flyspell-word
    "r" 'flyspell-region)
  :hook ((org-mode mu4e-compose-mode git-commit-mode) . flyspell-mode))

(use-package fontify-face
  :commands (fontify-face-mode))

(use-package transient :defer t)
(use-package forge
  :ensure (:files (:defaults "docs/*" ".dir-locals.el"))
  :after magit
  :init (setq forge-add-default-bindings nil
              forge-display-in-status-buffer nil
              forge-add-pullreq-refspec nil))

(use-package geiser
  :defer t
  :config
  (global-leader
    :major-modes '(scheme-mode)
    :keymaps     '(scheme-mode-map)
    "e" '(:ignore t :which-key "eval")
    "eb" 'geiser-eval-buffer
    "es" 'geiser-eval-last-sexp
    "es" 'geiser-eval-region
    "i" 'geiser-doc-module
    "]" 'geiser-squarify))

(use-package geiser-guile :defer t)

(use-feature help
  :defer 1
  :custom
  (help-enable-variable-value-editing t)
  (help-window-select t "Always select the help window"))

(use-feature savehist
  :defer 1
  :config
  (savehist-mode 1))

(use-package htmlize
  :defer t)

;; Provides a nice interface to evaluating Emacs Lisp expressions.
;; Input is handled by the comint package, and output is passed through the pretty-printer.
(use-feature ielm
  :config
  (global-leader
    :major-modes '(inferior-emacs-lisp-mode)
    :keymaps     '(inferior-emacs-lisp-mode-map)
    "b"  '(:ignore t :which-key "buffer")
    "bb" 'ielm-change-working-buffer
    "bd" 'ielm-display-working-buffer
    "bp" 'ielm-print-working-buffer
    "c"  'comint-clear-buffer)
  ;;@TODO: fix this command.
  ;;This should be easier
  :general
  (+general-global-application "i"
    '("ielm" . (lambda ()
                 (interactive)
                 (let* ((b (current-buffer))
                        (i (format "*ielm<%s>*" b)))
                   (setq ielm-prompt (concat (buffer-name b) ">"))
                   (ielm i)
                   (ielm-change-working-buffer b)
                   (next-buffer)
                   (switch-to-buffer-other-window i))))))

(use-package js2-mode
  :commands (js2-mode)
  :mode "\\.js\\'"
  :interpreter (("nodejs" . js2-mode) ("node" . js2-mode)))

(use-package ligature
  :config
  ;; TODO: configure this
  )

(use-package macrostep
  :config
  (global-leader
    :major-modes '(emacs-lisp-mode lisp-interaction-mode t)
    :keymaps     '(emacs-lisp-mode-map lisp-interaction-mode-map)
    "m"  '(:ignore t :which-key "macrostep")
    "me" 'macrostep-expand
    "mc" 'macrostep-collapse
    "mj" 'macrostep-next-macro
    "mk" 'macrostep-prev-macro))

(use-package magit
  :defer t
  :after (general)
  :custom
  (magit-repository-directories (list (cons elpaca-repos-directory 1)))
  (magit-diff-refine-hunk 'all)
  :general
  (+general-global-git/version-control
    "b"  'magit-branch
    "B"  'magit-blame
    "c"  'magit-clone
    "f"  '(:ignore t :which-key "file")
    "ff" 'magit-find-file
    "fh" 'magit-log-buffer-file
    "i"  'magit-init
    "L"  'magit-list-repositories
    "m"  'magit-dispatch
    "S"  'magit-stage-file
    "s"  'magit-status
    "U"  'magit-unstage-file)
  :config
  (transient-bind-q-to-quit))



;; Enrich existing commands with completion annotations
(use-package marginalia
  :ensure nerd-icons-completion
  :defer 2
  :config
  (marginalia-mode)
  (nerd-icons-completion-mode)
  (with-eval-after-load 'marginalia
    (nerd-icons-completion-marginalia-setup))
  (setf (alist-get 'elpaca-info marginalia-command-categories) 'elpaca))

(use-package markdown-mode
  :commands (markdown-mode gfm-mode)
  :mode
  (("README\\.md\\'" . gfm-mode)
   ("\\.md\\'" . markdown-mode)
   ("\\.markdown\\'" . markdown-mode))
  :custom
  (markdown-command "pandoc"))

(use-feature minibuffer
  :custom (read-file-name-completion-ignore-case t)
  :config
  (defun +minibuffer-up-dir ()
    "Trim rightmost directory component of `minibuffer-contents'."
    (interactive)
    (unless (minibufferp) (user-error "Minibuffer not selected"))
    (let* ((f (directory-file-name (minibuffer-contents)))
           (s (file-name-directory f)))
      (delete-minibuffer-contents)
      (when s (insert s))))
  (define-key minibuffer-local-filename-completion-map
              (kbd "C-h") #'+minibuffer-up-dir)
  (minibuffer-depth-indicate-mode))

(use-package mu4e
  :ensure nil ;; installed via nixos emacs package
  :commands (mu4e mu4e-update-index)
  :custom
  (message-kill-buffer-on-exit t)
  (mu4e-update-interval 900 "Update every fifteen minutes")
  (mail-user-agent 'mu4e-user-agent "Use mu4e as default email program.")
  (mu4e-org-support t)
  (mu4e-maildir (expand-file-name "~/.mail"))
  (mu4e-attachment-dir "~/Downloads")
  (mu4e-completing-read-function 'completing-read)
  (mu4e-compose-signature-auto-include nil)
  (mu4e-use-fancy-chars t)
  (mu4e-view-show-addresses t)
  (mu4e-view-show-images t)
  (mu4e-sent-messages-behavior 'sent)
  (mu4e-get-mail-command "mbsync -a")
  (mu4e-change-filenames-when-moving t "Needed for mbsync")
  (mu4e-confirm-quit nil)
  (mu4e-html2text-command  'mu4e-shr2text)
  (mu4e-context-policy 'pick-first)
  (mu4e-compose-context-policy 'always-ask)
  (mu4e-headers-auto-update t)
  (message-signature nil)
  :config
  ;; Function taken from doom email module
  (defun set-email-account! (label letvars &optional default-p)
    "Registers an email address for mu4e. The LABEL is a string. LETVARS are a
list of cons cells (VARIABLE . VALUE) -- you may want to modify:

 + `user-full-name' (used to populate the FROM field when composing mail)
 + `user-mail-address' (required in mu4e < 1.4)
 + `smtpmail-smtp-user' (required for sending mail from Emacs)

OPTIONAL:
 + `mu4e-sent-folder'
 + `mu4e-drafts-folder'
 + `mu4e-trash-folder'
 + `mu4e-refile-folder'
 + `mu4e-compose-signature'
 + `+mu4e-personal-addresses'

DEFAULT-P is a boolean. If non-nil, it marks that email account as the
default/fallback account."
    (when (version< mu4e-mu-version "1.4")
      (when-let (address (cdr (assq 'user-mail-address letvars)))
        (add-to-list 'mu4e-user-mail-address-list address)))
    ;; remove existing context with same label
    (setq mu4e-contexts
          (cl-loop for context in mu4e-contexts
                   unless (string= (mu4e-context-name context) label)
                   collect context))
    (let ((context (make-mu4e-context
                    :name label
                    :enter-func
                    (lambda () (mu4e-message "Switched to %s" label))
                    :leave-func
                    (lambda ()
                      (setq +mu4e-personal-addresses nil)
                      ;; REVIEW: `mu4e-clear-caches' was removed in 1.12.2, but
                      ;;   may still be useful to users on older versions.
                      (if (fboundp 'mu4e-clear-caches) (mu4e-clear-caches)))
                    :match-func
                    (lambda (msg)
                      (when msg
                        (string-prefix-p (format "/%s" label)
                                         (mu4e-message-field msg :maildir) t)))
                    :vars letvars)))
      (add-to-list 'mu4e-contexts context (not default-p))
      context))
  (set-email-account!
   "protonmail" '((user-full-name . "Jeff Workman")
                  (user-mail-address . "jeff.workman@protonmail.com")
                  (mu4e-sent-folder . "/Sent")
                  (mu4e-drafts-folder . "/Drafts")
                  (mu4e-trash-folder . "/Trash")
                  (mu4e-refile-folder . "/Archive")
                  (smtpmail-smtp-user . "jeff.workman")
                  (smtpmail-smtp-server . "127.0.0.1")
                  (smtpmail-smtp-service . 1025)
                  (smtpmail-stream-type . starttls))
   t)
  (add-to-list 'display-buffer-alist
               `(,(regexp-quote mu4e-main-buffer-name)
                 display-buffer-same-window))
  (add-to-list 'mu4e-view-actions
               '("ViewInBrowser" . mu4e-action-view-in-browser) t)

  (defun +mu4e-view-settings ()
    "Settings for mu4e-view-mode."
    (visual-line-mode)
    (olivetti-mode)
    (variable-pitch-mode))

  (add-hook 'mu4e-view-mode-hook #'+mu4e-view-settings)

  (global-leader :keymaps '(mu4e-compose-mode-map) "a" 'mml-attach-file)

  :general
  (+general-global-application "m" 'mu4e :which-key "mail"))

(use-package nerd-icons :demand t)

(use-package nginx-mode)

(use-package nix-mode)

(use-package nix-ts-mode)

(use-package nix-update)

(use-feature novice
  :custom
  (disabled-command-function nil "Enable all commands"))

;; A simple Emacs minor mode for a nice writing environment.
(use-package olivetti
  :commands (olivetti-mode))

;; Completion style for matching regexps in any order
(use-package orderless
  :defer 1
  :custom
  (completion-styles '(orderless basic))
  (completion-category-overrides '((file (styles partial-completion))
                                   (eglot (styles basic orderless))
                                   (eglot-capf (styles basic orderless))
                                   (lsp-capf (styles basic orderless)))))

(load-file (expand-file-name "init-org.el" user-emacs-directory))

(use-package package-lint
  :defer t
  :commands (package-lint-current-buffer +package-lint-elpaca)
  :config
  (defun +package-lint-elpaca ()
    "Help package-lint deal with elpaca."
    (interactive)
    (require 'package)
    (setq package-user-dir "/tmp/elpa")
    (add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
    (package-initialize)
    (package-refresh-contents))
  (+package-lint-elpaca))

(use-package paren-face
  :defer 2
  :config (global-paren-face-mode))

(use-feature paren
  :defer 1
  :config (show-paren-mode))

(use-package persp-mode
  :disabled t
  :defer 1
  :config (persp-mode))

(use-package project
  :defer t
  :after (general)
  :general
  (+general-global-project
    "q" 'project-query-replace-regexp))

(use-package projectile
  :defer t
  :after (general)
  :general
  (+general-global-project
    "!" 'projectile-run-shell-command-in-root
    "%" 'projectile-replace-regexp
    "&" 'projectile-run-async-shell-command-in-root
    "A" 'projectile-toggle-between-implementation-and-test
    "bn" 'projectile-next-project-buffer
    "bp" 'projectile-previous-project-buffer
    "c" 'projectile-compile-project
    "D" 'projectile-discover-projects-in-directory
    "e" 'projectile-edit-dir-locals
    "g" 'projectile-find-tag
    "G" 'projectile-regenerate-tags
    "i" 'projectile-invalidate-cache
    "k" 'projectile-kill-buffers
    "R" 'projectile-replace
    "s" 'projectile-save-project-buffers
    "T" 'projectile-test-project
    "v" 'projectile-vc

    "p" 'projectile-switch-project
    "b" 'projectile-switch-to-buffer
    "f" 'projectile-find-file
    "F" 'projectile-find-file-dwim
    "r" 'projectile-recentf
    "d" 'projectile-find-dir
    "d" 'projectile-remove-known-project
    "k" 'projectile-kill-buffers)
  :config
  (add-to-list 'projectile-globally-ignored-directories "*node_modules")
  (projectile-mode))

(use-package pdf-tools
  :ensure (pdf-tools :pre-build ("./server/autobuild") :files (:defaults "server/epdfinfo"))
  :functions (pdf-isearch-batch-mode)
  :commands (pdf-tools-install pdf-view-mode)
  :custom (pdf-view-midnight-colors '("#AFA27C" . "#0F0E16"))
  :config (add-hook 'pdf-view-mode-hook
                    (lambda ()
                      ;; get rid of borders on pdf's edges
                      (set (make-local-variable 'evil-normal-state-cursor) (list nil))
                      ;;for fast i-search in pdf buffers
                      (pdf-isearch-minor-mode)
                      (pdf-isearch-batch-mode)
                      (pdf-view-dark-minor-mode)
                      (pdf-view-midnight-minor-mode)))
  :mode (("\\.pdf\\'" . pdf-view-mode)))

(use-package rainbow-mode
  :commands (rainbow-mode))

(use-package uniquify
  :disabled t
  :config
  (setq uniquify-buffer-name-style 'post-forward
        uniquify-separator "|"
        uniquify-after-kill-buffer-p t
        uniquify-ignore-buffers-re "^\\*"))

(use-feature re-builder
  :custom
  (reb-re-syntax 'rx)
  :commands (re-builder))

(use-feature recentf
  :defer 1
  :config (recentf-mode)
  :custom
  (recentf-max-menu-items 1000 "Offer more recent files in menu")
  (recentf-max-saved-items 1000 "Save more recent files"))

(use-package sly)

(use-package smartparens
  :config
  ;; TODO: configure this
  )

(elpaca (straight.el :host github
                     :repo "radian-software/straight.el"
                     :files ("straight*.el")))

(use-feature tab-bar
  :custom
  (tab-bar-close-button-show nil "Dont' show the x button on tabs")
  (tab-bar-new-button-show   nil)
  (tab-bar-show  nil "hide the tab bar. Use commands to access tabs.")
  :general
  (+general-global-tab
    "b" 'tab-bar-history-back
    "d" 'tab-bar-close-tab
    "f" 'tab-bar-history-forward
    "N" 'tab-bar-new-tab
    "n" 'tab-bar-switch-to-next-tab
    "p" 'tab-bar-switch-to-prev-tab
    "L" '((lambda (arg) (interactive "p") (tab-bar-move-tab arg))
          :which-key "tab-bar-move-tab-right")
    "l" 'tab-bar-switch-to-next-tab
    "H" '((lambda (arg) (interactive "p") (tab-bar-move-tab (- arg)))
          :which-key "tab-bar-move-tab-left")
    "h" 'tab-bar-switch-to-prev-tab
    "r" 'tab-bar-rename-tab
    "t" 'tab-bar-switch-to-tab
    "u" 'tab-bar-undo-close-tab
    "O" 'tab-bar-close-other-tabs
    "w" 'tab-bar-move-tab-to-frame))

(use-feature tab-line
  :custom
  (tab-line-close-button-show nil)
  (tab-line-new-button-show   nil))

(use-feature tramp
  :defer t
  :custom (tramp-terminal-type "tramp")
  :config (setq debug-ignored-errors (cons 'remote-file-error debug-ignored-errors)))

(use-feature vc-hooks
  :custom
  (vc-follow-symlinks t "Visit real file when editing a symlink without prompting."))

(use-package vertico
  :demand t
  :custom (vertico-cycle t)
  :config
  (setf (car vertico-multiline) "\n") ;; don't replace newlines
  (vertico-mode)
  (define-key vertico-map (kbd "C-h") #'+minibuffer-up-dir))

(use-package vterm
  :ensure (vterm :post-build
                 (progn
                   (setq vterm-always-compile-module t)
                   (require 'vterm)
                   ;;print compilation info for elpaca
                   (with-current-buffer (get-buffer-create vterm-install-buffer-name)
                     (goto-char (point-min))
                     (while (not (eobp))
                       (message "%S"
                                (buffer-substring (line-beginning-position)
                                                  (line-end-position)))
                       (forward-line)))
                   (when-let* ((so (expand-file-name "./vterm-module.so"))
                               ((file-exists-p so)))
                     (make-symbolic-link
                      so (expand-file-name (file-name-nondirectory so)
                                           "../../builds/vterm")
                      'ok-if-already-exists))))
  :commands (vterm vterm-other-window)
  :general
  (+general-global-application
    "t" '(:ignore t :which-key "terminal")
    "tt" 'vterm-other-window
    "t." 'vterm)
  :config
  (evil-set-initial-state 'vterm-mode 'emacs))

(use-package which-key
  :demand t
  :init
  (setq which-key-enable-extended-define-key t)
  :config
  (which-key-mode)
  :custom
  (which-key-side-window-location 'bottom)
  (which-key-sort-order 'which-key-key-order-alpha)
  (which-key-side-window-max-width 0.33)
  (which-key-idle-delay 0.2))

(use-feature windmove
  :config
  (setq windmove-ignore-window-parameters t)
  (windmove-default-keybindings '(control meta))
  (windmove-mode +1))

(use-feature winner
  :defer 5
  :config
  (+general-global-window
    "u" 'winner-undo
    "r" 'winner-redo)
  (winner-mode))

(use-feature window
  :custom
  (switch-to-buffer-obey-display-actions t)
  (switch-to-prev-buffer-skip-regexp
   '("\\*Help\\*" "\\*Calendar\\*" "\\*mu4e-last-update\\*"
     "\\*Messages\\*" "\\*scratch\\*" "\\magit-.*" "\\*[Ff]lymake.*")))

(use-package yasnippet
  :commands (yas-global-mode)
  :custom
  (yas-snippet-dirs '("~/.emacs.d/snippets")))

(use-feature ruby-ts-mode
  :mode "\\.lic\\'")

(use-package yaml-mode)
