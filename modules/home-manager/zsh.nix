{ pkgs, lib, ... }: {
    home.packages = with pkgs; [ coreutils btop ];
    home.activation = import ./zsh/activation.nix { inherit pkgs lib; };

    programs.zsh = {
        enable = true;
        enableCompletion = false;
        autosuggestion.enable = true;
        syntaxHighlighting.enable = true;

        dotDir = "/Users/zhao/.config/zsh";
        history.path = "/Users/zhao/.config/zsh/.zsh_history";
        shellAliases = import ./zsh/aliases.nix;
        initContent = lib.mkBefore (builtins.readFile ./zsh/init.sh);
    };
}
