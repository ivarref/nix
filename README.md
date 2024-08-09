```bash
mkdir -p ~/.config/nix-darwin
cd ~/.config/nix-darwin
nix flake init -t nix-darwin
sed -i '' "s/simple/$(scutil --get LocalHostName)/" flake.nix

# Make sure to change nixpkgs.hostPlatform to aarch64-darwin if you are using Apple Silicon.

nix run --extra-experimental-features nix-command \
--extra-experimental-features flakes \
nix-darwin -- switch --flake ~/.config/nix-darwin
```
