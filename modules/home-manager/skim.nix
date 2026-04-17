{ pkgs, lib, ... }: {
    home.packages = with pkgs; [
        ocamlPackages.cpdf
        pdftk
        poppler-utils
    ];

    targets.darwin.defaults."net.sourceforge.skim-app.skim" = {
        # --- File Monitoring & Reloading ---
        SKAutoCheckFileUpdate = true;
        SKAutoReloadFileUpdate = true;

        # --- System & Window Behaviors ---
        NSQuitAlwaysKeepsWindows = true;
        SKDisableAnimations = true;
        SKInitialWindowSizeOption = 0;
        AppleWindowTabbingMode = "always";

        # --- Document Memory & Defaults ---
        SKRememberDefaults = false;
        SKRememberLastPageView = false;
        SKRememberLastPageViewed = true;
        SKUseSettingsFromPDF = false;

        # --- Custom Keybindings ---
        NSUserKeyEquivalents = {
            "Find Next" = "~@g";
            "Find Previous" = "~@h";
            "Find..." = "~@f";
            "Horizontal Continuous" = "^~@3";
            "Single Page Continuous" = "^~@1";
            "Two Pages Continuous" = "^~@2";
            "Move Tab to New Window" = "^~@n";
            "Close Tab" = "^~@w";
        };

        # --- Visual & Display Preferences ---
        SKAutoScales = true;
        SKDisplaysPageBreaks = false;
        SKInvertColorsInDarkMode = false;
        SKScrollStep = 150;
        SKSepiaTone = false;
        SKShowStatusBar = false;
        SKSnapshotThumbnailSize = 32;
        SKThumbnailSize = 32;
        SKAutoCropBoxMarginHeight = 1;
        SKAutoCropBoxMarginWidth = 1;

        # --- Colors & Margins ---
        SKWhitePoint = [ 1.0 1.0 1.0 1.0 ];
        SKBackgroundColor = [ 1.0 1.0 1.0 1.0 ];
        SKPageMargins = [ 0.0 0.0 ];

        # --- Default Display Settings ---
        SKDefaultPDFDisplaySettings = {
            autoScales = true;
            displayBox = 1;
            displayDirection = 0;
            displayMode = 1;
            displaysAsBook = false;
            displaysPageBreaks = true;
            displaysRTL = false;
            scaleFactor = 1.0;
        };
    };
}
