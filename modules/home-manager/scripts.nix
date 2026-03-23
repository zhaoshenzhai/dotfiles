{ pkgs, ... }: let
    scriptsDir = ../scripts;

    launcher = pkgs.writeShellApplication {
        name = "launcher";
        runtimeInputs = with pkgs; [ fd fzf coreutils gnused gawk gnugrep ];
        checkPhase = "";
        text = builtins.readFile "${scriptsDir}/launcher.sh";
    };

    gitMenu = pkgs.writeShellApplication {
        name = "gitMenu";
        runtimeInputs = with pkgs; [ git coreutils gnused gawk gnugrep ];
        checkPhase = "";
        text = builtins.readFile "${scriptsDir}/git.sh";
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

    attic = pkgs.writeShellApplication {
        name = "attic";
        runtimeInputs = with pkgs; [ texlive.combined.scheme-full fd coreutils gnused gawk findutils ];
        checkPhase = "";
        text = builtins.readFile "${scriptsDir}/attic.sh";
    };

    skimUtils = pkgs.writeShellApplication {
        name = "skimUtils";
        runtimeInputs = with pkgs; [ coreutils ];
        checkPhase = "";
        text = builtins.readFile "${scriptsDir}/skimUtils.sh";
    };
in
{
    environment.systemPackages = [
        pdfcp
        newLatex
        attic
        skimUtils
        gitMenu
        launcher
    ];
}
