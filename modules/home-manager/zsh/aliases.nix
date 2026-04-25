{
    ls = "ls --color=auto -F";
    la = "ls -lhAr --color=auto -F";
    exit = "closeWindow";

    nixs = "sudo darwin-rebuild switch --flake ~/iCloud/Dotfiles#puppy; aerospace reload-config; sketchybar --reload";
    nixu = "pushd ~/iCloud/Dotfiles; nix flake update; nixs; popd";
    nixd = "sudo nix-env -p /nix/var/nix/profiles/system --delete-generations old; nix-collect-garbage -d; nixs";

    zoom = "open -a zoom.us";
    skim = "open -a Skim";
}
