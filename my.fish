
abbr -a --set-cursor='%' -- db 'docker build --tag=dev:dev .%'
abbr -a --set-cursor='%' -- gf 'git ls-files | entr -c bash -c \'%\''
abbr -a --set-cursor='%' -- gc 'git commit -am "%" && git push'
