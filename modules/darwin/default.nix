{ pkgs, ... }: {
    # --- System Core ---
    nixpkgs.hostPlatform = "aarch64-darwin";
    nixpkgs.config.allowUnfree = true;
    nix.extraOptions = "experimental-features = nix-command flakes";
    nix.enable = false;
    system.stateVersion = 6;

    # --- User & Shell Configuration ---
    system.primaryUser = "zhao";
    users.users.zhao = {
        name = "zhao";
        home = "/Users/zhao";
    };

    programs.zsh.enable = true;
    imports = [ ./scripts.nix ];

    environment = {
        shells = [ pkgs.zsh ];
        variables = {
            EDITOR = "nvim";
            VISUAL = "nvim";
            TERMINAL = "alacritty";
        };
    };

    # --- Security & Input ---
    security.pam.services.sudo_local.touchIdAuth = true;

    # --- macOS System Defaults ---
    system.defaults = {
        dock = {
            autohide = true;
            mru-spaces = false;
            expose-group-apps = true;
        };

        finder = {
            AppleShowAllExtensions = true;
            QuitMenuItem = true;
        };

        trackpad = {
            Clicking = true;
            Dragging = true;
            TrackpadPinch = true;
            TrackpadRightClick = true;
        };

        NSGlobalDomain = {
            AppleShowAllFiles = true;
            AppleShowAllExtensions = true;
            AppleSpacesSwitchOnActivate = false;
            AppleWindowTabbingMode = "manual";

            InitialKeyRepeat = 15;
            KeyRepeat = 1;

            "com.apple.swipescrolldirection" = true;

            NSAutomaticSpellingCorrectionEnabled = false;
            NSAutomaticCapitalizationEnabled = false;
            NSAutomaticQuoteSubstitutionEnabled = false;
            NSAutomaticDashSubstitutionEnabled = false;
            NSAutomaticPeriodSubstitutionEnabled = false;
            NSAutomaticWindowAnimationsEnabled = false;
        };

        WindowManager = {
            GloballyEnabled = false;
            EnableStandardClickToShowDesktop = false;
            EnableTilingByEdgeDrag = false;
        };

        spaces.spans-displays = true;
    };

    # --- Fonts ---
    fonts.packages = with pkgs; [
        sketchybar-app-font
        nerd-fonts.symbols-only
        nerd-fonts.jetbrains-mono
        nerd-fonts.hack
        courier-prime
    ];

    # --- Homebrew ---
    homebrew = {
        enable = true;
        caskArgs.no_quarantine = true;
        global.brewfile = true;
        onActivation.cleanup = "zap";

        casks = [
            "zoom"
            "sf-symbols"
            "skim"
            "karabiner-elements"
        ];
    };
}
