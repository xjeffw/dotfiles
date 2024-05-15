;; -*- no-byte-compile: t; -*-
;;; $DOOMDIR/packages.el

(package! consult :pin "c0d8a12bce2568298ff9bcfec1c6cb5e68ca0b61")

(package! aggressive-indent)
(package! alert)
;; (package! cider
;;   :recipe (:host github :repo "clojure-emacs/cider")
;;   :pin "6e5294624959736c486f7a466bd5e78ce6183ab9")
;; (package! clj-refactor
;;   :recipe (:host github :repo "clojure-emacs/clj-refactor.el")
;;   :pin "b476345c580ae7cbc6b356ba0157db782684c47f")
;; (package! clojure-mode
;;   :recipe (:host github :repo "clojure-emacs/clojure-mode")
;;   :pin "481ca480e8b7b6c90881f8bd8434addab1d33778")
(package! catppuccin-theme)
(package! centered-window)
(package! shell-maker :recipe
  (:host github :repo "xenodium/chatgpt-shell" :files ("shell-maker.el")))
(package! chatgpt-shell :recipe
  (:host github :repo "xenodium/chatgpt-shell" :files ("chatgpt-shell.el")))
(package! copilot :recipe
  (:host github :repo "copilot-emacs/copilot.el" :files ("*.el" "dist")))
;; (package! deferred)
(package! disable-mouse)
(package! elsa :recipe (:host github :repo "emacs-elsa/Elsa"))
(package! elisp-slime-nav :built-in 'prefer)
(package! emacsql)
(package! eshell-prompt-extras)
(package! eterm-256color)
(package! evil-lisp-state)
(package! evil-matchit)
(package! evil-smartparens)
(package! flycheck-clojure)
(package! flycheck-pos-tip)
(package! gh-md)
(package! git-link)
(package! git-messenger)
(package! goto-chg)
(package! groovy-mode)
(package! gscholar-bibtex)
;;(package! ligature)
(package! lsp-tailwindcss :recipe (:host github :repo "merrickluo/lsp-tailwindcss"))
(package! nameless)
(package! nginx-mode)
;;(package! nix-buffer :built-in 'prefer)
;;(package! nix-sandbox :built-in 'prefer)
;;(package! nix-update :built-in 'prefer)
(package! org-fancy-priorities)
;; (package! org-pomodoro)
;; (package! org-present)
;; (package! org-projectile)
(package! org-ql)
(package! org-ref)
;; (package! org-roam)
(package! org-roam-bibtex)
(package! org-roam-ui)
(package! org-roam-ql)
(package! org-roam-ql-ql)
(package! org-roam-timestamps)
(package! org-super-agenda)
(package! paradox)
(package! paren-face)
(package! pkgbuild-mode)
(package! rainbow-mode)
(package! shut-up)
;; (package! swiper)
(package! systemd)
(package! vimrc-mode)
(package! volatile-highlights)
(package! whitespace)
(package! yaml-mode)
