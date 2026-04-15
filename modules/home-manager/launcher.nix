{ pkgs, lib, config, ... }:

let
    runtimePath = lib.makeBinPath [
        pkgs.fzf
        pkgs.neovim
        pkgs.alacritty
        pkgs.fd
        pkgs.gawk
        pkgs.coreutils
    ];

    launcher = pkgs.writeShellScriptBin "launcher" ''
        export PATH="${runtimePath}:/usr/bin:$PATH"
        export FZF_DEFAULT_OPTS="--color='bg+:-1,gutter:-1,pointer:#98c379'"

        ${builtins.readFile ../scripts/launcher.sh}
    '';
in
{
    home.packages = [
        launcher
        pkgs.fzf
        pkgs.fd
        pkgs.gawk
    ];
}
