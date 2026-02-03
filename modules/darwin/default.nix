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
            DBUS_SESSION_BUS_ADDRESS = "unix:path=/Users/zhao/.cache/dbus-session-socket";
        };
        systemPackages = [
            pkgs.dbus
        ];
    };

    # --- Security & Input ---
    security.pam.services.sudo_local.touchIdAuth = true;

    system.keyboard = {
        enableKeyMapping = true;
        remapCapsLockToEscape = true;
    };

    # --- macOS System Defaults ---
    system.defaults = {
        dock = {
            autohide = true;
            mru-spaces = false;
            showMissionControlGestureEnabled = false;
            expose-group-apps = false;
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
            AppleWindowTabbingMode = "always";

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
    };

    # --- Homebrew ---
    homebrew = {
        enable = true;
        caskArgs.no_quarantine = true;
        global.brewfile = true;
        onActivation.cleanup = "zap";

        casks = [
            "zoom"
        ];
    };

    # --- Dbus ---
    launchd.user.agents.dbus = {
        serviceConfig = {
            ProgramArguments = [
                "${pkgs.dbus}/bin/dbus-daemon"
                "--session"
                "--address=unix:path=/Users/zhao/.cache/dbus-session-socket"
                "--nofork"
            ];
            KeepAlive = true;
            ProcessType = "Interactive";
        };
    };
}
