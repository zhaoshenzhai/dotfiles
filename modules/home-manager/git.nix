{ pkgs, ... }: {
    programs.git = {
        enable = true;

        settings.user.name = "Zhaoshen Zhai";
        settings.user.email = "zhaoshen.zhai@gmail.com";
        settings.credential.helper = "osxkeychain";

        extraConfig = {
            credential.helper = "osxkeychain";
            url = {
                "https://zhaoshenzhai@github.com" = {
                    insteadOf = "https://github.com";
                };
            };
            
            init.defaultBranch = "main";
            push.autoSetupRemote = true;
          };
    };
    xdg.configFile."git/config".source = config.lib.file.mkOutOfStoreSymlink config.home.homeDirectory + "/.config/git/config";
}
