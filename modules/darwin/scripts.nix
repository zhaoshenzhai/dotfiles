{ pkgs, ... }: let
    scriptsDir = ../scripts;

    launcher = pkgs.writeShellApplication {
        name = "launcher";
        runtimeInputs = with pkgs; [ fd fzf coreutils gnused gawk gnugrep ];
        checkPhase = "";
        text = builtins.readFile "${scriptsDir}/launcher.sh";
    };

    pdfcp = pkgs.writeShellApplication {
        name = "pdfcp";
        runtimeInputs = with pkgs; [ ghostscript coreutils gnused gawk ];
        checkPhase = "";
        text = builtins.readFile "${scriptsDir}/pdfcp.sh";
    };

    newLatex = pkgs.writeShellApplication {
        name = "newLatex";
        runtimeInputs = with pkgs; [ coreutils gnused ];
        checkPhase = "";
        text = builtins.readFile "${scriptsDir}/newLaTeX.sh";
    };

    centerWindow = pkgs.runCommandCC "centerWindow" {} ''
        mkdir -p $out/bin
        $CC -O3 ${scriptsDir}/window/centering.m -framework Cocoa -o $out/bin/centerWindow
    '';

    texManager = pkgs.runCommandCC "texManager" {} ''
        mkdir -p $out/bin
        $CC -O3 ${scriptsDir}/texManager/main.c ${scriptsDir}/texManager/compiler.c -o $out/bin/texManager
    '';

    skimUtils = pkgs.runCommandCC "skimUtils" {} ''
        mkdir -p $out/bin
        $CC -O3 -fobjc-arc \
            ${scriptsDir}/skimUtils/main.m ${scriptsDir}/skimUtils/utils.m \
            ${scriptsDir}/skimUtils/search.m \
            ${scriptsDir}/skimUtils/moveTab.m \
            ${scriptsDir}/skimUtils/switchTab.m \
            ${scriptsDir}/skimUtils/switchFocus.m \
            ${scriptsDir}/skimUtils/openRelated.m \
            ${scriptsDir}/skimUtils/duplicateTab.m \
            ${scriptsDir}/skimUtils/cleanDuplicates.m \
            ${scriptsDir}/skimUtils/reopenLastClosed.m \
            -framework Cocoa -framework ScriptingBridge \
            -o $out/bin/skimUtils
    '';

    attic = pkgs.runCommandCC "attic" {
        buildInputs = with pkgs; [
            raylib
            cjson
            cm_unicode
        ];
    } ''
        mkdir -p $out/bin

        $CC -O3 -I${scriptsDir}/texManager \
            ${scriptsDir}/attic/main.c ${scriptsDir}/attic/commands.c \
            ${scriptsDir}/attic/memory.c ${scriptsDir}/attic/utils.c \
            ${scriptsDir}/texManager/compiler.c \
            -o $out/bin/attic

        FONT=$(find ${pkgs.cm_unicode} -type f \( -iname "cmunrm.ttf" -o -iname "cmunrm.otf" \) | head -n 1)

        $CC -O3 -fobjc-arc ${scriptsDir}/attic/graph/*.c ${scriptsDir}/window/transparency.m \
            -lraylib -lcjson -lpthread -DFONT_PATH="\"$FONT\"" \
            -framework CoreVideo -framework IOKit -framework Cocoa -framework GLUT \
            -framework OpenGL -framework QuartzCore -framework CoreImage \
            -o $out/bin/attic-graph
    '';

    transparentWindow = pkgs.runCommandCC "transparentWindow" {} ''
        mkdir -p $out/lib
        $CC -O3 -dynamiclib -framework Cocoa -framework QuartzCore -framework CoreImage \
            ${scriptsDir}/window/transparency.m -o $out/lib/transparentWindow.dylib
    '';

    alacrittyDaemon = pkgs.writeShellApplication {
        name = "alacrittyDaemon";
        runtimeInputs = with pkgs; [ coreutils ];
        checkPhase = "";
        text = ''
            export DYLD_INSERT_LIBRARIES="${transparentWindow}/lib/transparentWindow.dylib"
            ${builtins.readFile "${scriptsDir}/daemon.sh"}
        '';
    };
in
{
    environment.systemPackages = [
        alacrittyDaemon
        launcher
        pdfcp
        newLatex
        centerWindow
        texManager
        skimUtils
        attic
    ];
}
