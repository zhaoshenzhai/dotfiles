{ pkgs, ... }: let
    compress = pkgs.writeShellApplication {
        name = "compress";
        runtimeInputs = with pkgs; [
            ghostscript
            coreutils
            gnused
            gawk
        ];
        checkPhase = "";
        text = builtins.readFile ./compress.sh;
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
        compress
        newLatex
    ];
}
