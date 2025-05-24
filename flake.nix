{
  # https://davi.sh/blog/2024/01/nix-darwin/
  # https://davi.sh/blog/2024/02/nix-home-manager/
  description = "Example Darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      self,
      nix-darwin,
      nixpkgs,
      home-manager,
    }:
    let
      configuration =
        { pkgs, lib, ... }:
        {

          # Auto upgrade nix package and the daemon service.
          services.nix-daemon.enable = true;
          # nix.package = pkgs.nix;

          # Necessary for using flakes on this system.
          nix.settings.experimental-features = "nix-command flakes";

          # Set Git commit hash for darwin-version.
          system.configurationRevision = self.rev or self.dirtyRev or null;

          # Used for backwards compatibility, please read the changelog before changing.
          # $ darwin-rebuild changelog
          system.stateVersion = 4;

          # The platform the configuration will be used on.
          nixpkgs.hostPlatform = "aarch64-darwin";

          fonts.packages = with pkgs; [
            fira
            fira-code
            iosevka
            roboto
            roboto-mono
            source-sans
            source-code-pro
            source-serif
          ];

          # Declare the user that will be running `nix-darwin`.
          users.users.ire = {
            name = "ire";
            home = "/Users/ire";
          };

          programs.fish.enable = true;
          system.activationScripts.postActivation.text = ''
            # Set the default shell as fish for the user. MacOS doesn't do this like nixOS does
            sudo chsh -s ${lib.getBin pkgs.fish}/bin/fish ire

            # inspired by: https://www.reddit.com/r/MacOS/comments/16vmecr/ntfs_on_macos_sonoma_hacky_but_works/
            sudo ln -sf $(readlink /usr/local/lib/libfuse-t.dylib) /usr/local/lib/libfuse.2.dylib
            # ^^ symlink required by ntfs-3g

            # example mount command:
            # sudo bash -c 'mkdir /Volumes/NTFS && ntfs-3g /dev/disk4s1 /Volumes/NTFS'

            # where disk4s1 is from
            # $ diskutil list
            # ...
            # > /dev/disk4 (external, physical):
            #:                       TYPE NAME                    SIZE       IDENTIFIER
            # 0:     FDisk_partition_scheme                        *16.0 GB    disk4
            # 1:               Windows_NTFS UUI                     16.0 GB    disk4s1
            #                                                       HERE ------^^^^^^^

            # sudo ln -sf $(readlink /usr/local/lib/libfuse-t.dylib) /usr/local/lib/libosxfuse.2.dylib
          '';

          security.pam.enableSudoTouchIdAuth = true;

          # List packages installed in system profile. To search by name, run:
          # $ nix-env -qaP | grep wget
          environment.systemPackages = [
            pkgs.vim
            pkgs.fish
            pkgs.iterm2
            pkgs.ntfs3g
          ];

          homebrew = {
            enable = true;
            onActivation.cleanup = "uninstall";
            # clone_target = "ssh";
            # global = { config, ... }: {
            # };
            taps = [
              {
                name = "dmarcotte/easy-move-plus-resize";
                clone_target = "https://github.com/dmarcotte/easy-move-resize.git";
                force_auto_update = true;
              }
              {
                name = "macos-fuse-t/homebrew-cask";
                clone_target = "https://github.com/macos-fuse-t/homebrew-cask.git";
                # fuse-t: https://github.com/macos-fuse-t/homebrew-cask/blob/main/Casks/fuse-t.rb
                force_auto_update = true;
              }
              {
                name = "FelixKratz/formulae";
                clone_target = "git@github.com:FelixKratz/homebrew-formulae.git"; # https://github.com/FelixKratz/homebrew-formulae/blob/master/borders.rb
                # brew tap FelixKratz/formulae
                # brew install borders
                force_auto_update = true;
              }
              #            {
              #              name = "FelixKratz/JankyBorders";
              #              clone_target = "git@github.com:FelixKratz/JankyBorders.git";
              #              force_auto_update = true;
              #            }

              #            "FelixKratz/formulae" = { url = "github:"; }

              # {
              #   name = "gromgit/homebrew-fuse";
              #   clone_target = "https://github.com/gromgit/homebrew-fuse.git";
              #   # mounty: https://github.com/gromgit/homebrew-fuse/blob/main/Casks/mounty.rb
              #   force_auto_update = true;
              # }
            ];
            brews = [
              "cowsay"
              "llm"
              "borders"
            ];
            casks = [
              "easy-move-plus-resize"
              "fuse-t"
              "hammerspoon"
              "librewolf"
              "nikitabobko/tap/aerospace"
            ];
          };
        };
      homeconfig =
        { pkgs, ... }:
        {
          # this is internal compatibility configuration
          # for home-manager, don't change this!
          home.stateVersion = "23.05";

          home.packages = with pkgs; [
            bat
            babashka
            clj-kondo
            clojure
            docker
            docker-compose
            direnv
            dive
            entr
            expect
            fastfetch
            fd
            fzf
            htop
            ncdu
            neil
            neovim
            maven
            mc
            nixfmt-rfc-style
            jdk
            jq
            leiningen
            lima
            python3
            rclone
            ripgrep
            scc
            sshpass
            tmux
            watch
            wget
          ];

          home.sessionVariables = {
            EDITOR = "nvim";
            CDPATH = "$HOME/code:$HOME/.config";
          };

          home.sessionPath = [
            "$HOME/.config/nix/scripts"
            "$HOME/.config/nix/bin"
          ];

          programs = {
            fish = {
              enable = true;
              shellAliases = {
                swdarwin = "darwin-rebuild switch --flake ~/.config/nix";
                idea = "open -n \"/Applications/IntelliJ IDEA.app\" --args .";
              };
              shellAbbrs = {
                #                nb = "nix build";
                #                dr = "docker stop --force dev 2>/dev/null ; docker run --rm -it --name dev dev:dev";
              };
              shellInit = ''
                set -gx DIRENV_LOG_FORMAT ""
                direnv hook fish | source
                source $HOME/.config/nix/my.fish
                source $HOME/.config/nix/exports
              '';
            };

            git = {
              enable = true;
              userName = "ire";
              userEmail = "ivar.refsdal@sikt.no";
              ignores = [ ".DS_Store" ];
              extraConfig = {
                init.defaultBranch = "main";
                push.autoSetupRemote = true;
              };
            };

            direnv = {
              enable = true;
              nix-direnv.enable = true;
            };

            # Sets JAVA_HOME environment variable
            java.enable = true;

            # Let Home Manager install and manage itself.
            home-manager.enable = true;
          };
        };
    in
    {
      # Build darwin flake using:
      # $ darwin-rebuild build --flake .#Ivars-MacBook-Air
      darwinConfigurations."Ivars-MacBook-Air" = nix-darwin.lib.darwinSystem {
        modules = [
          configuration
          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.verbose = true;
            home-manager.users.ire = homeconfig;
          }
        ];
      };

      # Expose the package set, including overlays, for convenience.
      darwinPackages = self.darwinConfigurations."Ivars-MacBook-Air".pkgs;
    };
}
