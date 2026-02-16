;; -*- lexical-binding: t; -*-

(require 'use-package)

(use-package org
  :ensure (:autoloads "org-loaddefs.el")
  :defer t
  :general
  ;;<tab> is for GUI only. TAB maps to C-i on terminals.
  (+general-global-application
    "o"   '(:ignore t :which-key "org")
    "oc"  'org-capture
    "oC"  '+org-capture-again
    "oi"  'org-insert-link
    "oj"  'org-chronicle
    "ok"  '(:ignore t :which-key "clock")
    "okg" 'org-clock-goto
    "oki" 'org-clock-in-last
    "okj" 'org-clock-jump-to-current-clock
    "oko" 'org-clock-out
    "okr" 'org-resolve-clocks
    "ol"  'org-store-link
    "om"  'org-tags-view
    "os"  'org-search-view
    "oT"  'org-todo-list
    "ot"  '(:ignore t :which-key "timer")
    "ott" 'org-timer
    "otS" 'org-timer-stop
    "otC" 'org-timer-change-times-in-region
    "otc" 'org-timer-set-timer
    "ots" 'org-timer-start
    "oti" 'org-timer-item
    "otp" 'org-timer-pause-or-continue
    "otr" 'org-timer-show-remaining-time)
  :config
  (general-define-key :states '(normal) :keymaps 'org-mode-map
                      (kbd "<tab>") 'org-cycle
                      (kbd "<backtab>") 'org-shifttab)
  (general-define-key :states '(normal insert) :keymaps 'org-mode-map
                      (kbd "M-l") 'org-metaright
                      (kbd "M-h") 'org-metaleft
                      (kbd "M-k") 'org-metaup
                      (kbd "M-j") 'org-metadown
                      (kbd "M-L") 'org-shiftmetaright
                      (kbd "M-H") 'org-shiftmetaleft
                      (kbd "M-K") 'org-shiftmetaup
                      (kbd "M-J") 'org-shiftmetadown)
  (general-define-key :states  '(motion) :keymaps 'org-mode-map
                      (kbd "RET") 'org-open-at-point)
  (global-leader
    ;;for terminals
    :keymaps '(org-mode-map)
    "TAB" 'org-cycle
    "."  'org-time-stamp
    "!"  'org-time-stamp-inactive
    "<"  'org-date-from-calendar
    ">"  'org-goto-calendar

    "C"  '(:ignore t :which-key "clock")
    "Cc" 'org-clock-cancel
    "Ci" 'org-clock-in
    "Co" 'org-clock-out
    "Cr" 'org-clock-report
    "CR" 'org-resolve-clocks

    "d"  '(:ignore t :which-key "dates")
    "dd" 'org-deadline
    "df" '((lambda () (interactive) (+org-fix-close-times))
           :which-key "org-fix-close-time")
    "ds" 'org-schedule
    "di" 'org-time-stamp-inactive
    "dt" 'org-time-stamp

    "e"   '(:ignore t :which-key "export")
    "ee"  'org-export-dispatch

    "h"   '(:ignore t :which-key "heading")
    "hf"  'org-forward-heading-same-level
    "hb"  'org-backward-heading-same-level

    "i"  '(:ignore t :which-key "insert")
    "id" 'org-insert-drawer
    "ie" 'org-set-effort
    "if" 'org-footnote-new
    "iH" 'org-insert-heading-after-current
    "ih" 'org-insert-heading
    "ii" 'org-insert-item
    "il" 'org-insert-link
    "in" 'org-add-note
    "ip" 'org-set-property
    "is" 'org-insert-structure-template
    "it" 'org-set-tags-command

    "n"  '(:ignore t :which-key "narrow")
    "nb" 'org-narrow-to-block
    "ne" 'org-narrow-to-element
    "ns" 'org-narrow-to-subtree
    "nt" 'org-toggle-narrow-to-subtree
    "nw" 'widen

    "s"  '(:ignore t :which-key "trees/subtrees")
    "sA" 'org-archive-subtree
    "sa" 'org-toggle-archive-tag
    "sb" 'org-tree-to-indirect-buffer
    "sc" 'org-cut-subtree
    "sh" 'org-promote-subtree
    "sj" 'org-move-subtree-down
    "sk" 'org-move-subtree-up
    "sl" 'org-demote-subtree
    "sp" '(:ignore t :which-key "priority")
    "spu" 'org-priority-up
    "spd" 'org-priority-down
    "sps" 'org-priority-show
    "sm" 'org-match-sparse-tree
    "sn" 'org-toggle-narrow-to-subtree
    "sr" 'org-refile
    "sS" 'org-sort
    "ss" '+org-sparse-tree

    "t"   '(:ignore t :which-key "tables")
    "ta"  'org-table-align
    "tb"  'org-table-blank-field
    "tc"  'org-table-convert

    "td"  '(:ignore t :which-key "delete")
    "tdc" 'org-table-delete-column
    "tdr" 'org-table-kill-row
    "tE"  'org-table-export
    "te"  'org-table-eval-formula
    "tH"  'org-table-move-column-left
    "th"  'org-table-previous-field
    "tI"  'org-table-import

    "ti"  '(:ignore t :which-key "insert")
    "tic" 'org-table-insert-column
    "tih" 'org-table-insert-hline
    "tiH" 'org-table-hline-and-move
    "tir" 'org-table-insert-row
    "tJ"  'org-table-move-row-down
    "tj"  'org-table-next-row
    "tK"  'org-table-move-row-up
    "tL"  'org-table-move-column-right
    "tl"  'org-table-next-field
    "tN"  'org-table-create-with-table.el
    "tn"  'org-table-create
    "tp"  'org-plot/gnuplot
    "tr"  'org-table-recalculate
    "ts"  'org-table-sort-lines

    "tt"  '(:ignore t :which-key "toggle")
    "ttf" 'org-table-toggle-formula-debugger
    "tto" 'org-table-toggle-coordinate-overlays
    "tw"  'org-table-wrap-region

    "T"  '(:ignore t :which-key "toggle")
    "Tc"  'org-toggle-checkbox
    "Te"  'org-toggle-pretty-entities
    "TE"  '+org-toggle-hide-emphasis-markers
    "Th"  'org-toggle-heading
    "Ti"  'org-toggle-item
    "TI"  'org-toggle-inline-images
    "Tl"  'org-toggle-link-display
    "TT"  'org-todo
    "Tt"  'org-show-todo-tree
    "Tx"  'org-latex-preview
    "RET" 'org-ctrl-c-ret
    "#"   'org-update-statistics-cookies
    "'"   'org-edit-special
    "*"   'org-ctrl-c-star
    "-"   'org-ctrl-c-minus
    "A"   'org-attach)
  (defun +org-sparse-tree (&optional arg type)
    (interactive)
    (funcall #'org-sparse-tree arg type)
    (org-remove-occur-highlights))

  (defun +insert-heading-advice (&rest _args)
    "Enter insert mode after org-insert-heading. Useful so I can tab to control level of inserted heading."
    (when evil-mode (evil-insert 1)))

  (advice-add #'org-insert-heading :after #'+insert-heading-advice)

  (defun +org-update-cookies ()
    (interactive)
    (org-update-statistics-cookies "ALL"))

  ;; Offered a patch to fix this upstream. Too much bikeshedding for such a simple fix.
  (defun +org-tags-crm (fn &rest args)
    "Workaround for bug which excludes \",\" when reading tags via `completing-read-multiple'.
  I offered a patch to fix this, but it was met with too much resistance to be
  worth pursuing."
    (let ((crm-separator "\\(?:[[:space:]]*[,:][[:space:]]*\\)"))
      (unwind-protect (apply fn args)
        (advice-remove #'completing-read-multiple #'+org-tags-crm))))

  (define-advice org-set-tags-command (:around (fn &rest args) comma-for-crm)
    (advice-add #'completing-read-multiple :around #'+org-tags-crm)
    (apply fn args))
  :custom
  ;;default:
  ;;(org-w3m org-bbdb org-bibtex org-docview org-gnus org-info org-irc org-mhe org-rmail)
  ;;org-toc is interesting, but I'm not sure if I need it.
  (org-modules '(org-habit))
  (org-todo-keywords
   '((sequence  "TODO(t)" "STARTED(s!)" "NEXT(n!)" "BLOCKED(b@/!)" "|" "DONE(d)")
     (sequence  "IDEA(i)" "|" "CANCELED(c@/!)" "DELEGATED(D@/!)")
     (sequence  "RESEARCH(r)" "|"))
   ;;move to theme?
   org-todo-keyword-faces
   `(("CANCELED" . (:foreground "IndianRed1" :weight bold))
     ("TODO" . (:foreground "#ffddaa"
                :weight bold
                :background "#202020"
                :box (:line-width 3 :width -2 :style released-button)))))
  (org-ellipsis (nth 5 '("↴" "˅" "…" " ⬙" " ▽" "▿")))
  (org-priority-lowest ?D)
  (org-fontify-done-headline t)
  (org-M-RET-may-split-line nil "Don't split current line when creating new heading"))

(use-feature org-agenda
  :after (general evil)
  :config
  (defun +org-agenda-archives (&optional arg)
    "Toggle `org-agenda-archives-mode' so that it includes archive files by default.
  Inverts normal logic of ARG."
    (interactive "P")
    (let ((current-prefix-arg (unless (or org-agenda-archives-mode arg) '(4))))
      (call-interactively #'org-agenda-archives-mode)))

  (defun +org-agenda-place-point ()
    "Place point on first agenda item."
    (goto-char (point-min))
    (org-agenda-find-same-or-today-or-agenda))

  (add-hook 'org-agenda-finalize-hook #'+org-agenda-place-point 90)
  (global-leader :keymaps 'org-mode-map "a" 'org-agenda)
  :general
  (+general-global-application
    "o#"   'org-agenda-list-stuck-projects
    "o/"   'org-occur-in-agenda-files
    "oa"   '((lambda () (interactive) (org-agenda nil "a")) :which-key "agenda")
    "oe"   'org-store-agenda-views
    "oo"   'org-agenda)
  (with-eval-after-load 'org-agenda
    (evil-make-intercept-map org-agenda-mode-map)
    (general-define-key
     :keymaps 'org-agenda-mode-map
     ;;:states '(emacs normal motion)
     "A"     '+org-agenda-archives
     "C"     'org-agenda-clockreport-mode
     "D"     'org-agenda-goto-date
     "E"     'epoch-agenda-todo
     "H"     'org-habit-toggle-habits
     "J"     'org-agenda-next-item
     "K"     'org-agenda-previous-item
     "R"     'org-agenda-refile
     "S"     'org-agenda-schedule
     "RET"   'org-agenda-recenter
     "a"     '+org-capture-again
     "c"     'org-agenda-capture
     "j"     'org-agenda-next-line
     "k"     'org-agenda-previous-line
     "m"     'org-agenda-month-view
     "t"     'org-agenda-set-tags
     "T"     'org-agenda-todo
     "u"     'org-agenda-undo))
  :config
  (evil-set-initial-state 'org-agenda-mode 'normal)

  (defun +org-agenda-redo-all ()
    "Rebuild all agenda buffers"
    (interactive)
    (dolist (buffer (buffer-list))
      (with-current-buffer buffer
        (when (derived-mode-p 'org-agenda-mode)
          (org-agenda-maybe-redo)))))

  (add-hook 'org-mode-hook
            (lambda ()
              (add-hook 'after-save-hook '+org-agenda-redo-all nil t))))

(use-feature ob-tangle
  :after (org)
  :custom
  (org-src-window-setup 'current-window)
  (org-src-preserve-indentation t)
  :general
  (global-leader :keymaps 'org-mode-map
    "b"   '(:ignore t :which-key "babel")
    "bt"  'org-babel-tangle
    "bT"  'org-babel-tangle-file
    "be"  '(:ignore t :which-key "execute")
    "beb" 'org-babel-execute-buffer
    "bes" 'org-babel-execute-subtree)
  :config
  (dolist (template '(("f" . "src fountain")
                      ("se" . "src emacs-lisp :lexical t")
                      ("ss" . "src shell")
                      ("sj" . "src javascript")))
    (add-to-list 'org-structure-template-alist template))
  (use-feature ob-js
    :commands (org-babel-execute:js))
  (use-feature ob-python
    :commands (org-babel-execute:python))
  (use-feature ob-shell
    :commands (org-babel-execute:bash
               org-babel-execute:shell
               org-babel-expand-body:generic)
    :config (add-to-list 'org-babel-load-languages '(shell . t))
    (org-babel-do-load-languages 'org-babel-load-languages org-babel-load-languages)))

(use-feature org-capture
  :config
  (define-advice org-capture-fill-template (:around (fn &rest args) comma-for-crm)
    (advice-add #'completing-read-multiple :around #'+org-tags-crm)
    (apply fn args))
  (add-hook 'org-capture-mode-hook #'evil-insert-state)
  (defun +org-schedule-relative-to-deadline ()
    "For use with my appointment capture template. User is first prompted for an
  optional deadline. Then an optional schedule time. The scheduled default time is
  the deadline. This makes it easier to schedule relative to the deadline using
  the -- or ++ operators.

  Quitting during either date prompt results in an empty string for that prompt."
    (interactive)
    (condition-case nil
        (org-deadline nil)
      (quit nil))
    (let ((org-overriding-default-time (or (org-get-deadline-time (point))
                                           org-overriding-default-time)))
      (org-schedule nil (org-element-interpret-data
                         (org-timestamp-from-time
                          org-overriding-default-time
                          (and org-overriding-default-time 'with-time))))
      (let ((org-log-reschedule nil))
        (condition-case nil
            (org-schedule nil)
          (quit (org-schedule '(4)))))))

  (defun +org-capture-again (&optional arg)
    "Call `org-capture' with last selected template.
  Pass ARG to `org-capture'.
  If there is no previous template, call `org-capture'."
    (interactive "P")
    (org-capture arg (plist-get org-capture-plist :key)))

  (defun +org-capture-here ()
    "Convenience command to insert a template at point"
    (interactive)
    (org-capture 0))

  (defun +org-capture-property-drawer ()
    "Hook function run durning `org-capture-mode-hook'.
  If a template has a :properties keyword, add them to the entry."
    (when (eq (org-capture-get :type 'local) 'entry)
      (when-let* ((properties (doct-get :properties t)))
        (dolist (property properties)
          (org-set-property
           (symbol-name (car property))
           (replace-regexp-in-string
            "\n.*" ""
            (org-capture-fill-template
             (doct--replace-template-strings (cadr property)))))))))

  (defun +org-capture-todo ()
    "Set capture entry to TODO automatically"
    (org-todo "TODO"))

  (setq org-capture-templates
        (doct `(("Bookmark"
                 :keys "b"
                 :hook +org-capture-property-drawer
                 :id "7c20c705-80a3-4f5a-9181-2ea14a18fa75"
                 :properties ((Created "%U"))
                 :template ("* [[%x][%^{title}]] %^g" "%?"))
                ("Note"
                 :keys "n"
                 :file ,(defun +org-capture-repo-note-file ()
                          "Find note for current repository."
                          (require 'projectile)
                          (let* ((coding-system-for-write 'utf-8)
                                 ;;@MAYBE: extract this to a global variable.
                                 (notedir "~/Documents/devops/repo-notes/")
                                 (project-root (projectile-project-root))
                                 (name (concat (file-name-base (directory-file-name project-root)) ".org"))
                                 (path (expand-file-name name (file-truename notedir))))
                            (with-current-buffer (find-file-noselect path)
                              (unless (derived-mode-p 'org-mode) (org-mode)
                                      ;;set to utf-8 because we may be visiting raw file
                                      (setq buffer-file-coding-system 'utf-8-unix))
                              (when-let* ((headline (doct-get :headline)))
                                (unless (org-find-exact-headline-in-buffer headline)
                                  (goto-char (point-max))
                                  (insert "* " headline)
                                  (org-set-tags (downcase headline))))
                              (unless (file-exists-p path) (write-file path))
                              path)))
                 :template (lambda () (concat  "* %{todo-state} " (when (y-or-n-p "Link? ") "%A\n") "%?"))
                 :todo-state "TODO"
                 :children (("bug" :keys "b" :headline "Bug")
                            ("design"        :keys "d" :headline "Design")
                            ("documentation" :keys "D" :headline "Documentation")
                            ("enhancement"   :keys "e" :headline "Enhancement" :todo-state "IDEA")
                            ("feature"       :keys "f" :headline "Feature"     :todo-state "IDEA")
                            ("optimization"  :keys "o" :headline "Optimization")
                            ("miscellaneous" :keys "m" :headline "Miscellaneous")
                            ("security"      :keys "s" :headline "Security")))
                ("Todo" :keys "t"
                 :id "0aeb95eb-25ee-44de-9ef5-2698514f6208"
                 :hook (lambda ()
                         (+org-capture-property-drawer)
                         ;;swallow org-todo quit so we don't abort the whole capture
                         (condition-case nil (org-todo) (quit nil)))
                 :properties ((Created "%U"))
                 :template ("* %^{description} %^g" "%?"))
                ("use-package" :keys "u"
                 :file ,(expand-file-name "init.org" user-emacs-directory)
                 :function
                 ,(defun +org-capture-use-package-form ()
                    "place point for use-package capture template."
                    (org-fold-show-all)
                    (goto-char (org-find-entry-with-id "f8affafe-3a4c-490c-a066-006aeb76f628"))
                    (org-narrow-to-subtree)
                    ;;popping off parent headline, evil and general.el since they are order dependent.
                    (when-let* ((name (read-string "package name: "))
                                (headlines (nthcdr 4 (caddr (org-element-parse-buffer 'headline 'visible))))
                                (packages (mapcar (lambda (headline) (cons (plist-get (cadr headline) :raw-value)
                                                                           (plist-get (cadr headline) :contents-end)))
                                                  headlines))
                                (target (let ((n (downcase name)))
                                          (cdr
                                           (cl-some (lambda (package) (and (string-greaterp n (downcase (car package))) package))
                                                    (nreverse packages))))))
                      ;;put name on template's doct plist
                      (setq org-capture-plist
                            (plist-put org-capture-plist :doct
                                       (plist-put (org-capture-get :doct) :use-package name)))
                      (goto-char target)
                      (org-end-of-subtree)
                      (open-line 1)
                      (forward-line 1)))
                 :type plain
                 :empty-lines-after 1
                 :template ("** %(doct-get :use-package)"
                            "#+begin_quote"
                            "%(read-string \"package description:\")"
                            "#+end_quote"
                            "#+begin_src emacs-lisp"
                            "(use-package %(doct-get :use-package)%?)"
                            "#+end_src")))))

  ;; make-capture-frame cobbled together from:
  ;; - http://cestlaz.github.io/posts/using-emacs-24-capture-2/
  ;; - https://stackoverflow.com/questions/23517372/hook-or-advice-when-aborting-org-capture-before-template-selection
  ;; Don't use this within Emacs. Rather, invoke it when connecting an Emacs client to a server with:
  "emacsclient --create-frame \
            --socket-name 'capture' \
            --alternate-editor='' \
            --frame-parameters='(quote (name . \"capture\"))' \
            --no-wait \
            --eval \"(+org-capture-make-frame)\""

  (defun +org-capture-delete-frame (&rest _args)
    "Delete frame with a name frame-parameter set to \"capture\""
    (when (and (daemonp) (string= (frame-parameter (selected-frame) 'name) "capture"))
      (delete-frame)))
  (add-hook 'org-capture-after-finalize-hook #'+org-capture-delete-frame 100)

  (defun +org-capture-make-frame ()
    "Create a new frame and run org-capture."
    (interactive)
    (select-frame-by-name "capture")
    (delete-other-windows)
    (cl-letf (((symbol-function 'switch-to-buffer-other-window) #'switch-to-buffer))
      (condition-case err
          (org-capture)
        ;; "q" signals (error "Abort") in `org-capture'
        ;; delete the newly created frame in this scenario.
        (user-error (when (string= (cadr err) "Abort") (delete-frame))))))

  :commands (+org-capture-make-frame)
  :general (:states 'normal
            :keymaps 'org-capture-mode-map
            ",c" 'org-capture-finalize
            ",k" 'org-capture-kill
            ",r" 'org-capture-refile)

  :custom
  (org-capture-dir (concat (getenv "HOME") "/todo/")))

(use-package org-contrib)

(use-package org-fancy-priorities
  :commands (org-fancy-priorities-mode)
  :hook (org-mode . org-fancy-priorities-mode))

(use-feature org-habit
  :after (org)
  :config
  (defun +org-habit-graph-on-own-line (graph)
    "Place org habit consitency graph below the habit."
    (let* ((count 0)
           icon)
      (save-excursion
        (beginning-of-line)
        (while (and (eq (char-after) ? ) (not (eolp)))
          (when (get-text-property (point) 'display) (setq icon t))
          (setq count (1+ count))
          (forward-char)))
      (add-text-properties (+ (line-beginning-position) count) (line-end-position)
                           `(display ,(concat (unless icon "  ")
                                              (string-trim-left (thing-at-point 'line))
                                              (make-string (or org-habit-graph-column 0) ? )
                                              (string-trim-right
                                               (propertize graph 'mouse-face 'inherit)))))))
  (defun +org-habit-insert-consistency-graphs (&optional line)
    "Insert consistency graph for any habitual tasks."
    (let ((inhibit-read-only t)
          (buffer-invisibility-spec '(org-link))
          (moment (time-subtract nil (* 3600 org-extend-today-until))))
      (save-excursion
        (goto-char (if line (line-beginning-position) (point-min)))
        (while (not (eobp))
          (let ((habit (get-text-property (point) 'org-habit-p)))
            (when habit
              (let ((graph (org-habit-build-graph
                            habit
                            (time-subtract moment (days-to-time org-habit-preceding-days))
                            moment
                            (time-add moment (days-to-time org-habit-following-days)))))
                (+org-habit-graph-on-own-line graph))))
          (forward-line)))))
  (advice-add #'org-habit-insert-consistency-graphs
              :override #'+org-habit-insert-consistency-graphs)
  :custom
  (org-habit-today-glyph #x1f4c5)
  (org-habit-completed-glyph #x2713)
  (org-habit-preceding-days 29)
  (org-habit-following-days 1)
  (org-habit-graph-column 3)
  (org-habit-show-habits-only-for-today nil))

(use-feature org-indent
  :after (org)
  :hook (org-mode . org-indent-mode)
  :config
  (define-advice org-indent-refresh-maybe (:around (fn &rest args) "when-buffer-visible")
    "Only refresh indentation when buffer's window is visible.
Speeds up `org-agenda' remote operations."
    (when (get-buffer-window (current-buffer) t) (apply fn args))))

(defun +org-files-list ()
  "Returns a list of the file names for currently open Org files"
  (delq nil
        (mapcar (lambda (buffer)
                  (when-let* ((file-name (buffer-file-name buffer))
                              (directory (file-name-directory file-name)))
                    (unless (string-suffix-p "archives/" directory)
                      file-name)))
                (org-buffer-list 'files t))))

(setq +org-max-refile-level 20)

(setq org-outline-path-complete-in-steps nil
      org-refile-allow-creating-parent-nodes 'confirm
      org-refile-use-outline-path 'file
      org-refile-targets `((org-agenda-files  :maxlevel . ,+org-max-refile-level)
                           (+org-files-list :maxlevel . ,+org-max-refile-level)))

(setq org-agenda-files '("~/todo")
      org-agenda-text-search-extra-files '(agenda-archives)
      org-fold-catch-invisible-edits 'show-and-error
      org-confirm-babel-evaluate nil
      org-enforce-todo-dependencies t
      org-hide-emphasis-markers t
      org-hierarchical-todo-statistics nil
      org-log-done 'time
      org-log-reschedule t
      org-return-follows-link t
      org-reverse-note-order t
      org-src-tab-acts-natively t
      org-file-apps
      '((auto-mode . emacs)
        ("\\.mm\\'" . default)
        ("\\.mp[[:digit:]]\\'" . "/usr/bin/mpv --force-window=yes %s")
        ;;("\\.x?html?\\'" . "/usr/bin/firefox-beta %s")
        ("\\.x?html?\\'" . "/usr/bin/bash -c '$BROWSER  %s'")
        ("\\.pdf\\'" . default)))

;; Set clock report duration format to floating point hours
(setq org-duration-format '(("h" . nil) (special . 2)))

(use-package org-make-toc
  :commands (org-make-toc))

(use-package org-modern :after (org)
  :config
  (global-org-modern-mode)
  (remove-hook 'org-agenda-finalize-hook 'org-modern-agenda))

(use-package org-pomodoro
  :config
  ;; TODO: configure this
  )

(use-package org-roam
  :ensure (org-roam :host github :repo "org-roam/org-roam")
  :general
  (+general-global-application
    "or" '(:ignore t :which-key "org-roam-setup"))
  :init (setq org-roam-v2-ack t))

(use-package org-roam-ui)

(use-package org-superstar
  :ensure (org-superstar :host github :repo "integral-dw/org-superstar-mode")
  :after (org))

;; Github flavored Markdown back-end for Org export engine
(use-package ox-gfm :defer t)

;; Export org-mode docs as HTML compatible with Twitter Bootstrap.
(use-package ox-twbs
  :disabled t
  :after (org)
  :defer t)

(provide 'init-org)
