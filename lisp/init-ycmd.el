(require-package 'ycmd)
(require-package 'company-ycmd)
(require 'ycmd)
(add-hook 'c++-mode-hook 'company-mode)
(add-hook 'c++-mode-hook 'ycmd-mode)
;;路径就是你自己的ycmd的路径
(set-variable 'ycmd-server-command
              '("python" "~/ycmd/ycmd"))
(set-variable 'ycmd-global-config "~/.ycm_extra_conf.py")

(require 'company-ycmd)
(company-ycmd-setup)

(provide 'init-ycmd)
