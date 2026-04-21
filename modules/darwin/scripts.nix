{ pkgs, ... }: let
    scriptsDir = ../scripts;

    transparentWindow = pkgs.runCommandCC "transparentWindow" {} ''
        mkdir -p $out/lib
        $CC -O3 -dynamiclib -framework Cocoa -framework ScreenCaptureKit -framework CoreMedia -framework QuartzCore -framework CoreImage \
        ${scriptsDir}/window/transparency.m -o $out/lib/transparentWindow.dylib
    '';

    centerWindow = pkgs.runCommandCC "centerWindow" {} ''
        mkdir -p $out/bin
        $CC -O3 -framework Cocoa ${scriptsDir}/window/centering.m -o $out/bin/centerWindow
    '';

    launcher = pkgs.runCommandCC "launcher" {} ''
        mkdir -p $out/bin
        $CC -O3 -fobjc-arc -DFD_PATH="\"${pkgs.fd}/bin/fd\"" -DFZF_PATH="\"${pkgs.fzf}/bin/fzf\"" \
            -framework ApplicationServices -framework Foundation -framework AppKit \
            -I${scriptsDir} -I${scriptsDir}/commonUtils \
            ${scriptsDir}/commonUtils/*.m ${scriptsDir}/launcher.m -o $out/bin/launcher
    '';

    texManager = pkgs.runCommandCC "texManager" {} ''
        mkdir -p $out/bin
        $CC -O3 -fobjc-arc -framework ApplicationServices -framework Foundation -framework AppKit \
            -I${scriptsDir} -I${scriptsDir}/commonUtils \
            ${scriptsDir}/commonUtils/*.m ${scriptsDir}/texManager/*.m -o $out/bin/texManager
    '';

    skimUtils = pkgs.runCommandCC "skimUtils" {} ''
        mkdir -p $out/bin
        $CC -O3 -fobjc-arc -framework ApplicationServices -framework ScriptingBridge -framework Cocoa \
            -I${scriptsDir} -I${scriptsDir}/commonUtils \
            ${scriptsDir}/commonUtils/*.m ${scriptsDir}/skimUtils/*.m -o $out/bin/skimUtils
    '';

    pdfcp = pkgs.runCommandCC "pdfcp" {} ''
        mkdir -p $out/bin
        $CC -O3 -fobjc-arc -framework ApplicationServices -framework Foundation -framework AppKit \
            -I${scriptsDir} -I${scriptsDir}/commonUtils \
            ${scriptsDir}/commonUtils/*.m ${scriptsDir}/pdfcp.m -o $out/bin/pdfcp
    '';

    alacrittyDaemon = pkgs.runCommandCC "alacrittyDaemon" { nativeBuildInputs = [ pkgs.makeWrapper ]; } ''
        mkdir -p $out/bin
        $CC -O3 -fobjc-arc -framework ApplicationServices -framework Foundation -framework AppKit \
            -I${scriptsDir} -I${scriptsDir}/commonUtils \
            ${scriptsDir}/commonUtils/*.m ${scriptsDir}/window/alacrittyDaemon.m -o $out/bin/.alacrittyDaemon-unwrapped
        makeWrapper $out/bin/.alacrittyDaemon-unwrapped $out/bin/alacrittyDaemon \
            --set DYLD_INSERT_LIBRARIES "${transparentWindow}/lib/transparentWindow.dylib"
    '';

    attic = pkgs.runCommandCC "attic" { buildInputs = with pkgs; [ raylib cjson cm_unicode ]; } ''
        mkdir -p $out/bin
        $CC -O3 -fobjc-arc -framework ApplicationServices -framework Foundation -framework AppKit \
            -I${scriptsDir} -I${scriptsDir}/commonUtils -I${scriptsDir}/texManager \
            ${scriptsDir}/commonUtils/*.m ${scriptsDir}/texManager/compiler.m ${scriptsDir}/attic/*.m -o $out/bin/attic

        FONT=$(find ${pkgs.cm_unicode} -type f \( -iname "cmunrm.ttf" -o -iname "cmunrm.otf" \) | head -n 1)
        $CC -O3 -fobjc-arc -lraylib -lcjson -lpthread -DFONT_PATH="\"$FONT\"" \
            -framework ScreenCaptureKit -framework CoreMedia -framework CoreVideo -framework IOKit -framework Cocoa -framework GLUT \
            -framework OpenGL -framework QuartzCore -framework CoreImage -framework ApplicationServices \
            -I${scriptsDir} -I${scriptsDir}/commonUtils \
            ${scriptsDir}/commonUtils/*.m ${scriptsDir}/window/transparency.m ${scriptsDir}/attic/graph/*.m \
            -o $out/bin/attic-graph
    '';
in
{
    environment.systemPackages = [
        launcher
        centerWindow
        texManager
        skimUtils
        attic
        pdfcp
        alacrittyDaemon
    ];
}
