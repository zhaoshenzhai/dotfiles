{ pkgs, ... }: {
    programs.starship = {
        enable = true;
        enableZshIntegration = true;
        settings = {
            format = "\${custom.dir}$username$hostname$character";

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
                format = "[$path]($style)[$read_only]($read_only_style)";
            };

            custom.dir = {
                command = "starship module directory";
                when = "[ \"$PWD\" != \"$HOME\" ]";
                format = "$output\n";
            };

            character = {
                success_symbol = "[➜](bold green)";
                error_symbol = "[➜](bold red)";
            };
        };
    };
}
