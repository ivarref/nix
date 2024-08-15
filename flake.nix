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
          '';

          security.pam.enableSudoTouchIdAuth = true;

          # List packages installed in system profile. To search by name, run:
          # $ nix-env -qaP | grep wget
          environment.systemPackages = [
            pkgs.neofetch
            pkgs.vim
            pkgs.fish
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
            ];
            brews = [ "cowsay" ];
            casks = [ "easy-move-plus-resize" ];
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
            direnv
            dive
            entr
            fzf
            neil
            nixfmt-rfc-style
            jdk
            jq
            lima
            rclone
            ripgrep
            sshpass
            wget
          ];

          home.sessionVariables = {
            EDITOR = "zed --wait";
            CDPATH = "$HOME/code";
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
              shellInit = ''
                direnv hook fish | source
                export DOCKER_HOST=$(limactl list docker --format 'unix://{{.Dir}}/sock/docker.sock')
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
