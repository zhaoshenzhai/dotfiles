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
in
{
    environment.systemPackages = [
        pdfcp
        newLatex
    ];
}
