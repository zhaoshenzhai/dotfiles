{ pkgs, ... }: 
let
    # Compile the helper C program included in your dotfiles
    sketchybar-helper = pkgs.stdenv.mkDerivation {
        name = "sketchybar-helper";
        src = ./sketchybar/helper;
        buildInputs = [ ];
        buildPhase = "clang -std=c99 -O3 helper.c -o helper";
        installPhase = ''
            mkdir -p $out/bin
            cp helper $out/bin/sketchybar-helper
        '';
    };
in
{
    # Add the helper to your path
    home.packages = [ sketchybar-helper ];

    # Link the entire configuration directory
    xdg.configFile."sketchybar" = {
        source = ./sketchybar;
        recursive = true;
    };
}
