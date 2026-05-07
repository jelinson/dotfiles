(custom-set-variables
 '(fill-column 80)
 '(show-trailing-whitespace t))

(setq column-number-mode t)
(setq transient-mark-mode t)
(require 'recentf)
(recentf-mode 1)
(setq recentf-max-menu-items 25)
(global-set-key "\C-x\ \C-r" 'recentf-open-files)

(global-set-key "\C-c\C-d" "\C-a\C-@\C-n\M-w\C-y")
(setq require-final-newline t)

(add-hook 'before-save-hook 'delete-trailing-whitespace)
