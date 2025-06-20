# abbr -a --set-cursor='%' -- db 'docker build --tag=dev:dev .%'
abbr -a --set-cursor='%' -- gf 'git ls-files | entr -c bash -c \'%\''
abbr -a --set-cursor='%' -- gc 'git commit -am "%" && git push'
abbr -a --set-cursor='!' -- gq 'git reset --soft HEAD~1; git log --pretty=format:"%h%x09%an%x09%ad%x09%s" -5; git commit -am "$(git log -1 --format=%s)"; git push --force!'
abbr -a --set-cursor='%' -- vim 'nvim %'
abbr -a --set-cursor='%' -- fished 'nvim ~/.config/nix/my.fish; source ~/.config/nix/my.fish%'
abbr -a --set-cursor='%' -- nixed 'nvim ~/.config/nix/flake.nix%'
abbr -a --set-cursor='%' -- aeroed 'nvim ~/.config/aerospace/aerospace.toml%'
abbr -a --set-cursor='%' -- alm "llm -m mistral-7b-instruct-v0 '%'"
abbr -a --set-cursor='%' -- ghostty "/Applications/Ghostty.app/Contents/MacOS/ghostty %"

abbr -a --set-cursor='%' -- swdarwin "sudo darwin-rebuild switch --flake ~/.config/nix %"
abbr -a --set-cursor='%' -- bbi "brew bundle install %"

function last_history_item
    echo "git ls-files | entr -cr bash -c 'set -x; env FROM_ENTR=1 $history[1]; echo \"Exit code is: \$?\"'"
end

function last_history_item2
    echo "git ls-files | entr -ccr bash -c '$history[1]'"
end

abbr -a gfl --function last_history_item
abbr -a gfs --function last_history_item2

# Base16 Shell
if status --is-interactive
    set BASE16_SHELL "$HOME/.config/base16-shell/"
    source "$BASE16_SHELL/profile_helper.fish"
    base16-materia
end

eval "$(/opt/homebrew/bin/brew shellenv)"
#base16-materia
