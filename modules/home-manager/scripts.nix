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

    skimUtils = pkgs.writeShellApplication {
        name = "skimUtils";
        runtimeInputs = with pkgs; [ coreutils ];
        checkPhase = "";
        text = builtins.readFile "${scriptsDir}/skimUtils.sh";
    };

    attic = pkgs.runCommandCC "attic" {
        buildInputs = with pkgs; [
            raylib
            cjson
            courier-prime
            cm_unicode
        ];
    } ''
        mkdir -p $out/bin

        $CC -O3 ${scriptsDir}/attic/main.c ${scriptsDir}/attic/commands.c \
            ${scriptsDir}/attic/memory.c ${scriptsDir}/attic/utils.c \
            -o $out/bin/attic

        MAIN_FONT=$(find ${pkgs.cm_unicode} -type f \( -iname "cmunrm.ttf" -o -iname "cmunrm.otf" \) | head -n 1)
        ID_FONT=$(find ${pkgs.courier-prime} -type f \( -iname "*Regular.ttf" -o -iname "*Regular.otf" \) | head -n 1)

        $CC -O3 ${scriptsDir}/attic/graph/*.c -lraylib -lcjson \
            -DFONT_PATH_MAIN="\"$MAIN_FONT\"" \
            -DFONT_PATH_ID="\"$ID_FONT\"" \
            -framework CoreVideo -framework IOKit -framework Cocoa -framework GLUT -framework OpenGL \
            -o $out/bin/attic-graph
    '';
in
{
    environment.systemPackages = [
        pdfcp
        newLatex
        skimUtils
        launcher
        attic
    ];
}
