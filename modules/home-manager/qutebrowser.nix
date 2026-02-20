{ pkgs, lib, ... }: {
    programs.qutebrowser = {
        enable = true;
        loadAutoconfig = false;
        package = pkgs.runCommand "qutebrowser-dummy" {} "mkdir $out";

        searchEngines = {
            DEFAULT = "https://www.google.com/search?q={}";
            yt = "https://www.youtube.com/results?search_query={}";
        };

        settings = {
            url.start_pages = [ "https://google.com" ];
            url.default_page = "https://google.com";
            "auto_save.session" = false;
            "qt.args" = [ 
                "disable-gpu-driver-bug-workarounds"
                "enable-native-gpu-memory-buffers"
                "num-raster-threads=4"
            ];

            statusbar.show = "always";
            tabs.show = "multiple";
            tabs.favicons.scale = 0.9;
            tabs.indicator.width = 0;
            tabs.max_width = 350;
            zoom.default = "100%";
            scrolling.smooth = true;

            fonts = {
                default_family = "Courier Prime";
                default_size = "20pt";
                tabs.selected = "bold default_size default_family";
                tabs.unselected = "bold default_size default_family";
                statusbar = "bold default_size default_family";
            };

            editor.command = [ "alacritty" "-e" "nvim" "{}" ];
            fileselect.handler = "external";

            fileselect.single_file.command = [
                "${pkgs.alacritty}/bin/alacritty"
                "--title" "vifm-float"
                "--option" "window.dimensions={columns=100,lines=35}"
                "--option" "window.position={x=525,y=250}"
                "-e" "${pkgs.vifm}/bin/vifm"
                "-c" ":only"
                "--choose-files" "{}"
            ];
            fileselect.multiple_files.command = [
                "${pkgs.alacritty}/bin/alacritty"
                "--title" "vifm-float"
                "--option" "window.dimensions={columns=100,lines=35}"
                "--option" "window.position={x=525,y=250}"
                "-e" "${pkgs.vifm}/bin/vifm"
                "-c" ":set nodotfiles | filter Applications|Desktop|Documents|Library|Movies|Music|Pictures | :only"
                "--choose-files" "{}"
            ];

            downloads.remove_finished = 1000;
            downloads.location.directory = "~/Downloads";
            downloads.prevent_mixed_content = false;

            content.fullscreen.window = true;
            content.tls.certificate_errors = "block";
            colors.webpage.preferred_color_scheme = "dark";

            colors = {
                messages = {
                    info.bg = "#1e2127";
                    warning.bg = "#1e2127";
                    error.bg = "#1e2127";
                    info.border = "#1e2127";
                    warning.border = "#1e2127";
                    error.border = "#1e2127";
                    warning.fg = "#a8a8aa";
                };
                statusbar = {
                    normal.bg = "#1e2127";
                    normal.fg = "#a8a8aa";
                    insert.bg = "#1e2127";
                    insert.fg = "#a8a8aa";
                    command.bg = "#1e2127";
                    command.fg = "#a8a8aa";
                    url.fg = "#a8a8aa";
                    url.hover.fg = "#f8f8ff";
                    url.success.http.fg = "#a8a8aa";
                    url.success.https.fg = "#a8a8aa";
                };
                tabs = {
                    bar.bg = "#1e2127";
                    even.bg = "#1e2127";
                    odd.bg = "#1e2127";
                    even.fg = "#a8a8a8";
                    odd.fg = "#a8a8a8";
                    selected.even.bg = "#1e2127";
                    selected.odd.bg = "#1e2127";
                    selected.even.fg = "#f8f8ff";
                    selected.odd.fg = "#f8f8ff";
                    pinned = {
                        even.bg = "#1e2127";
                        odd.bg = "#1e2127";
                        even.fg = "#a8a8a8";
                        odd.fg = "#a8a8a8";
                        selected.even.bg = "#1e2127";
                        selected.odd.bg = "#1e2127";
                        selected.even.fg = "#f8f8ff";
                        selected.odd.fg = "#f8f8ff";
                    };
                };
                completion = {
                    fg = "#abb2bf";
                    odd.bg = "#1e2127";
                    even.bg = "#1e2127";
                    match.fg = "#e06c75";

                    category = {
                        fg = "#61afef";
                        bg = "#1e2127";
                        border.top = "#1e2127";
                        border.bottom = "#1e2127";
                    };

                    item.selected = {
                        fg = "#282c34";
                        bg = "#98c379";
                        border.top = "#98c379";
                        border.bottom = "#98c379";
                        match.fg = "#e06c75";
                    };

                    scrollbar = {
                        fg = "#abb2bf";
                        bg = "#1e2127";
                    };
                };
                prompts.bg = "#1e2127";
                downloads.bar.bg = "#1e2127";
            };
        };

        # Key Bindings
        keyBindings = {
            normal = {
                "<Ctrl+Return>" = "cmd-set-text -s :open -t";

                "<Ctrl+=>" = "zoom-in";
                "<Ctrl+->" = "zoom-out";
                "<Ctrl+0>" = "zoom 100";
                
                "<Ctrl+h>" = "back";
                "<Ctrl+l>" = "forward";
                "<Ctrl+j>" = "tab-prev";
                "<Ctrl+k>" = "tab-next";
                "<Ctrl+w>" = "tab-close";
                "<Ctrl+u>" = "cmd-repeat 20 scroll up";
                "<Ctrl+d>" = "cmd-repeat 20 scroll down";
                
                "<Ctrl+Shift+r>" = "restart";
                "<Ctrl+`>" = "config-cycle statusbar.show always never;; config-cycle tabs.show multiple never";

                "<Ctrl+1>" = "tab-select 1";
                "<Ctrl+2>" = "tab-select 2";
                "<Ctrl+3>" = "tab-select 3";
                "<Ctrl+4>" = "tab-select 4";
                "<Ctrl+5>" = "tab-select 5";
                "<Ctrl+6>" = "tab-select 6";
                "<Ctrl+7>" = "tab-select 7";
                "<Ctrl+8>" = "tab-select 8";
                "<Ctrl+9>" = "tab-select 9";

                "<Ctrl+q>" = "nop";
            };
            command = {
                "<Ctrl+j>" = "completion-item-focus next";
                "<Ctrl+k>" = "completion-item-focus prev";
                "<Ctrl+q>" = "mode-enter normal";
            };
        };

        # extraConfig = ''
        #     # Qt overrides the macOS dock icon with a non-tintable raster image at runtime.
        #     # We use ctypes to directly call the macOS Objective-C API to remove this 
        #     # runtime override, allowing macOS to fall back to the dynamic/tintable .icns file.
        #     def release_mac_dock_icon():
        #         try:
        #             import ctypes
        #             import ctypes.util

        #             objc_path = ctypes.util.find_library('objc')
        #             if not objc_path: return
        #             objc = ctypes.cdll.LoadLibrary(objc_path)

        #             # Strictly define argtypes and restype for ARM64 (Apple Silicon) compatibility
        #             objc.objc_getClass.restype = ctypes.c_void_p
        #             objc.objc_getClass.argtypes = [ctypes.c_char_p]
        #             objc.sel_registerName.restype = ctypes.c_void_p
        #             objc.sel_registerName.argtypes = [ctypes.c_char_p]

        #             # Cast objc_msgSend to the exact function signatures required
        #             msgSend_sharedApp = ctypes.cast(objc.objc_msgSend, ctypes.CFUNCTYPE(ctypes.c_void_p, ctypes.c_void_p, ctypes.c_void_p))
        #             msgSend_setIcon = ctypes.cast(objc.objc_msgSend, ctypes.CFUNCTYPE(None, ctypes.c_void_p, ctypes.c_void_p, ctypes.c_void_p))

        #             NSApplication = objc.objc_getClass(b"NSApplication")
        #             sharedApp_sel = objc.sel_registerName(b"sharedApplication")
        #             setIcon_sel = objc.sel_registerName(b"setApplicationIconImage:")

        #             # Execute: app = [NSApplication sharedApplication]
        #             app = msgSend_sharedApp(NSApplication, sharedApp_sel)
        #             
        #             # Execute: [app setApplicationIconImage:nil]
        #             msgSend_setIcon(app, setIcon_sel, None)
        #         except Exception:
        #             pass

        #     try:
        #         try:
        #             from PyQt6.QtCore import QTimer
        #         except ImportError:
        #             from PyQt5.QtCore import QTimer
        #         
        #         # Wait 1 second to ensure Qutebrowser has completely finished loading
        #         QTimer.singleShot(1000, release_mac_dock_icon)
        #     except Exception:
        #         pass
        # '';
    };

    home.file = {
        ".qutebrowser/quickmarks".source = ./qutebrowser/quickmarks;
    };

    home.activation.installQutebrowserBookmarks = lib.hm.dag.entryAfter ["writeBoundary"] ''
        DATA_DIR="$HOME/.qutebrowser/bookmarks"
        mkdir -p "$DATA_DIR"
        cp -f "${./qutebrowser/bookmarks}" "$DATA_DIR/urls"
        chmod u+w "$DATA_DIR/urls"
    '';

    home.activation.injectQutebrowserIcns = lib.hm.dag.entryAfter ["writeBoundary"] ''
        APP_PATH="/Applications/qutebrowser.app"
        if [ -d "$APP_PATH" ]; then
            cp -f "${./qutebrowser/qutebrowser.icns}" "$APP_PATH/Contents/Resources/qutebrowser.icns"
            touch "$APP_PATH"
            touch "$APP_PATH/Contents/Info.plist"
        fi
    '';
}
