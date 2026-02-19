{ pkgs, lib, ... }: {
    targets.darwin.defaults."net.sourceforge.skim-app.skim" = {
        SKUISetupPreferTabs = 1;
        AppleWindowTabbingMode = "manual";

        SKTeXEditorPreset = "Custom";
        SKTeXEditorCommand = "${pkgs.neovim-remote}/bin/nvr";
        SKTeXEditorArguments = "--remote-silent +%line \"%file\"";

        SKAutoCheckFileUpdate = true;
        SKAutoReloadFileUpdate = true;

        SKAutoScales = true;
        SKRememberLastPageView = false;
        SKRememberDefaults = false;
        SKInitialPDFViewSettings = {
            autoScales = true;
            displayMode = 2;
        };
    };
}
