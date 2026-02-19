{ pkgs, lib, ... }: {
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
            autoScales = true;
            displayMode = 1;
            displaysAsBook = false;
        };
    };
}
