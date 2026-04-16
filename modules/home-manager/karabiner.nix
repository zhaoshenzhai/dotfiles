{ ... }:
let
    spotlight = import ./karabiner/spotlight.nix;
    qutebrowser = import ./karabiner/qutebrowser.nix;
    skim = import ./karabiner/skim.nix;
    system = import ./karabiner/system.nix;
in {
    xdg.configFile."karabiner/karabiner.json" = {
        force = true;
        text = builtins.toJSON {
            profiles = [
                {
                    name = "Default profile";
                    selected = true;
                    complex_modifications = {
                        rules = [
                            spotlight
                            qutebrowser
                            skim
                            system
                        ];
                    };
                }
            ];
        };
    };
}
