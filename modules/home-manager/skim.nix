{ pkgs, lib, ... }: {
    targets.darwin.defaults."net.sourceforge.skim-app.skim" = {
        # --- Appearance ---
        SKPageBackgroundColor = [ 0.0784 0.1020 0.1216 1.0 ];
        SKInvertColorsInDarkMode = true;

        # --- SyncTeX ---
        SKTeXEditorPreset = "Custom";
        SKTeXEditorCommand = "${pkgs.neovim-remote}/bin/nvr";
        SKTeXEditorArguments = "--remote-silent +%line \"%file\"";

        # --- Behavior & Initial Zoom ---
        SKAutoCheckFileUpdate = true;
        SKAutoReloadFileUpdate = true;
        SKAutoScales = true;
        SKRememberLastPageView = false;
        SKRememberDefaults = false;
        SKInitialPDFViewSettings = {
            displayMode = 2;
            autoScales = true;
        };
    };
}
