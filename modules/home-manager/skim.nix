{ pkgs, lib, ... }: {
    home.packages = with pkgs; [
        ocamlPackages.cpdf
        pdftk
        poppler-utils
        (writeShellScriptBin "skim-focus-daemon" ''
            PIPE="/tmp/skim_focus_pipe"
            rm -f "$PIPE"
            mkfifo "$PIPE"

            ORIGINAL_COLOR="0"
            PREV_APP=""
            ENABLED=0

            while true; do
                if read -r PAYLOAD < "$PIPE"; then
                    [ -z "$PAYLOAD" ] && continue

                    if [ "$PAYLOAD" == "TOGGLE_STATE" ]; then
                        if [ "$ENABLED" -eq 1 ]; then
                            ENABLED=0
                        else
                            ENABLED=1
                        fi
                        continue
                    elif [ "$PAYLOAD" == "DISABLE_STATE" ]; then
                        ENABLED=0
                        continue
                    fi

                    FOCUSED_APP="$PAYLOAD"

                    if [ "$FOCUSED_APP" != "$PREV_APP" ]; then

                        if [ "$ENABLED" -eq 1 ]; then
                            if [ "$PREV_APP" == "Skim" ]; then
                                ORIGINAL_COLOR=$(defaults read net.sourceforge.skim-app.skim SKInvertColorsInDarkMode 2>/dev/null || echo 0)

                                # if [ "$FOCUSED_APP" == "alacritty" ]; then
                                    if [ "$ORIGINAL_COLOR" != "1" ]; then
                                        defaults write net.sourceforge.skim-app.skim SKInvertColorsInDarkMode -bool true
                                    fi
                                # fi
                            fi

                            if [ "$FOCUSED_APP" == "Skim" ]; then
                                CURRENT=$(defaults read net.sourceforge.skim-app.skim SKInvertColorsInDarkMode 2>/dev/null || echo 0)
                                if [ "$CURRENT" != "$ORIGINAL_COLOR" ]; then
                                    if [ "$ORIGINAL_COLOR" == "1" ]; then
                                        defaults write net.sourceforge.skim-app.skim SKInvertColorsInDarkMode -bool true
                                    else
                                        defaults write net.sourceforge.skim-app.skim SKInvertColorsInDarkMode -bool false
                                    fi
                                fi
                            fi
                        fi

                        PREV_APP="$FOCUSED_APP"
                    fi
                fi
            done
        '')
    ];

    targets.darwin.defaults."net.sourceforge.skim-app.skim" = {
        SKUISetupPreferTabs = 1;

        SKWhitePoint = [0.99 0.995 1 0.95];
        SKDisableAnimations = true;

        SKTeXEditorPreset = "Custom";
        SKTeXEditorCommand = "${pkgs.neovim-remote}/bin/nvr";
        SKTeXEditorArguments = "--remote-silent +%line \"%file\"";

        SKAutoCheckFileUpdate = true;
        SKAutoReloadFileUpdate = true;

        SKRememberLastPageView = true;
        SKRememberDefaults = false;

        SKInitialPDFViewSettings = {
            displayMode = 1;
            displaysAsBook = false;
            displaysPageBreaks = false;
        };
    };
}
