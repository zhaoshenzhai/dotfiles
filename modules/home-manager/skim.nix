{ pkgs, lib, ... }: {
    home.packages = with pkgs; [
        ocamlPackages.cpdf
        pdftk
        poppler-utils

        (writeShellScriptBin "skim-focus-hook" ''
            FOCUSED_APP=$(aerospace list-windows --focused --format "%{app-bundle-id}" 2>/dev/null)
            STATE_FILE="/tmp/skim_last_focused_app"
            COLOR_STATE_FILE="/tmp/skim_original_color_state"
            PREV_APP=$(cat "$STATE_FILE" 2>/dev/null || echo "")

            if [ "$FOCUSED_APP" != "$PREV_APP" ]; then
                if [ "$PREV_APP" == "net.sourceforge.skim-app.skim" ]; then
                    CURRENT=$(defaults read net.sourceforge.skim-app.skim SKInvertColorsInDarkMode 2>/dev/null || echo 0)
                    echo "$CURRENT" > "$COLOR_STATE_FILE"

                    if [ "$CURRENT" != "1" ]; then
                        defaults write net.sourceforge.skim-app.skim SKInvertColorsInDarkMode -bool true
                    fi
                elif [ "$FOCUSED_APP" == "net.sourceforge.skim-app.skim" ]; then
                    ORIGINAL=$(cat "$COLOR_STATE_FILE" 2>/dev/null || echo 0)
                    CURRENT=$(defaults read net.sourceforge.skim-app.skim SKInvertColorsInDarkMode 2>/dev/null || echo 0)

                    if [ "$CURRENT" != "$ORIGINAL" ]; then
                        if [ "$ORIGINAL" == "1" ]; then
                            defaults write net.sourceforge.skim-app.skim SKInvertColorsInDarkMode -bool true
                        else
                            defaults write net.sourceforge.skim-app.skim SKInvertColorsInDarkMode -bool false
                        fi
                    fi
                fi

                echo "$FOCUSED_APP" > "$STATE_FILE"
            fi
        '')
    ];

    targets.darwin.defaults."net.sourceforge.skim-app.skim" = {
        SKUISetupPreferTabs = 1;

        SKWhitePoint = [0.99 0.995 1 0.95];

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
