(require-package 'evil)
(setq evil-symbol-word-search t)
(require 'evil)

(setq evil-default-cursor t)

(define-key evil-visual-state-map (kbd "mn") 'mc/mark-next-like-this)
(define-key evil-visual-state-map (kbd "ma") 'mc/mark-all-like-this-dwim)
(define-key evil-visual-state-map (kbd "md") 'mc/mark-all-like-this-in-defun)
(define-key evil-visual-state-map (kbd "mm") 'ace-mc-add-multiple-cursors)
(define-key evil-visual-state-map (kbd "ms") 'ace-mc-add-single-cursor)

(evil-mode 1)
(require-package 'evil-surround)
(require 'evil-surround)

(global-evil-surround-mode 1)
(defun evil-surround-prog-mode-hook-setup ()
  (push '(47 . ("/" . "/")) evil-surround-pairs-alist)
  (push '(40 . ("(" . ")")) evil-surround-pairs-alist)
  (push '(41 . ("(" . ")")) evil-surround-pairs-alist))
(add-hook 'prog-mode-hook 'evil-surround-prog-mode-hook-setup)
(defun evil-surround-emacs-lisp-mode-hook-setup ()
  (push '(?` . ("`" . "'")) evil-surround-pairs-alist))
(add-hook 'emacs-lisp-mode-hook 'evil-surround-emacs-lisp-mode-hook-setup)
(defun evil-surround-org-mode-hook-setup ()
  (push '(?= . ("=" . "=")) evil-surround-pairs-alist))
(add-hook 'org-mode-hook 'evil-surround-org-mode-hook-setup)

(require-package 'evil-visualstar)
(require 'evil-visualstar)

(setq evil-visualstar/persistent t)
(global-evil-visualstar-mode t)


(defun ffip-diff-mode-hook-setup ()
  (evil-local-set-key 'normal "p" 'diff-hunk-prev)
  (evil-local-set-key 'normal "n" 'diff-hunk-next)
  (evil-local-set-key 'normal "P" 'diff-file-prev)
  (evil-local-set-key 'normal "N" 'diff-file-next)
  (evil-local-set-key 'normal "q" 'ffip-diff-quit)
  (evil-local-set-key 'normal (kbd "RET") 'ffip-diff-find-file)
  (evil-local-set-key 'normal "o" 'ffip-diff-find-file))
(add-hook 'ffip-diff-mode-hook 'ffip-diff-mode-hook-setup)

(require-package 'evil-mark-replace)
(require 'evil-mark-replace)

(defmacro define-and-bind-text-object (key start-regex end-regex)
  (let ((inner-name (make-symbol "inner-name"))
        (outer-name (make-symbol "outer-name")))
    `(progn
       (evil-define-text-object ,inner-name (count &optional beg end type)
         (evil-select-paren ,start-regex ,end-regex beg end type count nil))
       (evil-define-text-object ,outer-name (count &optional beg end type)
         (evil-select-paren ,start-regex ,end-regex beg end type count t))
       (define-key evil-inner-text-objects-map ,key (quote ,inner-name))
       (define-key evil-outer-text-objects-map ,key (quote ,outer-name)))))

(define-and-bind-text-object "$" "\\$" "\\$")
(define-and-bind-text-object "=" "=" "=")
(define-and-bind-text-object "|" "|" "|")
(define-and-bind-text-object "/" "/" "/")
(define-and-bind-text-object "l" "^ *" " *$")
(define-and-bind-text-object "r" "\{\{" "\}\}")


(defun evil-filepath-is-separator-char (ch)
  "Check ascii table that CH is slash characters.
If the character before and after CH is space or tab, CH is NOT slash"
  (let (rlt prefix-ch postfix-ch)
    (when (and (> (point) (point-min)) (< (point) (point-max)))
      (save-excursion
        (backward-char)
        (setq prefix-ch (following-char)))
      (save-excursion
        (forward-char)
        (setq postfix-ch (following-char))))
    (if (and (not (or (= prefix-ch 32) (= postfix-ch 32)))
             (or (= ch 47) (= ch 92)) )
        (setq rlt t))
    rlt))

(defun evil-filepath-not-path-char (ch)
  "Check ascii table for charctater "
  (let (rlt)
    (if (or (and (<= 0 ch) (<= ch 32))
            (= ch 34) ; double quotes
            (= ch 39) ; single quote
            (= ch 40) ; (
            (= ch 41) ; )
            (= ch 60) ; <
            (= ch 62) ; >
            (= ch 91) ; [
            (= ch 93) ; ]
            (= ch 96) ; `
            (= ch 123) ; {
            (= ch 125) ; }
            (= 127 ch))
        (setq rlt t))
    rlt))

(defun evil-filepath-char-not-placed-at-end-of-path (ch)
  (or (= 44 ch) ; ,
      (= 46 ch) ; .
      ))

(defun evil-filepath-calculate-path (b e)
  (let (rlt f)
    (when (and b e)
      (setq b (+ 1 b))
      (when (save-excursion
              (goto-char e)
              (setq f (evil-filepath-search-forward-char 'evil-filepath-is-separator-char t))
              (and f (>= f b)))
        (setq rlt (list b (+ 1 f) (- e 1)))))
    rlt))

(defun evil-filepath-get-path-already-inside ()
  (let (b e)
    (save-excursion
      (setq b (evil-filepath-search-forward-char 'evil-filepath-not-path-char t)))
    (save-excursion
      (setq e (evil-filepath-search-forward-char 'evil-filepath-not-path-char))
      (when e
        (goto-char (- e 1))
        ;; example: hello/world,
        (if (evil-filepath-char-not-placed-at-end-of-path (following-char))
            (setq e (- e 1)))
        ))
    (evil-filepath-calculate-path b e)))

(defun evil-filepath-search-forward-char (fn &optional backward)
  (let (found rlt (limit (if backward (point-min) (point-max))) out-of-loop)
    (save-excursion
      (while (not out-of-loop)
        ;; for the char, exit
        (if (setq found (apply fn (list (following-char))))
            (setq out-of-loop t)
          ;; reach the limit, exit
          (if (= (point) limit)
              (setq out-of-loop t)
            ;; keep moving
            (if backward (backward-char) (forward-char)))))
      (if found (setq rlt (point))))
    rlt))

(defun evil-filepath-extract-region ()
  "Find the closest file path"
  (let (rlt
        b
        f1
        f2)

    (if (and (not (evil-filepath-not-path-char (following-char)))
             (setq rlt (evil-filepath-get-path-already-inside)))
        ;; maybe (point) is in the middle of the path
        t
      ;; need search forward AND backward to find the right path
      (save-excursion
        ;; path in backward direction
        (when (setq b (evil-filepath-search-forward-char 'evil-filepath-is-separator-char t))
          (goto-char b)
          (setq f1 (evil-filepath-get-path-already-inside))))
      (save-excursion
        ;; path in forward direction
        (when (setq b (evil-filepath-search-forward-char 'evil-filepath-is-separator-char))
          (goto-char b)
          (setq f2 (evil-filepath-get-path-already-inside))))
      ;; pick one path as the final result
      (cond
       ((and f1 f2)
        (if (> (- (point) (nth 2 f1)) (- (nth 0 f2) (point)))
            (setq rlt f2)
          (setq rlt f1)))
       (f1
        (setq rlt f1))
       (f2
        (setq rlt f2))))

    rlt))

(evil-define-text-object evil-filepath-inner-text-object (&optional count begin end type)
  "File name of nearby path"
  (let ((selected-region (evil-filepath-extract-region)))
    (if selected-region
        (evil-range (nth 1 selected-region) (nth 2 selected-region) :expanded t))))

(evil-define-text-object evil-filepath-outer-text-object (&optional NUM begin end type)
  "Nearby path"
  (let ((selected-region (evil-filepath-extract-region)))
    (if selected-region
        (evil-range (car selected-region) (+ 1 (nth 2 selected-region)) type :expanded t))))

(define-key evil-inner-text-objects-map "f" 'evil-filepath-inner-text-object)
(define-key evil-outer-text-objects-map "f" 'evil-filepath-outer-text-object)

(require-package 'evil-escape)
(require 'evil-escape)

(setq-default evil-escape-delay 0.5)
(setq evil-escape-excluded-major-modes '(dired-mode))
(setq-default evil-escape-key-sequence "kj")
(evil-escape-mode 1)

(setq evil-move-cursor-back t)

(defun toggle-org-or-message-mode ()
  (interactive)
  (if (eq major-mode 'message-mode)
      (org-mode)
    (if (eq major-mode 'org-mode) (message-mode))
    ))


(evil-declare-key 'normal org-mode-map
  "gh" 'outline-up-heading
  "gl" 'outline-next-visible-heading
  "$" 'org-end-of-line ; smarter behaviour on headlines etc.
  "^" 'org-beginning-of-line ; ditto
  "<" (lambda () (interactive) (org-demote-or-promote 1)) ; out-dent
  ">" 'org-demote-or-promote ; indent
  (kbd "TAB") 'org-cycle)

(loop for (mode . state) in
      '((minibuffer-inactive-mode . emacs)
        (ggtags-global-mode . emacs)
        (grep-mode . emacs)
        (Info-mode . emacs)
        (term-mode . emacs)
        (sdcv-mode . emacs)
        (anaconda-nav-mode . emacs)
        (log-edit-mode . emacs)
        (vc-log-edit-mode . emacs)
        (magit-log-edit-mode . emacs)
        (inf-ruby-mode . emacs)
        (direx:direx-mode . emacs)
        (yari-mode . emacs)
        (erc-mode . emacs)
        (neotree-mode . emacs)
        (w3m-mode . emacs)
        (gud-mode . emacs)
        (help-mode . emacs)
        (eshell-mode . emacs)
        (shell-mode . emacs)
        ;;(message-mode . emacs)
        (fundamental-mode . emacs)
        (weibo-timeline-mode . emacs)
        (weibo-post-mode . emacs)
        (sr-mode . emacs)
        (profiler-report-mode . emacs)
        (dired-mode . emacs)
        (compilation-mode . emacs)
        (speedbar-mode . emacs)
        (ivy-occur-mode . emacs)
        (messages-buffer-mode . normal)
        (magit-commit-mode . normal)
        (magit-diff-mode . normal)
        (browse-kill-ring-mode . normal)
        (etags-select-mode . normal)
        (js2-error-buffer-mode . emacs)
        )
      do (evil-set-initial-state mode state))

;; I prefer Emacs way after pressing ":" in evil-mode
(define-key evil-ex-completion-map (kbd "C-a") 'move-beginning-of-line)
(define-key evil-ex-completion-map (kbd "C-b") 'backward-char)
(define-key evil-ex-completion-map (kbd "M-p") 'previous-complete-history-element)
(define-key evil-ex-completion-map (kbd "M-n") 'next-complete-history-element)

(define-key evil-normal-state-map "Y" (kbd "y$"))
(define-key evil-normal-state-map "go" 'goto-char)
(define-key evil-normal-state-map (kbd "M-y") 'counsel-browse-kill-ring)
(define-key evil-normal-state-map (kbd "C-]") 'etags-select-find-tag-at-point)
(define-key evil-visual-state-map (kbd "C-]") 'etags-select-find-tag-at-point)

(require-package 'evil-numbers)
(require 'evil-numbers)
(define-key evil-normal-state-map "+" 'evil-numbers/inc-at-pt)
(define-key evil-normal-state-map "-" 'evil-numbers/dec-at-pt)

(require-package 'evil-matchit)
(require 'evil-matchit)
(global-evil-matchit-mode 1)

;; press ",xx" to expand region
;; then press "z" to contract, "x" to expand
(eval-after-load "evil"
  '(progn
     (setq expand-region-contract-fast-key "z")
     ))

;; I learn this trick from ReneFroger, need latest expand-region
;; @see https://github.com/redguardtoo/evil-matchit/issues/38
(define-key evil-visual-state-map (kbd "v") 'er/expand-region)
(define-key evil-insert-state-map (kbd "C-e") 'move-end-of-line)
(define-key evil-insert-state-map (kbd "C-k") 'kill-line)
(define-key evil-insert-state-map (kbd "M-j") 'yas-expand)
(define-key evil-emacs-state-map (kbd "M-j") 'yas-expand)
(global-set-key (kbd "C-r") 'undo-tree-redo)

;; My frequently used commands are listed here
;; For example, for line like `"ef" 'end-of-defun`
;;   You can either press `,ef` or `M-x end-of-defun` to execute it

(require-package 'general)
(require 'general)
(general-evil-setup t)

;; {{ use `,` as leader key
(nvmap :prefix ","
       "=" 'increase-default-font-height ; GUI emacs only
       "-" 'decrease-default-font-height ; GUI emacs only
       "em" 'erase-message-buffer
       "eb" 'eval-buffer
       "sd" 'sudo-edit
       "sc" 'shell-command
       "ee" 'eval-expression
       "aa" 'copy-to-x-clipboard ; used frequently
       "aw" 'ace-swap-window
       "af" 'ace-maximize-window
       "ac" 'aya-create
       "ae" 'aya-expand
       "zz" 'paste-from-x-clipboard ; used frequently
       "cy" 'strip-convert-lines-into-one-big-string
       "bs" '(lambda () (interactive) (goto-edge-by-comparing-font-face -1))
       "es" 'goto-edge-by-comparing-font-face
       "vj" 'my-validate-json-or-js-expression
       "mcr" 'my-create-regex-from-kill-ring
       "ntt" 'neotree-toggle
       "ntf" 'neotree-find ; open file in current buffer in neotree
       "ntd" 'neotree-project-dir
       "nth" 'neotree-hide
       "nts" 'neotree-show
       "fl" 'cp-filename-line-number-of-current-buffer
       "fn" 'cp-filename-of-current-buffer
       "fp" 'cp-fullpath-of-current-buffer
       "dj" 'dired-jump ;; open the dired from current file
       "ff" 'toggle-full-window ;; I use WIN+F in i3
       "ip" 'find-file-in-project
       "kk" 'find-file-in-project-by-selected
       "fd" 'find-directory-in-project-by-selected
       "trm" 'get-term
       "tff" 'toggle-frame-fullscreen
       "tfm" 'toggle-frame-maximized
       "ti" 'fastdef-insert
       "th" 'fastdef-insert-from-history
       ;; "ci" 'evilnc-comment-or-uncomment-lines
       ;; "cl" 'evilnc-comment-or-uncomment-to-the-line
       ;; "cc" 'evilnc-copy-and-comment-lines
       ;; "cp" 'evilnc-comment-or-uncomment-paragraphs
       "epy" 'emmet-expand-yas
       "epl" 'emmet-expand-line
       "rd" 'evilmr-replace-in-defun
       "rb" 'evilmr-replace-in-buffer
       "ts" 'evilmr-tag-selected-region ;; recommended
       "rt" 'evilmr-replace-in-tagged-region ;; recommended
       "tua" 'artbollocks-mode
       "cby" 'cb-switch-between-controller-and-view
       "cbu" 'cb-get-url-from-controller
       "ht" 'etags-select-find-tag-at-point ; better than find-tag C-]
       "hp" 'etags-select-find-tag
       "mm" 'counsel-bookmark-goto
       "mk" 'bookmark-set
       "yy" 'counsel-browse-kill-ring
       "gf" 'counsel-git-find-file
       "gc" 'counsel-git-find-file-committed-with-line-at-point
       "gl" 'counsel-git-grep-yank-line
       "gg" 'counsel-git-grep-in-project ; quickest grep should be easy to press
       "ga" 'counsel-git-grep-by-author
       "gm" 'counsel-git-find-my-file
       "gs" 'ffip-show-diff ; find-file-in-project 5.0+
       "sf" 'counsel-git-show-file
       "sh" 'my-select-from-search-text-history
       "df" 'counsel-git-diff-file
       "rjs" 'run-js
       "jsr" 'js-send-region
       "rmz" 'run-mozilla
       "rpy" 'run-python
       "rlu" 'run-lua
       "tci" 'toggle-company-ispell
       "kb" 'kill-buffer-and-window ;; "k" is preserved to replace "C-g"
       "it" 'issue-tracker-increment-issue-id-under-cursor
       "ls" 'highlight-symbol
       "lq" 'highlight-symbol-query-replace
       "ln" 'highlight-symbol-nav-mode ; use M-n/M-p to navigation between symbols
       "bm" 'pomodoro-start ;; beat myself
       "ii" 'counsel-imenu-goto
       "im" 'ido-imenu
       "ij" 'rimenu-jump
       "." 'evil-ex
       ;; @see https://github.com/pidu/git-timemachine
       ;; p: previous; n: next; w:hash; W:complete hash; g:nth version; q:quit
       "tt" 'my-git-timemachine
       "tdb" 'tidy-buffer
       "tdl" 'tidy-current-line
       ;; toggle overview,  @see http://emacs.wordpress.com/2007/01/16/quick-and-dirty-code-folding/
       "ov" 'my-overview-of-current-buffer
       "or" 'open-readme-in-git-root-directory
       "oo" 'compile
       "c$" 'org-archive-subtree ; `C-c $'
       ;; org-do-demote/org-do-premote support selected region
       "c<" 'org-do-promote ; `C-c C-<'
       "c>" 'org-do-demote ; `C-c C->'
       "cam" 'org-tags-view ; `C-c a m': search items in org-file-apps by tag
       "cxi" 'org-clock-in ; `C-c C-x C-i'
       "cxo" 'org-clock-out ; `C-c C-x C-o'
       "cxr" 'org-clock-report ; `C-c C-x C-r'
       "qq" 'my-grep
       "xc" 'save-buffers-kill-terminal
       "rr" 'counsel-recentf-goto
       "rh" 'counsel-yank-bash-history ; bash history command => yank-ring
       "rf" 'counsel-goto-recent-directory
       "da" 'diff-region-tag-selected-as-a
       "db" 'diff-region-compare-with-b
       "di" 'evilmi-delete-items
       "si" 'evilmi-select-items
       "jb" 'js-beautify
       "jp" 'my-print-json-path
       "sep" 'string-edit-at-point
       "sec" 'string-edit-conclude
       "sea" 'string-edit-abort
       "xe" 'eval-last-sexp
       "ru" 'undo-tree-save-state-to-register ; C-x r u
       "rU" 'undo-tree-restore-state-from-register ; C-x r U
       "xt" 'toggle-window-split
       "uu" 'winner-undo
       "UU" 'winner-redo
       "to" 'toggle-web-js-offset
       "sl" 'sort-lines
       "ulr" 'uniquify-all-lines-region
       "ulb" 'uniquify-all-lines-buffer
       "lj" 'moz-load-js-file-and-send-it
       "mr" 'moz-console-clear
       "rnr" 'rinari-web-server-restart
       "rnc" 'rinari-find-controller
       "rnv" 'rinari-find-view
       "rna" 'rinari-find-application
       "rnk" 'rinari-rake
       "rnm" 'rinari-find-model
       "rnl" 'rinari-find-log
       "rno" 'rinari-console
       "rnt" 'rinari-find-test
       "fs" 'ffip-save-ivy-last
       "fr" 'ffip-ivy-resume
       "fc" 'cp-ffip-ivy-last
       "ss" 'swiper-the-thing ; http://oremacs.com/2015/03/25/swiper-0.2.0/ for guide
       "hst" 'hs-toggle-fold
       "hsa" 'hs-toggle-fold-all
       "hsh" 'hs-hide-block
       "hss" 'hs-show-block
       "hd" 'describe-function
       "hf" 'find-function
       "hk" 'describe-key
       "hv" 'describe-variable
       "gt" 'ggtags-find-tag-dwim
       "gr" 'ggtags-find-reference
       "fb" 'flyspell-buffer
       "fe" 'flyspell-goto-next-error
       "fa" 'flyspell-auto-correct-word
       "pe" 'flymake-goto-prev-error
       "ne" 'flymake-goto-next-error
       "fw" 'ispell-word
       "bc" '(lambda () (interactive) (wxhelp-browse-class-or-api (thing-at-point 'symbol)))
       "oag" 'org-agenda
       "otl" 'org-toggle-link-display
       "om" 'toggle-org-or-message-mode
       "ut" 'undo-tree-visualize
       "ar" 'align-regexp
       "wrn" 'httpd-restart-now
       "wrd" 'httpd-restart-at-default-directory
       "bk" 'buf-move-up
       "bj" 'buf-move-down
       "bh" 'buf-move-left
       "bl" 'buf-move-right
       "xm" 'my-M-x
       "xx" 'er/expand-region
       "xf" 'ido-find-file
       "xb" 'ido-switch-buffer
       "xh" 'mark-whole-buffer
       "xk" 'ido-kill-buffer
       "xs" 'save-buffer
       "xz" 'suspend-frame
       "vm" 'vc-rename-file-and-buffer
       "vc" 'vc-copy-file-and-rename-buffer
       "xvv" 'vc-next-action ; 'C-x v v' in original
       "vg" 'vc-annotate ; 'C-x v g' in original
       "va" 'git-add-current-file
       "vk" 'git-checkout-current-file
       "vs" 'git-gutter:stage-hunk
       "vr" 'git-gutter:revert-hunk
       "vl" 'vc-print-log
       "vv" 'git-messenger:popup-message
       "v=" 'git-gutter:popup-hunk
       "hh" 'cliphist-paste-item
       "yu" 'cliphist-select-item
       "ih" 'my-goto-git-gutter ; use ivy-mode
       "ir" 'ivy-resume
       "nn" 'my-goto-next-hunk
       "pp" 'my-goto-previous-hunk
       "ycr" 'my-yas-reload-all
       "wf" 'popup-which-function)
;; }}

;; {{ Use `SPC` as leader key
;; all keywords arguments are still supported
(nvmap :prefix "SPC"
       "ss" 'wg-create-workgroup ; save windows layout
       "ll" 'my-wg-switch-workgroup ; load windows layout
       "kk" 'scroll-other-window
       "jj" 'scroll-other-window-up
       "yy" 'hydra-launcher/body
       "hh" 'multiple-cursors-hydra/body
       "tt" 'my-toggle-indentation
       "gs" 'git-gutter:set-start-revision
       "gh" 'git-gutter-reset-to-head-parent
       "gr" 'git-gutter-reset-to-default
       "ps" 'profiler-start
       "pr" 'profiler-report
       "cc" 'compile  ;; Mine chenpeng 20160519
       ;;Debug
       "dg" 'gdb
       "db" 'gud-break
       "dk" 'gud-kill-yes
       "dr" 'gud-remove
       "dd" 'my-gud-gdb
       "du" 'gud-run
       "dp" 'gud-print
       "dl" 'gud-cls
       "dn" 'gud-next
       "ds" 'gud-step
       "di" 'gud-stepi
       "dc" 'gud-cont
       "df" 'gud-finish
       "dw" 'gdb-many-windows

       ;;Format
       "fi" 'indent-region

       ;;Explore
       "ef" 'beginning-of-defun
       "eu" 'backward-up-list
       "ejb" 'back-to-previous-buffer
       "ejn" 'next-buffer
       "ebf" 'beginning-of-defun
       "ebl" 'backward-up-list

       "egd" 'ggtags-find-definition
       "egr" 'ggtags-find-reference
       "egf" 'ggtags-find-file
       "egt" 'ggtags-find-tag
       "ep" 'previous-buffer
       "ef" 'evil-show-file-info
       "el" 'helm-imenu
       "eip" 'find-file-in-project
       "es" 'helm-semantic-or-imenu
       "ef" 'end-of-defun
       "ews" 'narrow-or-widen-dwim
       "eww" 'widen
       "ewd" 'narrow-to-defun
       "ewr" 'narrow-to-region
       "bb" 'back-to-previous-buffer
       "ef" 'end-of-defun
       "mf" 'mark-defun

       ;; bookmark
       "bs" 'bookmark-set
       "bl" 'list-bookmarks
       ;; select window
       "0" 'select-window-0
       "1" 'select-window-1
       "2" 'select-window-2
       "3" 'select-window-3
       "4" 'select-window-4
       "5" 'select-window-5
       "6" 'select-window-6
       "7" 'select-window-7
       "8" 'select-window-8
       "9" 'select-window-9
       "x0" 'delete-window
       "x1" 'delete-other-windows
       "x2" 'split-window-vertically
       "x3" 'split-window-horizontally
       "rw" 'rotate-windows
       ) ;;;;;;;;;;;;;;;;END PREFIX SPC;;;;;;;;;;;;;;;;;;

;; {{ remember what we searched
;; http://emacs.stackexchange.com/questions/24099/how-to-yank-text-to-search-command-after-in-evil-mode/
(defvar my-search-text-history nil "List of text I searched.")
(defun my-select-from-search-text-history ()
  (interactive)
  (ivy-read "Search text history:" my-search-text-history
            :action (lambda (item)
                      (copy-yank-str item)
                      (message "%s => clipboard & yank ring" item))))
(defun my-cc-isearch-string ()
  (interactive)
  (if (and isearch-string (> (length isearch-string) 0))
      ;; NOT pollute clipboard who has things to paste into Emacs
      (add-to-list 'my-search-text-history isearch-string)))

(defadvice evil-search-incrementally (after evil-search-incrementally-after-hack activate)
  (my-cc-isearch-string))

(defadvice evil-search-word (after evil-search-word-after-hack activate)
  (my-cc-isearch-string))

(defadvice evil-visualstar/begin-search (after evil-visualstar/begin-search-after-hack activate)
  (my-cc-isearch-string))
;; }}

;; change mode-line color by evil state
(lexical-let ((default-color (cons (face-background 'mode-line)
                                   (face-foreground 'mode-line))))
  (add-hook 'post-command-hook
            (lambda ()
              (let ((color (cond ((minibufferp) default-color)
                                 ((evil-insert-state-p) '("#e80000" . "#ffffff"))
                                 ((evil-emacs-state-p)  '("#444488" . "#ffffff"))
                                 ((buffer-modified-p)   '("#006fa0" . "#ffffff"))
                                 (t default-color))))
                (set-face-background 'mode-line (car color))
                (set-face-foreground 'mode-line (cdr color))))))

(require-package 'evil-nerd-commenter)
(require 'evil-nerd-commenter)
(evilnc-default-hotkeys)

;; {{ evil-exchange
;; press gx twice to exchange, gX to cancel

(require-package 'evil-exchange)
(require 'evil-exchange)
;; change default key bindings (if you want) HERE
;; (setq evil-exchange-key (kbd "zx"))
(evil-exchange-install)
;; }}

;; }}

(provide 'init-evil)
