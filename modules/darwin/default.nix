{pkgs, ... }: {
    # Nix stuff (do not touch!)
    nixpkgs.hostPlatform = "aarch64-darwin";
    nix.extraOptions = "experimental-features = nix-command flakes";
    nix.enable = false;
    system.stateVersion = 6;

    # Sudo with touch id
    security.pam.services.sudo_local.touchIdAuth = true;

    # User
    system.primaryUser = "zhao";
    users.users.zhao = {
        name = "zhao";
        home = "/Users/zhao";
    };

    # Shell
    programs.zsh.enable = true;
    environment = {
        shells = [ pkgs.zsh ];
        variables = {
            EDITOR = "nvim";
            VISUAL = "nvim";
            TERMINAL = "alacritty";
        };
    };

    # Keyboard settings
    system.keyboard = {
        enableKeyMapping = true;
        remapCapsLockToEscape = true;
    };

    # MacOS settings
    system.defaults = {
        dock = {
            autohide = true;
            mru-spaces = false;
            wvous-tr-corner = 1;
            wvous-tl-corner = 1;
            wvous-br-corner = 1;
            wvous-bl-corner = 1;
            expose-group-apps = false;
            showMissionControlGestureEnabled = false;
        };

        trackpad = {
            Clicking = true;
            Dragging = true;
            TrackpadPinch = true;
            TrackpadRightClick = true;
        };

        finder = {
            AppleShowAllExtensions = true;
            QuitMenuItem = true;
        };

        WindowManager = {
            GloballyEnabled = false;
            EnableStandardClickToShowDesktop = false;
            EnableTilingByEdgeDrag = false;
            EnableTopTilingByEdgeDrag = false;
            EnableTiledWindowMargins = false;
            EnableTilingOptionAccelerator = false;
        };

        CustomUserPreferences = {
            "com.apple.spaces".spans-displays = false;
            "com.apple.dock".workspaces-auto-swoosh = false;
        };

        NSGlobalDomain = {
            AppleShowAllFiles = true;
            AppleShowAllExtensions = true;
            AppleSpacesSwitchOnActivate = false;
            AppleWindowTabbingMode = "always";
            InitialKeyRepeat = 15;
            KeyRepeat = 1;
            NSAutomaticSpellingCorrectionEnabled = false;
            NSAutomaticCapitalizationEnabled = false;
            NSAutomaticQuoteSubstitutionEnabled = false;
            NSAutomaticDashSubstitutionEnabled = false;
            NSAutomaticPeriodSubstitutionEnabled = false;
            NSAutomaticWindowAnimationsEnabled = false;
            "com.apple.springing.enabled" = false;
            "com.apple.swipescrolldirection" = true;
        };
    };
}
