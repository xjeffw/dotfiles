;; -*- lexical-binding: t -*-

(defun --toggle-emacs-debug (&optional force enable)
  (interactive)
  (let ((enable (if force (not (not enable)) (not debug-on-error))))
    (setq! debug-on-error enable
           backtrace-on-redisplay-error enable
           debug-on-message (if enable ".*Selecting deleted buffer.*" nil))
    (if enable
        (message "Enabled emacs debugging")
      (message "Disabled emacs debugging"))
    enable))
;; (--toggle-emacs-debug t t)

(pushnew! debug-ignored-errors
          'scan-sexps
          ".*debug-on-message.*"
          "\.\*Selecting deleted buffer\.\*"
          ".*Window.*too small.*")

(defun --filter-messages (orig-fun format-string &rest args)
  "Wrapper for `message' to hide spammy deprecation warnings.
ORIG-FUN is the original `message' function.
FORMAT-STRING and ARGS are the arguments passed to `message'."
  (if (null format-string)
      (apply orig-fun nil nil)
    (let ((output (apply #'format-message format-string args)))
      (unless (or (string-match ".*when-let.*" output)
                  (string-match ".*if-let.*" output))
        (apply orig-fun format-string args)))))

(advice-add 'message :around #'--filter-messages)
;; (advice-remove 'message #'--filter-messages)

(require 'dash)
(require 's)
(require 'f)
(require 'ht)
(require 'doom-lib)
(require 'doom)
(require 'deferred)
(require 'shut-up)
(require 'bytecomp)
(require 'server)

(add-load-path! (dir!))

(byte-recompile-file (concat (dir!) "commands.el") nil 0 t)
(load! "commands")

(defvar --window-opacity nil)
(defvar --background-color nil)
(load (expand-file-name "~/.config/config-nix.el"))
;; (setq! --window-opacity 1.0)

(setq! split-window-preferred-function 'split-window-prefer-horizontal)

(after! copilot
  (pushnew! copilot-disable-predicates '--byte-compiling-p)
  (pushnew! warning-suppress-types '(copilot copilot-exceeds-max-char)))

(require 'gcmh)

(setq! user-full-name "Jeff Workman"
       user-mail-address "jeff.workman@protonmail.com"
       doom-leader-key "SPC"
       doom-leader-alt-key "C-SPC"
       smie-indent-basic 2
       +workspaces-on-switch-project-behavior 'non-empty
       display-line-numbers-type t
       emojify-download-emojis-p t
       org-directory "~/org/"
       confirm-kill-processes t
       frame-title-format
       '((:eval (let ((lexical-binding t))
                  (-if-let (buffer (or (-some-> (minibuffer-selected-window) (window-buffer))
                                       (current-buffer)))
                      (with-current-buffer buffer
                        (let* ((buffer-name (if (and (featurep 'doom-modeline)
                                                     (not (and (featurep 'hide-mode-line) hide-mode-line-mode)))
                                                (substring-no-properties (or (doom-modeline--buffer-name) ""))
                                              "%b"))
                               (buffer-name (if (equal buffer-name "%b") (buffer-name) buffer-name))
                               (buffer-name (or buffer-name "")))
                          (concat
                           (-> (-some-> (nerd-icons-icon-for-buffer)
                                 (substring-no-properties)
                                 (concat "  "))
                               (or ""))
                           (string-trim buffer-name "[ \\\t\\\r\\\n\\*]+" "[ \\\t\\\r\\\n\\*]+")
                           (unless (display-graphic-p) " - Emacs"))))
                    "Emacs"))))
       require-final-newline t
       large-file-warning-threshold (* 10 1000 1000)
       ;; catppuccin-flavor 'macchiato
       catppuccin-flavor 'frappe
       ;; doom-theme 'doom-one
       ;; doom-theme 'doom-tomorrow-night
       doom-theme 'catppuccin
       doom-one-brighter-comments t
       doom-one-brighter-modeline nil
       doom-themes-padded-modeline nil
       doom-gruvbox-dark-variant "medium"
       gcmh-high-cons-threshold (* 1024 1024 1000))

(require 'catppuccin-theme)

;; (setf (alist-get 'alpha-background default-frame-alist) --window-opacity)
(setf (alist-get 'alpha-background default-frame-alist) nil)
(setf (alist-get 'right-fringe default-frame-alist) 8)
(setf (alist-get 'left-fringe default-frame-alist) 8)
(setf (alist-get 'internal-border-width default-frame-alist) 0)
;; (set-frame-parameter nil 'internal-border-width 0)

(menu-bar-mode -1)
(global-auto-revert-mode t)
(transient-mark-mode t)
(delete-selection-mode t)
(windmove-default-keybindings '(control meta))
(windmove-mode +1)

(setq-default tab-width 2               ; editorconfig overrides this
              fill-column 100
              byte-compile-warning-types '(not free-vars constants mutate-constant)
              lisp-indent-offset nil)

;; Swap () and [] keys
(define-key! key-translation-map
  "(" "["
  ")" "]"
  "[" "("
  "]" ")")

(when (mac?)
  (setq! mac-command-modifier 'meta
         mac-right-command-modifier 'left
         mac-option-modifier 'super
         mac-right-option-modifier 'left))

(when (featurep 'pgtk) (setq! use-system-tooltips t))

(use-package! disable-mouse
  :if (asahi?)
  :config
  (global-disable-mouse-mode +1)
  (mapc #'disable-mouse-in-keymap
        (list evil-motion-state-map
              evil-normal-state-map
              evil-visual-state-map
              evil-insert-state-map)))

(use-package! centered-window
  :disabled t
  :config
  (setq! cwm-centered-window-width 120
         split-width-threshold 160)
  (centered-window-mode 1))

(use-package! uniquify
  :config
  (setq uniquify-buffer-name-style 'post-forward
        uniquify-separator "|"
        uniquify-after-kill-buffer-p t
        uniquify-ignore-buffers-re "^\\*"))

(defvar --modeline-font nil)

(progn
  (defun --get-font-spec (&optional variable? modeline?)
    (if modeline?
        nil
      (apply 'font-spec
             :family (if variable? "Inter" "JetBrainsMono Nerd Font")
             :size (+ 12
                      (if variable? 0 0)
                      (if modeline? 0 0)
                      (if (mac?) 1 0)
                      (if (asahi?) 0 0))
             :weight (if variable? 'medium
                       (if (mac?) (if modeline? 'bold 'semibold)
                         (if modeline? 'extrabold 'bold)))
             nil)))
  (cl-eval-when 'eval
    (-some-> (symbol-function '--sync-fonts) funcall)))

(progn
  (defun --configure-fonts ()
    (setq! doom-font (--get-font-spec)
           --modeline-font (--get-font-spec nil t)
           doom-big-font nil
           doom-big-font-increment 2
           doom-font-increment 1
           doom-variable-pitch-font (--get-font-spec t))

    (custom-theme-set-faces! 'doom-tomorrow-night
      `(font-lock-comment-face :foreground "#8d8e8e")
      `(font-lock-doc-face :foreground "#8d8e8e")
      `(shadow :foreground "#868889"))

    (custom-theme-set-faces! 'catppuccin
      `(highlight
        :foreground ,(catppuccin-lighten "#cad3f5" 40)
        :background ,(catppuccin-lighten "#2f3244" 16))
      ;; `(hl-line :background ,(catppuccin-lighten "#2f3244" 2))
      `(shadow :foreground ,(catppuccin-lighten "#6e738d" 50))
      `(lsp-inlay-hint-face :foreground ,(catppuccin-lighten "#6e738d" 25))
      `(lsp-flycheck-warning-unnecessary-face
        :foreground ,(catppuccin-color 'subtext1)
        :underline ,(catppuccin-darken (catppuccin-color 'yellow) 10)))

    (defun --set-faces-on-frame (&optional frame)
      (let ((frame (or frame (selected-frame))))
        (if (display-graphic-p frame)
            ;; gui emacs
            (progn
              (set-face-attribute 'default frame
                                  :background --background-color)
              (set-face-attribute 'lsp-lens-face frame
                                  :weight 'extrabold
                                  :height 0.9
                                  :inherit 'shadow)
              (set-face-attribute 'lsp-inlay-hint-face frame
                                  :family "Fira Code"
                                  :weight 'bold
                                  :height 0.85)
              (set-face-attribute 'tree-sitter-hl-face:function.call frame
                                  :weight 'unspecified)
              (set-face-attribute 'tree-sitter-hl-face:punctuation.delimiter frame
                                  :foreground (catppuccin-lighten "#939ab7" 50)) )
          ;; transparency for terminal
          (set-face-background 'default "#00000000" frame)
          (set-face-background 'hl-line "#00000000" frame))))
    (add-hook! '(after-make-frame-functions server-after-make-frame-hook)
               :append '--set-faces-on-frame)
    (add-hook! 'doom-load-theme-hook
               :append (-each (frame-list) '--set-faces-on-frame))

    (-each (frame-list) '--set-faces-on-frame)

    (if --modeline-font
        (custom-theme-set-faces! nil
          `(doom-modeline :font ,--modeline-font)
          `(mode-line :font ,--modeline-font)
          `(mode-line-active :font ,--modeline-font)
          `(mode-line-inactive :font ,--modeline-font))
      (custom-theme-set-faces! nil
        `(doom-modeline :weight extrabold)
        `(mode-line :weight extrabold)
        `(mode-line-active :weight extrabold)
        `(mode-line-inactive :weight extrabold)))
    nil)
  (cl-eval-when 'eval
    (-some-> (symbol-function '--configure-fonts) funcall)))

(--configure-fonts)

;; (after! doom-modeline ;; TODO: run this?
;;   ;; workaround for modeline focus bug
;;   ;; running doom/reload-font after focusing frame also fixes this
;;   (remove-function after-focus-change-function #'doom-modeline-focus-change))

(defun --sync-fonts (&optional frame)
  (interactive)
  (--configure-fonts)
  (when (and (graphical?) (null frame))
    (set-frame-font doom-font)))

(add-hook! 'doom-after-reload-hook :append '--sync-fonts)

(defvar-local --modeline-cache ""
  "Cached string produced by `doom-modeline-format--main'.")

(defvar-local --modeline-timer nil
  "Idle timer used to refresh `--modeline-cache' for the current buffer.")

(defun --schedule-modeline-update ()
  "Schedule a deferred refresh of `--modeline-cache' for the current buffer."
  (when --modeline-timer
    (cancel-timer --modeline-timer)
    (setq --modeline-timer nil))
  (let ((buffer (current-buffer)))
    (setq-local
     --modeline-timer
     (run-with-idle-timer
      0.05 nil
      (lambda ()
        (when (buffer-live-p buffer)
          (with-current-buffer buffer
            (setq-local --modeline-cache (format-mode-line (doom-modeline-format--main)))
            (setq-local --modeline-timer nil))))))))

(defun --format-modeline-cached ()
  "Return cached modeline text while scheduling a refresh."
  (let ((cached (or --modeline-cache "")))
    (--schedule-modeline-update)
    cached))

(define-advice doom-modeline-set-modeline
    (:around (orig-fn key &optional default) --cache-main-modeline)
  (if (eql key 'main)
      (setf (if default
                (default-value 'mode-line-format)
              mode-line-format)
            '("%e" (:eval (--format-modeline-cached))))
    (funcall orig-fn key default)))

(use-package! doom-modeline
  :defer t
  :init
  (setq! doom-modeline-buffer-file-name-style 'truncate-with-project
         doom-modeline-persp-name t
         doom-modeline-persp-icon t
         doom-modeline-buffer-encoding 'nondefault
         doom-modeline-default-eol-type 0
         doom-modeline-indent-info t
         doom-modeline-height 23
         doom-modeline-major-mode-icon t)
  :config
  (size-indication-mode -1)
  (add-hook! 'doom-modeline-mode-hook :append (size-indication-mode -1)))
;; (doom-modeline-format--main)

(use-package! ruby-mode
  :mode (("\\.lic\\'" . ruby-mode)
         ("\\.rb\\'"  . ruby-mode)))

(after! mu4e
  (setq! mu4e-get-mail-command "mbsync -a"
         mu4e-change-filenames-when-moving t
         ;; mu4e-update-interval 300
         mu4e-headers-auto-update t
         message-signature nil)
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
  (use-package! mu4e-alert
    :config
    (mu4e-alert-enable-notifications)
    (mu4e-alert-enable-mode-line-display)))

(use-package! smartparens
  :init
  (setq sp-base-key-bindings 'sp
        sp-override-key-bindings '(("C-M-<left>"  . nil)
                                   ("C-M-<right>" . nil)
                                   ("C-M-<up>"    . nil)
                                   ("C-M-<down>"  . nil)
                                   ("C-M-w"       . nil)
                                   ("C-<left>"    . nil)
                                   ("C-<right>"   . nil))
        sp-navigate-interactive-always-progress-point t)
  :config
  (add-hook! smartparens-mode 'evil-smartparens-mode))

(use-package evil-easymotion
  :after evil
  :config
  (define-key evilem-map "=" #'evilem-motion-next-line-first-non-blank)
  (evilem-default-keybindings "g s"))

(setq lispy-key-theme '(lispy))
(after! lispy
  (pushnew! lispy-clojure-modes 'cider-repl-mode)
  (undefine-key! lispy-mode-map-lispy "[" "]" "{" "}" "M-." "C-k" "C-j")
  (lispy-set-key-theme lispy-key-theme)
  (doom-require 'lispyville))

(setq! lispyville-key-theme '((operators normal)
                              c-w
                              (prettify insert)
                              (atom-movement t)
                              (additional motion)
                              additional-motions
                              (commentary t)
                              mark-special))
(after! lispyville
  ;; for changing lispyville-key-theme after package has loaded
  ''(progn
      (setq! lispyville-mode-map (make-sparse-keymap))
      (lispyville-set-key-theme lispyville-key-theme)
      (setf (alist-get 'lispyville-mode minor-mode-map-alist) lispyville-mode-map))
  (add-hook! lispy-mode 'lispyville-mode)
  (map! :m "RET" 'newline-and-indent
        :mode lispy-mode
        :nvmi "DEL" 'lispy-delete-backward
        "M-<up>" 'lispyville-drag-backward
        "M-<down>" 'lispyville-drag-forward
        :mode lispyville-mode
        :nm "<" 'lispyville-beginning-of-defun
        :nm ">" 'lispyville-beginning-of-next-defun
        :i "<" nil
        :i ">" nil
        :nmi "C->" 'lispyville-end-of-defun
        :i "[" 'lispy-open-square
        :i "]" 'lispy-close-square
        :i "{" 'lispy-open-curly
        :i "}" 'lispy-close-curly
        :m "C-{" 'lispyville-previous-opening
        :m "C-}" 'lispyville-next-closing
        :m "F" 'lispyville-forward-atom-end
        :m "B" 'lispyville-backward-atom-begin
        :mi "C-f" 'lispyville-forward-sexp
        :mi "C-b" 'lispyville-backward-sexp)
  (map! :mode lispyville-mode
        :leader
        "(" 'lispyville-wrap-round
        "[" 'lispyville-wrap-brackets
        "{" 'lispyville-wrap-braces))

(use-package! evil-matchit
  :after evil
  :init (setq! evilmi–shortcut "%")
  :config (global-evil-matchit-mode 1))

(use-package! evil-snipe
  :after evil
  :init
  (setq! evil-snipe-scope 'whole-visible
         evil-snipe-repeat-scope 'whole-visible
         evil-snipe-spillover-scope nil
         evil-snipe-smart-case t
         evil-snipe-tab-increment t)
  :config
  (evil-snipe-mode 1)
  (evil-snipe-override-mode 1)
  (map! :mode (evil-snipe-override-mode evil-snipe-override-local-mode)
        :m "F" nil))

(use-package! elisp-mode
  :mode ("\\.el\\'" . emacs-lisp-mode)
  :config
  (map! :mode (emacs-lisp-mode lisp-interaction-mode)
        :localleader
        "e p" 'eval-print-last-sexp)
  nil)

(after! magit
  (setq! magit-display-buffer-function #'magit-display-buffer-same-window-except-diff-v1)
  (setq! transient-display-buffer-action '(display-buffer-in-side-window
                                           (side . bottom)
                                           (dedicated . t)
                                           (inhibit-same-window . t)))
  (map! :mode magit-mode
        :nv "/" nil))

(use-package! forge
  :after magit
  :config
  (setq auth-sources '("~/.authinfo")))

(use-package! gptel
  :bind ("C-S-l" . gptel-menu)
  :config
  (setq! --gptel-anthropic (gptel-make-anthropic "Claude"
                             :stream t
                             :key (lambda () (--pass-get "keys/anthropic"))))
  (let ((use-anthropic t))
    (if use-anthropic
        (setq! gptel-backend --gptel-anthropic
               gptel-model "claude-3-7-sonnet-20250219"
               gptel-api-key (lambda () (--pass-get "keys/anthropic")))
      (setq! gptel-backend gptel--openai
             gptel-model "gpt-4o"
             gptel-api-key (lambda () (--pass-get "keys/openai"))))))

(use-package! elysium
  :disabled t
  :defer-incrementally t
  :config
  (map! "C-S-k SPC" 'elysium-toggle-window
        "C-S-k RET" 'elysium-query
        "C-S-k c" 'elysium-keep-all-suggested-changes
        "C-S-k k" 'elysium-discard-all-suggested-changes
        :leader
        "K SPC" 'elysium-toggle-window
        "K RET" 'elysium-query
        "K c" 'elysium-keep-all-suggested-changes
        "K k" 'elysium-discard-all-suggested-changes))

(map! :leader
      :desc "Kill sexp"
      "k" 'sp-kill-sexp
      ;; :desc "Kill at point"
      ;; "K" 'lispy-kill-at-point
      :desc "Wrap with ()"
      "(" 'sp-wrap-round
      :desc "Wrap with []"
      "[" 'sp-wrap-square
      :desc "Wrap with {}"
      "{" 'sp-wrap-curly
      :desc "Recenter buffer"
      "l" 'recenter-top-bottom
      :desc "Format buffer"
      "C-f" '+format/buffer
      :desc "Mark sexp"
      "RET" 'lispy-mark
      :desc "Mark defun"
      "S-<return>" 'er/mark-defun
      :desc "Reload doom with nix"
      "h r n" 'doom/nix-reload
      :desc "org-pomodoro"
      "C-p" 'org-pomodoro
      :desc "Jump to cider-repl"
      "r" '--cider-goto-repl
      :desc "List workspaces"
      "0" '+workspace/display
      :desc "Switch workspace"
      "\\" '+workspace/switch-to
      :desc "Switch workspace left"
      "-" '+workspace/switch-left
      :desc "Switch workspace right"
      "=" '+workspace/switch-right
      :desc "Workspace 1"
      "1" '+workspace/switch-to-0
      :desc "Workspace 2"
      "2" '+workspace/switch-to-1
      :desc "Workspace 3"
      "3" '+workspace/switch-to-2
      :desc "Workspace 4"
      "4" '+workspace/switch-to-3
      :desc "Workspace 5"
      "5" '+workspace/switch-to-4
      :desc "Workspace 6"
      "6" '+workspace/switch-to-5
      :desc "Workspace 7"
      "7" '+workspace/switch-to-6
      :desc "Workspace 8"
      "8" '+workspace/switch-to-7
      :desc "Workspace 9"
      "9" '+workspace/switch-to-8
      :desc "Query replace in project"
      "p q" 'project-query-replace-regexp)

(map! :m "0" 'doom/backward-to-bol-or-indent
      :m "g 0" 'evil-beginning-of-line
      :m "C-a" 'doom/backward-to-bol-or-indent
      :mi "C-f" 'sp-forward-sexp
      :mi "C-b" 'sp-backward-sexp
      :m "C-e" 'evil-end-of-line
      :mi "C-y" 'yank)

(with-eval-after-load 'help-mode
  (map! :mode help-mode
        :n "C-o" nil))

(map! :m "C-o" nil
      :m "<tab>" nil
      :m "TAB" nil
      :n "M-." nil
      :g "M-<left>" nil
      :g "M-<right>" nil
      :g "C-s-<backspace>"  '+default/newline-above
      :g "C-s-k"            '+default/newline-above
      :g "C-s-<return>"     '+default/newline-below
      :g "C-s-j"            '+default/newline-below
      "<tab>" nil
      "TAB" nil
      :m "/" '+default/search-buffer
      "M-," 'pop-tag-mark
      "M-." '+lookup/definition
      "M->" '+lookup/references
      "C-o" 'ace-select-window
      "C-1" 'delete-other-windows
      "C-x 1" 'delete-other-windows
      "C-2" 'delete-other-windows-vertically
      "C-x 2" 'delete-other-windows-vertically
      "C-q" 'delete-window
      "C-S-x" 'split-window-below
      "C-x x" 'split-window-below
      "C-<down>" '--scroll-down-one-line
      "C-<up>" '--scroll-up-one-line
      "C-j" '--scroll-down-one-line
      "C-k" '--scroll-up-one-line
      "C-<left>" 'previous-buffer
      "C-<right>" 'next-buffer
      ;; "C-S-<left>" '+workspace/switch-left
      ;; "C-S-<right>" '+workspace/switch-right
      "C-l" 'recenter-top-bottom
      "C-x C-k" 'kill-region
      "C-M-k" 'sp-kill-sexp
      "C-M-w" 'split-window-auto
      "C-M-f" 'toggle-frame-fullscreen
      "C-c ;" 'comment-or-uncomment-region
      "C-x \\" '--align-regexp
      "C-\\" '--align-regexp)

(defun --set-paren-face-colors ()
  (let ((paren-color  (cond (t "#707070")))
        (square-color (cond (t "#bbbf40")))
        (curly-color  (cond (t "#4f8f3d"))))
    (face-spec-set 'parenthesis `((t (:inherit shadow))))
    (defface square-brackets
      `((t (:foreground ,square-color)))
      "Face for displaying square brackets."
      :group 'paren-face)
    (defface curly-brackets
      `((t (:foreground ,curly-color)))
      "Face for displaying curly brackets."
      :group 'paren-face)))
;; (add-hook! 'after-make-frame-functions '--init-copy-paste)

(use-package! paren-face
  :disabled t
  :config
  (setq paren-face-regexp "[\\(\\)]")
  (global-paren-face-mode)
  (--set-paren-face-colors)
  (defconst clojure-brackets-keywords
    '(("\\[" 0 'square-brackets)
      ("\\]" 0 'square-brackets)
      ("[\\{\\}]" 0 'curly-brackets)))
  (defun --custom-paren-face-mode-hook ()
    (if paren-face-mode
        (font-lock-add-keywords nil clojure-brackets-keywords t)
      (font-lock-remove-keywords nil clojure-brackets-keywords))
    (when (called-interactively-p 'any)
      (font-lock-ensure)))
  (add-hook! 'paren-face-mode-hook '--custom-paren-face-mode-hook))

(after! smerge-mode
  (require 'evil-core)
  (map! :mode smerge-mode
        :n "g c" nil))

(defun --emacs-startup ()
  (auto-compression-mode 1)
  (--init-copy-paste)
  (when (or (graphical?) (and (featurep 'server) server-process))
    (--load-default-session))
  (--kill-external-source-buffers)
  (--projectile-remove-external-projects)
  ;; (--toggle-emacs-debug t t)
  t)
(add-hook! 'emacs-startup-hook :depth 90 '--emacs-startup)

(after! tramp
  (setq! tramp-default-method "ssh")
  (pushnew! tramp-methods '("vcsh"
                            (tramp-login-program "vcsh")
                            (tramp-login-args
                             (("enter")
                              ("%h")))
                            (tramp-remote-shell "/bin/sh")
                            (tramp-remote-shell-args
                             ("-c")))))

(defun --sh-mode-hook ()
  (add-hook! 'after-save-hook :local
             'executable-make-buffer-file-executable-if-script-p)
  (after! company (company-shell-rebuild-cache))
  (setq-local +format-with 'shfmt))

(after! sh-script
  (set-mode-name sh-mode "Sh")
  (add-hook! sh-mode '--sh-mode-hook)
  (add-hook! (sh-mode shell-mode) 'rainbow-mode)
  (after! company (use-package! company-shell)))

(after! hl-line
  (setq! hl-line-overlay-priority -80))

(after! paradox
  (setq! paradox-github-token (--pass-get "keys/github/paradox")))

(after! rainbow-mode
  (setq! rainbow-html-colors t
         rainbow-html-colors-alist nil
         rainbow-ansi-colors 'auto
         rainbow-x-colors nil
         rainbow-latex-colors nil
         rainbow-r-colors nil)
  (after! hl-line
    ;; Disable hl-line-mode when rainbow-mode is enabled
    ;; because it interferes with the colors.
    (add-hook! rainbow-mode
      (hl-line-mode (if rainbow-mode -1 +1)))))

(after! cc-mode
  :config
  (setq-hook! (c-mode c++-mode objc-mode java-mode)
    indent-tabs-mode t))

(after! corfu
  (corfu-popupinfo-mode 1)
  (corfu-history-mode 1)
  (setq! corfu-separator ?\s
         corfu-min-width 32
         corfu-max-width 80
         corfu-bar-width 0.2
         corfu-left-margin-width 0.5
         corfu-right-margin-width 0.5
         corfu-preview-current t
         corfu-preselect 'directory
         corfu-auto-delay 0.2
         corfu-auto-prefix 3)
  (setq! corfu-popupinfo-delay '(1.0 . 0.5)
         corfu-popupinfo-resize nil
         corfu-popupinfo-hide t
         corfu-popupinfo-min-height 4
         corfu-popupinfo-max-height 15
         corfu-popupinfo-min-width 30
         corfu-popupinfo-max-width 80)

  (map! :mode corfu-mode
        "C-." 'complete-symbol
        "C-x C-o" 'complete-symbol
        :nmig
        "C-SPC" nil
        "C-<space>" nil
        :map corfu-map
        :nmig "M-SPC" 'corfu-insert-separator
        :nmig "C-SPC" 'corfu-insert-separator
        :nmig "RET" 'corfu-complete)
  nil)

(after! adaptive-wrap
  ;; (+global-word-wrap-mode 1)
  )

;; (pushnew! +word-wrap-disabled-modes 'cider-repl-mode)

(use-package! helpful :defer-incrementally t)

(defvar --pass-get-cache (make-hash-table :test 'equal :size 10))
(defun --pass-get (name)
  (with-memoization (gethash name --pass-get-cache)
    (nth 0 (process-lines "pass" name))))

;; (use-package! shell-maker)

(use-package! chatgpt-shell
  :disabled t
  :init (use-package! shell-maker)
  :config
  (setq! chatgpt-shell-openai-key (fn! (--pass-get "keys/openai"))))

(use-package! copilot
  :defer 5.0
  :commands copilot-mode
  :hook ((prog-mode . copilot-mode) (conf-mode . copilot-mode))
  :config
  (setq! copilot-idle-delay 0.1
         copilot-max-char 100000
         copilot-indent-offset-warning-disable t)
  (pushnew! copilot-clear-overlay-ignore-commands
            '--copilot-show-or-accept
            '--copilot-complete-or-next
            'corfu-next
            'corfu-previous
            'corfu-scroll-down
            'corfu-scroll-up
            'corfu-first
            'corfu-last
            'corfu-insert-separator
            'corfu-complete)
  (map! :mode copilot-mode
        :nmi "TAB" '--copilot-show-or-accept
        :nmi "<tab>" '--copilot-show-or-accept
        :nmi "M-<tab>" '--copilot-complete-or-next
        :nmi "M-TAB" '--copilot-complete-or-next
        :nmi "S-TAB" 'copilot-accept-completion-by-line
        :nmi "<backtab>" 'copilot-accept-completion-by-line
        :nmi "C-TAB"  'copilot-accept-completion-by-word
        :nmi "C-<tab>" 'copilot-accept-completion-by-word)
  (map! :map copilot-completion-map
        :nmi "TAB" 'copilot-accept-completion
        :nmi "<tab>" 'copilot-accept-completion)
  (map! :i "C-TAB" nil
        :i "C-<tab>" nil
        :i "<backtab>" nil)
  (after! corfu
    (map! :map corfu-map
          :nmig "TAB" nil
          :nmig "<tab>" nil
          :nmig "S-TAB" nil
          :nmig "<backtab>" nil))
  (after! company
    (map! :map company-active-map
          "TAB" nil
          "<tab>" nil
          "<enter>" 'company-complete-selection
          "RET" 'company-complete-selection
          "<return>" 'company-complete-selection)))

(after! projectile
  (setq projectile-indexing-method 'alien
        projectile-enable-caching nil))

(after! swiper
  (setq swiper-action-recenter t)
  (map! "C-s" 'swiper
        "C-r" 'swiper
        "C-S-S" 'swiper-all
        :m "/" '+default/search-buffer))

(use-package! ligature)

(use-package! hl-todo
  :defer-incrementally t
  :config
  (global-hl-todo-mode 1))

(use-package! alert
  :init
  (setq alert-default-style (if (graphical?) 'libnotify 'message)
        alert-fade-time 3))

(defun --elapsed-alert (title elapsed)
  (let ((alert-fade-time 3))
    (alert (format "Elapsed: %.3fs" elapsed) :title title)))

(defmacro --with-elapsed-time-alert (&rest body)
  `(--elapsed-alert (--body-title ',body)
    (--with-elapsed-time ,@body)))
;;(--with-elapsed-time-alert (+ 1 2))

(defun --describe-init ()
  (interactive)
  (let ((alert-fade-time (if (display-graphic-p) 3 2))
        (inhibit-message nil))
    (alert (format "Emacs started in %s" (--init-time t))
           :title (format "Emacs <%s>" (buffer-name))
           :category 'emacs-init)))

(when (graphical?)
  (add-hook! 'after-init-hook '--describe-init))

(setq-default flycheck-disabled-checkers
              '(clojure-cider-typed
                clojure-cider-kibit
                clojure-cider-eastwood
                emacs-lisp-checkdoc))

(use-package! elsa
  :defer t)

(use-package! elsa-lsp
  :commands elsa-lsp-register)

(defun --set-flycheck-eslint ()
  (require 'flycheck)
  (require 'lsp)
  (lsp-diagnostics-lsp-checker-if-needed)
  (setq-local flycheck-checker 'javascript-eslint)
  (flycheck-add-next-checker 'javascript-eslint 'lsp)
  (flycheck-mode 1)
  (lsp-mode 1)
  (flycheck-select-checker 'javascript-eslint))

(defun +syntax-init-popups-h ()
  (require 'flycheck)
  (unless (and (bound-and-true-p lsp-ui-mode) (bound-and-true-p lsp-ui-sideline-enable))
    (if (and (fboundp 'flycheck-pos-tip-mode)
             (display-graphic-p))
        (flycheck-pos-tip-mode +1)
      (flycheck-popup-tip-mode +1))))

(after! flycheck
  (setq flycheck-global-modes '(not org-mode)
        ;; git-gutter uses left fringe
        flycheck-indication-mode 'right-fringe)
  (map! :mode flycheck-mode
        "C-c ." 'flycheck-next-error
        "C-c ," 'flycheck-previous-error)

  (flycheck-add-mode 'javascript-eslint 'typescript-ts-mode)
  (flycheck-add-mode 'javascript-eslint 'tsx-ts-mode)
  (flycheck-add-mode 'javascript-eslint 'web-mode)

  (after! typescript-ts-mode
    (add-hook! (typescript-ts-mode tsx-ts-mode) '--set-flycheck-eslint))
  (after! web-mode
    (add-hook! web-mode '--set-flycheck-eslint))

  (use-package! flycheck-pos-tip
    :config
    (flycheck-pos-tip-mode 1))

  (use-package! flyover
    :config
    (setq! flyover-levels '(error warning info)
           flyover-levels '()
           flyover-use-theme-colors t
           flyover-background-lightness 40
           flyover-wrap-messages t
           flyover-text-tint-percent 60)
    ;; (add-hook! flycheck-mode 'flyover-mode)
    (setq! flycheck-mode-hook (-remove (lambda (f) (eql f 'flyover-mode)) flycheck-mode-hook))
    )
  (global-flycheck-mode 1))

(after! lsp-semgrep
  (setq! lsp-semgrep-languages (-remove (fn! (-contains? '("docker" "dockerfile" "python" "python2" "python3"
                                                           "js" "javascript" "ts" "typescript") %1))
                                        lsp-semgrep-languages)))

(use-package! expand-region :defer-incrementally t)

(use-package! whitespace
  :commands whitespace-mode
  :init
  (add-hook! (prog-mode text-mode conf-mode) 'whitespace-mode)
  :config
  (setq! whitespace-line-column nil)
  (setq! whitespace-style '(face tabs empty trailing indentation space-after-tab space-before-tab)))

(after! python
  nil)

(use-package! systemd
  :mode (("\\.service\\'" . systemd-mode)
         ("\\.target\\'"  . systemd-mode)))

(use-package! groovy-mode
  :mode "/Jenkinsfile"
  :config
  (setq! groovy-indent-offset 2)
  (setq-hook! groovy-mode tab-width 2))

(after! markdown-mode
  (use-package! gh-md)
  (setq-hook! (gfm-mode markdown-mode) +format-with 'prettier-markdown))

(use-package! nginx-mode
  :mode ("/nginx.conf$" "\\.nginx-site\\'"))

(defun --load-org-notify ()
  (interactive)
  (when (not (featurep 'org-notify))
    (require 'org)
    (add-to-list 'load-path "~/.doom.d/org-notify")
    (require 'org-notify)
    (setq org-notify-interval 600
          org-notify-fade-time 7)))

(after! org
  (require 'doom-themes-ext-org))

(after! vterm
  (setq! ;; vterm-disable-inverse-video t
   vterm-term-environment-variable "xterm-256color"
   ;; vterm-term-environment-variable "eterm-color"
   ))

(after! org
  (setq! org-log-done 'time
         org-agenda-files '("~/org/roam/" "~/org/todo.org")
         org-agenda-timegrid-use-ampm t
         +org-capture-todo-file "roam/20240416233119-current_tasks.org"
         +org-capture-emails-file "roam/20240416233119-current_tasks.org")
  (map! :mode org-mode
        "C-<tab>"        nil
        "C-k"            nil
        "C-j"            nil
        "C-S-<left>"     'org-metaleft
        "C-S-<right>"    'org-metaright
        "C-S-<down>"     'org-metadown
        "C-S-<up>"       'org-metaup
        "C-S-<return>"   'org-meta-return)
  (use-package! org-ql)
  ;; (use-package! org-present)
  ;; (use-package! org-projectile)
  (setq-hook! org-mode
    debug-on-error nil
    debug-on-message nil)
  (after! spell-fu
    (pushnew! spell-fu-ignore-modes 'org-mode)
    (add-hook! org-mode :append (spell-fu-mode -1)))
  (use-package! org-modern
    :config
    (setq! org-modern-todo nil)))

(after! org-roam
  (setq! org-roam-completion-everywhere t
         ;; +org-roam-auto-backlinks-buffer t
         ))

(after! corfu
  (setq! global-corfu-modes '((not) prog-mode)))

(use-package! org-roam-timestamps
  :after org-roam
  :config (org-roam-timestamps-mode))

(use-package! org-pomodoro
  :commands org-pomodoro --org-pomodoro-status-json)

(use-package! pkgbuild-mode :mode "/PKGBUILD")

(use-package! yaml-mode :mode "\\.yml\\'")

(after! clojure-mode
  (use-package clojure-mode
    :mode ("\\.rex\\'"))
  (require 'tramp)
  (use-package! cider)
  (setq clojure-use-backtracking-indent t
        clojure-indent-style 'align-arguments ;; 'always-align
        cider-repl-use-pretty-printing t
        cider-auto-select-error-buffer t
        cider-prompt-for-symbol nil
        cider-save-file-on-load t
        nrepl-use-ssh-fallback-for-remote-hosts t
        ;; cider-preferred-build-tool 'shadow-cljs
        ;; cider-default-cljs-repl 'shadow-select
        cider-shadow-default-options ":dev"
        cider-clojure-cli-aliases ":dev"
        clojure-docstring-fill-column 80
        clojure-align-forms-automatically nil)
  (--each '((cider-clojure-cli-global-options . "-A:dev:test:+default")
            (clojure-indent-style quote always-align)
            (cider-test-defining-forms . ("deftest" "defspec" "deftest-browser" "deftest-etaoin")))
    (add-to-list 'safe-local-variable-values it))
  (map! :mode cider-mode
        "C-c ," 'flycheck-previous-error)
  (after! apheleia
    (pushnew! apheleia-formatters '(zprint "zprint" "{:search-config? true}"))
    (setq-hook! (clojure-mode clojurescript-mode clojurec-mode)
      +format-with-lsp nil
      +format-with 'cljfmt))
  (set-mode-name clojure-mode "CLJ")
  (set-mode-name clojurescript-mode "CLJS")
  (set-mode-name clojurec-mode "CLJC")
  (add-hook! (clojure-mode clojurescript-mode clojurec-mode) 'cider-mode 'apheleia-mode)
  (add-hook! (clojure-mode clojurescript-mode clojurec-mode cider-repl-mode) 'lispy-mode)
  (add-hook! cider-repl-mode 'corfu-mode)
  (setq-hook! (clojure-mode clojurescript-mode clojurec-mode)
    lsp-lens-enable nil)
  (define-key! 'cider-mode-map
    "M-." nil ;; 'cider-find-var
    "C-c C-k" 'cider-load-buffer
    "C-c n" 'cider-repl-set-ns)
  (define-key! 'cider-repl-mode-map
    "M-." nil)
  ;; (use-package! flycheck-clojure
  ;;   :config (flycheck-clojure-setup))
  ;; (use-package! flycheck-clj-kondo)
  ;; (use-package! clj-refactor
  ;;   :config
  ;;   (setq cljr-warn-on-eval t
  ;;         cljr-suppress-middleware-warnings nil))
  (defun --cider-reload-repl-ns ()
    (let ((ns (buffer-local-value 'cider-buffer-ns (car (cider-repls)))))
      (when ns
        (cider-nrepl-request:eval (format "(require '%s :reload)" ns)
                                  (lambda (_response) nil)))))
  (add-hook 'cider-file-loaded-hook '--cider-reload-repl-ns)
  (defun --override-clojure-capf ()
    (setq-local completion-at-point-functions
                (list #'cider-complete-at-point
                      #'lsp-completion-at-point
                      #'lispy-clojure-complete-at-point)))
  (add-hook! (clojure-mode clojure-ts-mode cider-mode) :append '--override-clojure-capf))



(use-package! less-css-mode
  :mode ("\\.less\\'"
         "\\.variables\\'"
         "\\.overrides\\'")
  :config (add-hook! less-css-mode 'rainbow-mode))

(use-package! jade-mode
  :mode "\\.jade\\'")

;; Make sure Emacs has the correct ssh-agent config,
;; in order to use tramp and git commands without requesting a password.
(unless (mac?)
  (if (equal (user-login-name) "root")
      (setenv "SSH_AUTH_SOCK" "/run/ssh-agent.socket")
    (setenv "SSH_AUTH_SOCK" (concat (getenv "XDG_RUNTIME_DIR") "/ssh-agent.socket"))))

;; Run server inside GUI process on MacOS
(when (gui-mac?)
  (require 'server)
  (when (null server-process)
    (server-start t t)))

(after! apheleia
  (setq-default +format-with nil)
  (setq! +format-with-lsp t
         +format-on-save-disabled-modes '(sql-mode
                                          tex-mode
                                          latex-mode
                                          org-msg-edit-mode)))

(after! editorconfig
  (setq! editorconfig-lisp-use-default-indent t))

;; workaround for buggy display of this
(defun --lsp-ui-doc-glance-toggle ()
  (interactive)
  (if (lsp-ui-doc--frame-visible-p)
      (lsp-ui-doc--delete-frame)
    (lsp-ui-doc-glance)))

(defun lsp-booster--advice-json-parse (old-fn &rest args)
  "Try to parse bytecode instead of json."
  (or
   (when (equal (following-char) ?#)
     (let ((bytecode (read (current-buffer))))
       (when (byte-code-function-p bytecode)
         (funcall bytecode))))
   (apply old-fn args)))

(after! lsp-mode
  (advice-add (if (progn (require 'json)
                         (fboundp 'json-parse-buffer))
                  'json-parse-buffer
                'json-read)
              :around
              #'lsp-booster--advice-json-parse))

(defun lsp-booster--advice-final-command (old-fn cmd &optional test?)
  "Prepend emacs-lsp-booster command to lsp CMD."
  (let ((orig-result (funcall old-fn cmd test?)))
    (if (and (not test?)                             ;; for check lsp-server-present?
             (not (file-remote-p default-directory)) ;; see lsp-resolve-final-command, it would add extra shell wrapper
             lsp-use-plists
             (not (functionp 'json-rpc-connection))  ;; native json-rpc
             (executable-find "emacs-lsp-booster"))
        (progn
          (when-let ((command-from-exec-path (executable-find (car orig-result))))  ;; resolve command from exec-path (in case not found in $PATH)
            (setcar orig-result command-from-exec-path))
          (message "Using emacs-lsp-booster for %s!" orig-result)
          (cons "emacs-lsp-booster" orig-result))
      orig-result)))

(after! lsp-mode
  (advice-add 'lsp-resolve-final-command :around #'lsp-booster--advice-final-command))

(after! lsp-mode
  (setq! lsp-idle-delay 0.25
         lsp-ui-doc-max-width 100
         lsp-ui-doc-max-height 16
         lsp-ui-doc-use-webkit nil
         lsp-auto-guess-root t
         lsp-guess-root-without-session t
         lsp-warn-no-matched-clients nil
         lsp-ui-doc-include-signature t
         lsp-ui-sideline-enable nil
         lsp-inlay-hint-enable t)
  (pushnew! lsp-file-watch-ignored-directories "/home/jeff/repos/nix/nixpkgs" "/nix/store")
  (pushnew! lsp-disabled-clients 'semgrep-ls)
  (require 'lsp-ui)
  (require 'lsp-ui-doc)
  (map! :mode lsp-mode
        "s-l" '--lsp-ui-doc-glance-toggle
        ;; "s-L" (cmd! (lsp-ui-doc--delete-frame) (command-execute 'lsp-ui-doc-glance))
        "s-;" 'lsp-ui-doc-focus-frame
        "s-:" 'lsp-ui-doc-focus-frame
        :mode lsp-ui-doc-frame-mode
        "s-l" 'lsp-ui-doc-hide
        "s-;" 'lsp-ui-doc-unfocus-frame
        "s-:" 'lsp-ui-doc-unfocus-frame
        :leader
        "l" '--lsp-ui-doc-glance-toggle
        "L" 'lsp-avy-lens
        "'" 'lsp-ui-doc-focus-frame
        "RET" 'lsp-inlay-hints-mode))

(after! lsp-treemacs
  (setq! lsp-treemacs-error-list-current-project-only t))

(after! rustic
  (after! lsp-rust
    (setq! lsp-rust-analyzer-server-format-inlay-hints t
           lsp-rust-analyzer-display-chaining-hints t
           lsp-rust-analyzer-display-parameter-hints t
           lsp-rust-analyzer-max-inlay-hint-length 25
           lsp-rust-analyzer-diagnostics-disabled ["inactive-code"]))
  (after! apheleia
    (dolist (mode '(rust-mode rust-ts-mode rustic-mode))
      (setf (alist-get mode apheleia-mode-alist) 'lsp))))

(after! nix-mode
  (after! lsp-mode
    (defcustom-lsp lsp-nix-nil-auto-archive nil
      "Auto-archiving behavior which may use network."
      :type 'lsp-json-bool
      :group 'lsp-nix-nil
      :lsp-path "nil.nix.flake.autoArchive"
      :package-version '(lsp-mode . "8.0.1"))
    (defcustom-lsp lsp-nix-nil-auto-eval-inputs nil
      "Whether to auto-eval flake inputs.
      The evaluation result is used to improve completion, but may cost lots of time and/or memory."
      :type 'boolean
      :group 'lsp-nix-nil
      :lsp-path "nil.nix.flake.autoEvalInputs"
      :package-version '(lsp-mode . "8.0.1"))
    (defcustom-lsp lsp-nix-nil-nixpkgs-input-name nil
      "The input name of nixpkgs for NixOS options evaluation.
      The options hierarchy is used to improve completion, but may cost lots of time and/or memory.
      If this value is `null` or is not found in the workspace flake's inputs, NixOS options are not evaluated."
      :type 'string
      :group 'lsp-nix-nil
      :lsp-path "nil.nix.flake.nixpkgsInputName"
      :package-version '(lsp-mode . "8.0.1"))
    (setq! lsp-nix-rnix-server-path nil
           ;; lsp-nix-nil-server-path "nil"
           lsp-nix-nil-server-path nil
           lsp-nix-nil-formatter ["nixfmt" "-w" "80"]
           lsp-nix-nil-auto-archive t
           lsp-nix-nil-auto-eval-inputs nil
           lsp-nix-nil-nixpkgs-input-name "nixpkgs"
           lsp-nix-nixd-server-path "nixd")
    (setq-hook! nix-mode-hook +format-with-lsp t)))

(use-package! vimrc-mode
  :mode "\\.vim\\(rc\\)?\\'")

(defun --cider-load-buffer-reload-repl (&optional buffer)
  (interactive)
  (cider-load-buffer buffer)
  (--cider-reload-repl-ns)
  nil)

(defun all-sesman-sessions ()
  (sesman-sessions (sesman--system) t))

(defun test-buffer-name (buf regexp &optional exclude-regexp)
  (and (string-match regexp (buffer-name buf))
       (if (null exclude-regexp) t
         (not (string-match exclude-regexp (buffer-name buf))))))

(defun match-buffer-name (regexp &optional exclude-regexp)
  (->> (buffer-list)
       (--filter (test-buffer-name it regexp exclude-regexp))))

(defun match-sesman-session (regexp &optional exclude-regexp)
  (->> (all-sesman-sessions)
       (--remove (not (test-buffer-name (cl-second it) regexp exclude-regexp)))
       (-first-item)))

(defun --cider-quit-all ()
  (interactive)
  (dolist (buf (match-buffer-name "\*cider-repl\ .*"))
    (save-excursion
      (switch-to-buffer buf)
      (cider-quit))))

(defun --benchmark-sysrev ()
  (interactive)
  (cl-flet ((quit-all ()
              (--cider-quit-all)
              (save-excursion
                (find-file "~/code/sysrev/project.clj")
                (dolist (b (projectile-project-buffers))
                  (kill-buffer b)))))
    (quit-all)
    (with-delay 0.1 (garbage-collect))
    (with-delay 0.25 (sysrev))
    (with-delay 2.5 (quit-all))))

(defun --cider-repl-p (b)
  (eql 'cider-repl-mode (with-current-buffer b major-mode)))

(defun --cider-repl-cljs-p (b)
  (and (--cider-repl-p b)
       (not (null (string-match ".*cljs.*" (buffer-name b))))))

(defun --cider-repl-buffers ()
  (cl-remove-if-not '--cider-repl-p (buffer-list)))

(defun --cider-next-repl (current-repl)
  (->> (--cider-repl-buffers)
       (cl-remove-if (lambda (b) (equal (buffer-name b)
                                        (buffer-name current-repl))))
       (car)))

(defun --cider-goto-repl ()
  (interactive)
  (cond ((--cider-repl-p (current-buffer))
         (when-let ((b (--cider-next-repl (current-buffer))))
           (switch-to-buffer b)))
        (t
         (when-let ((b (--cider-next-repl (current-buffer))))
           (switch-to-buffer-other-window b)))))

(after! minimap
  (setq minimap-update-delay 0.1
        minimap-minimum-width 20
        minimap-width-fraction 0.15
        minimap-always-recenter nil)
  (after! ace-window
    (add-to-list 'aw-ignored-buffers "*MINIMAP*")))

(defun --ensure-treemacs-hl-line-mode (&rest _)
  (-when-let (window (treemacs-get-local-window))
    (with-current-buffer (window-buffer window)
      (unless (buffer-local-value 'hl-line-mode (window-buffer))
        (hl-line-mode 1)))))

(defun --treemacs-variable-pitch (&rest _)
  (dolist (face '(treemacs-root-face
                  treemacs-git-unmodified-face
                  treemacs-git-modified-face
                  treemacs-git-renamed-face
                  treemacs-git-ignored-face
                  treemacs-git-untracked-face
                  treemacs-git-added-face
                  treemacs-git-conflict-face
                  treemacs-directory-face
                  treemacs-directory-collapsed-face
                  treemacs-file-face
                  treemacs-tags-face))
    (let ((faces (face-attribute face :inherit nil)))
      (set-face-attribute
       face nil :inherit
       `(variable-pitch
         ,@(delq 'unspecified (if (listp faces) faces (list faces))))))))

(defun --treemacs-hide-fringes (&rest _)
  (-when-let (window (treemacs-get-local-window))
    (with-current-buffer (window-buffer window)
      ;; ensure fringe-indicator-mode is enabled
      (unless (eq (buffer-local-value 'treemacs-fringe-indicator-mode (current-buffer)) 'always)
        (treemacs-fringe-indicator-mode 'always))
      ;; disable right fringe
      (set-window-fringes window nil 0))))

(setq! +treemacs-git-mode 'deferred)

(after! treemacs
  (setq! treemacs-display-in-side-window t
         treemacs-file-event-delay 1000
         treemacs-silent-filewatch t
         treemacs-silent-refresh t
         treemacs-indentation '(4 px)
         treemacs-is-never-other-window t
         treemacs-show-cursor nil)
  (require 'hide-mode-line)
  (setq-hook! treemacs-mode mode-line-format nil)
  (setq-hook! treemacs-mode tab-width 1)
  (add-hook! treemacs-mode 'hide-mode-line-mode)
  (--treemacs-variable-pitch)
  (add-hook! 'doom-load-theme-hook :append '--treemacs-variable-pitch)
  (after! (lsp-treemacs solaire-mode)
    (pushnew! solaire-mode-remap-alist
              '(treemacs-window-background-face . solaire-default-face))
    (pushnew! solaire-mode-remap-alist
              '(treemacs-hl-line-face . solaire-hl-line-face))
    (add-hook! lsp-treemacs-error-list-mode 'solaire-mode))
  (treemacs-git-mode 1)
  (treemacs-follow-mode 1)
  (treemacs-project-follow-mode 1)
  (treemacs-filewatch-mode 1)
  (treemacs-hide-gitignored-files-mode 1)
  (map! :mode treemacs-mode
        "C-o" (cmd! (call-interactively 'other-window))))

(defmacro --setup-js-prettier-modes (feature-modes extra-modes)
  "Configure modes that are auto-formatted by external `prettier` tool."
  (let* ((features feature-modes)
         (modes `(,@feature-modes ,@extra-modes))
         (forms (-mapcat (lambda (mode)
                           (list `(setq-mode-local ,mode +format-with-lsp nil)))
                         modes)))
    `(after! lsp-mode
       (-each ',features 'require)
       (after! ,features ,@forms)
       ',modes)))

(--setup-js-prettier-modes
 (web-mode
  typescript-ts-mode
  json-mode
  json-ts-mode)
 (typescript-tsx-mode tsx-ts-mode))

(use-package! css-mode
  :mode "\\.postcss\\'" "\\.css\\'"
  :config
  (add-hook! css-ts-mode 'lsp-mode)
  (setq-hook! css-ts-mode +format-with 'prettier-css))

(use-package! typescript-ts-mode
  :mode "\\.ts\\'" "\\.js\\'" "\\.cjs\\'"
  :config
  (add-hook! (typescript-ts-mode tsx-ts-mode) 'lsp-mode))

(use-package! typescript-tsx-mode
  :mode "\\.tsx\\'"
  :config
  (use-package! typescript-ts-mode)
  (add-hook! typescript-tsx-mode 'tsx-ts-mode))

(use-package! json-ts-mode
  :mode "\\.json\\'" "/.prettierrc$"
  :config
  (add-hook! json-ts-mode 'lsp-mode))

(defun --web-mode-hook ()
  (when (equal web-mode-engine "svelte")
    (setq-local +format-with 'prettier-svelte)))

(after! web-mode
  (add-hook! web-mode '--web-mode-hook))

(use-package! lsp-tailwindcss
  :init
  (setq! lsp-tailwindcss-add-on-mode t)
  :config
  ;; (pushnew! lsp-disabled-clients 'tailwindcss)
  ;; (setq! lsp-disabled-clients (-remove-item 'tailwindcss lsp-disabled-clients))
  (after! clojure-mode
    (setq-hook! (clojure-mode clojurec-mode)
      lsp-tailwindcss-experimental-class-regex ["\"([^\"]*)\""]))
  (--each '(css-mode
            css-ts-mode
            scss-mode
            less-css-mode
            typescript-ts-mode
            tsx-ts-mode)
    (pushnew! lsp-tailwindcss-major-modes it)))

(after! lsp-css
  (setq! lsp-css-lint-unknown-at-rules "ignore"
         lsp-svelte-plugin-css-diagnostics-enable nil))

(defvar --default-server-name "server")

(defun --default-session-file-path (&optional session-name)
  (concat doom-data-dir
          "workspaces/default-session"
          (unless (or (null session-name)
                      (equal session-name --default-server-name))
            (concat "." session-name))))

(defun --restore-default-session (session-name)
  "Runs `doom/load-session' using default session file for `session-name'."
  (interactive)
  (doom/load-session (--default-session-file-path session-name)))

(defvar --server-initialized nil)

(defun --ensure-server-initialized ()
  (when server-process
    (unless --server-initialized
      (when (equal server-name "server")
        (message (format "<%s> | Setting up emacs environment ... " server-name))
        (--restore-default-session server-name)
        (message (format "<%s> | Emacs server is ready" server-name)))
      (setq --server-initialized t))))

(add-hook! 'server-after-make-frame-hook '--ensure-server-initialized)

;; Session can be restored with buffers configured to use
;; 'git-gutter-mode instead of 'git-gutter-fringe-mode.
;; This restarts git-gutter-mode for all buffers
;; upon opening a graphical frame.
;;(add-hook! 'server-after-make-frame-hook '--fix-git-gutter-buffers)

;;;;; Local Variables:
;; byte-compile-warnings: (not free-vars constants mutate-constant docstring unresolved)
;; End:
