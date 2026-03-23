{ pkgs, ... }: let
    pdfcp = pkgs.writeShellApplication {
        name = "pdfcp";
        runtimeInputs = with pkgs; [
            ghostscript
            coreutils
            gnused
            gawk
        ];
        checkPhase = "";
        text = builtins.readFile ./pdfcp.sh;
    };

    newLatex = pkgs.writeShellApplication {
        name = "newLatex";
        runtimeInputs = with pkgs; [
            coreutils
            gnused
        ];
        checkPhase = "";
        text = builtins.readFile ./newLaTeX.sh;
    };

    attic = pkgs.writeShellScriptBin "attic" (builtins.readFile ./attic.sh);
    skimUtils = pkgs.writeShellScriptBin "skimUtils" (builtins.readFile ./skimUtils.sh);
in
{
    environment.systemPackages = [
        pdfcp
        newLatex
        attic
        skimUtils
    ];
}
