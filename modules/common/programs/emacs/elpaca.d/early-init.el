;;; early-init.el --- Emacs pre package.el & GUI configuration -*- lexical-binding: t; -*-

(setq package-enable-at-startup nil)
(setq inhibit-default-init nil)

(setq native-comp-async-report-warnings-errors nil)

;; Garbage Collection
(setq gc-cons-threshold most-positive-fixnum
      gc-cons-percentage 1)

(defun +reset-init-values ()
  (run-with-idle-timer
   1 nil
   (lambda ()
     (setq gc-cons-percentage 0.1
           gc-cons-threshold 100000000)
     (message "gc-cons-threshold restored"))))

(with-eval-after-load 'elpaca
  (add-hook 'elpaca-after-init-hook '+reset-init-values))

;; UI
(push '(menu-bar-lines . 0) default-frame-alist)
(push '(tool-bar-lines . 0) default-frame-alist)
(push '(vertical-scroll-bars) default-frame-alist)
(setq frame-inhibit-implied-resize t)

(setq server-client-instructions nil)

;; Fonts
(push '(font . "JetBrainsMono Nerd Font") default-frame-alist)
(set-face-font 'default "JetBrainsMono Nerd Font")
(set-face-font 'variable-pitch "Inter")
(copy-face 'default 'fixed-pitch)

(advice-add #'x-apply-session-resources :override #'ignore)

(setq ring-bell-function #'ignore
      inhibit-startup-screen t)

(provide 'early-init)
