
abbr -a --set-cursor='%' -- db 'docker build --tag=dev:dev .%'
abbr -a --set-cursor='%' -- gf 'git ls-files | entr -c bash -c \'%\''
abbr -a --set-cursor='%' -- gc 'git commit -am "%" && git push'

function last_history_item
    echo "git ls-files | entr -c bash -c 'set -x; $history[1]'"
end

abbr -a gfl --function last_history_item
