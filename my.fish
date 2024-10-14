
abbr -a --set-cursor='%' -- db 'docker build --tag=dev:dev .%'
abbr -a --set-cursor='%' -- gf 'git ls-files | entr -c bash -c \'%\''
abbr -a --set-cursor='%' -- gc 'git commit -am "%" && git push'

function last_history_item
    echo "git ls-files | entr -cr bash -c 'set -x; $history[1]'"
end

abbr -a gfl --function last_history_item

# Base16 Shell
if status --is-interactive
    set BASE16_SHELL "$HOME/.config/base16-shell/"
    source "$BASE16_SHELL/profile_helper.fish"
end

base16-onedark
#base16-materia
