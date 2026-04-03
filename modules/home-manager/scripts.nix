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
        buildInputs = with pkgs; [ raylib ];
    } ''
        mkdir -p $out/bin

        $CC -O3 ${scriptsDir}/attic/main.c ${scriptsDir}/attic/commands.c ${scriptsDir}/attic/memory.c ${scriptsDir}/attic/utils.c -o $out/bin/attic

        $CC -O3 ${scriptsDir}/attic/graph.c ${scriptsDir}/attic/cJSON.c -lraylib -framework CoreVideo -framework IOKit -framework Cocoa -framework GLUT -framework OpenGL -o $out/bin/attic-graph
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
