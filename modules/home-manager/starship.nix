{ pkgs, ... }: {
    programs.starship = {
        enable = true;
        enableZshIntegration = true;
        settings = {
            format = "$directory$line_break$username$hostname$character";

            username = {
                show_always = true;
                format = "[$user]($style)@";
                style_user = "bold cyan";
            };

            hostname = {
                ssh_only = false;
                format = "[$hostname]($style) ";
                style = "bold purple";
                ssh_symbol = "";
            };

            directory = {
                style = "blue";
                truncate_to_repo = false;
                truncation_length = 20;
                truncation_symbol = "…/";
                read_only = " 🔒";
            };

            character = {
                success_symbol = "[➜](bold green)";
                error_symbol = "[➜](bold red)";
            };
        };
    };
}
