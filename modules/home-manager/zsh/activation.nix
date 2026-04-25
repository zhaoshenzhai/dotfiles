{ pkgs, lib, ... }: {
    zcompileCache = lib.hm.dag.entryAfter ["writeBoundary"] ''
        $DRY_RUN_CMD ${pkgs.zsh}/bin/zsh -c '
            ZDIR="/Users/zhao/.config/zsh"
            [[ -f "$ZDIR/.zshenv" ]] && zcompile -M "$ZDIR/.zshenv"
            [[ -f "$ZDIR/.zshrc" ]] && zcompile -M "$ZDIR/.zshrc"
            [[ -f "$ZDIR/.zcompdump" ]] && zcompile -M "$ZDIR/.zcompdump"
        '
    '';
}
