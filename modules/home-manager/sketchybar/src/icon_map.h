#ifndef ICON_MAP_H
#define ICON_MAP_H

#include <string.h>

static inline const char* get_icon_for_app(const char* app) {
    if (!app) return ":default:";
    
    // Custom
    if (strcmp(app, "qutebrowser")      == 0) return ":qute_browser:";
    if (strstr(app, "Karabiner")     != NULL) return ":karabiner_elements:";
    if (strcmp(app, "alacritty")        == 0) return ":terminal:";
    if (strcmp(app, "launcher")         == 0) return ":spotlight:";
    if (strcmp(app, "zoom.us")          == 0) return ":zoom:";
    if (strcmp(app, "Skim")             == 0) return ":book:";
    if (strcmp(app, "vifm")             == 0) return ":calibre:";
    if (strcmp(app, "btop")             == 0) return ":statistics:";
    if (strcmp(app, "git")              == 0) return ":git_hub:";
    if (strcmp(app, "mpv")              == 0) return ":mpv:";

    // macOS
    if (strcmp(app, "iPhone Mirroring") == 0) return ":iphone_mirroring:";
    if (strcmp(app, "System Settings")  == 0) return ":gear:";
    if (strcmp(app, "SecurityAgent")    == 0) return ":bruno:";
    if (strcmp(app, "Calculator")       == 0) return ":calculator:";
    if (strcmp(app, "SF Symbols")       == 0) return ":sf_symbols:";
    if (strcmp(app, "Reminders")        == 0) return ":reminders:";
    if (strcmp(app, "Spotlight")        == 0) return ":spotlight:";
    if (strcmp(app, "Passwords")        == 0) return ":passwords:";
    if (strcmp(app, "Calendar")         == 0) return ":calendar:";
    if (strcmp(app, "Messages")         == 0) return ":messages:";
    if (strcmp(app, "Preview")          == 0) return ":book:";
    if (strcmp(app, "Weather")          == 0) return ":weather:";
    if (strcmp(app, "Find My")          == 0) return ":find_my:";
    if (strcmp(app, "Safari")           == 0) return ":safari:";
    if (strcmp(app, "Finder")           == 0) return ":finder:";
    if (strcmp(app, "Music")            == 0) return ":music:";
    if (strcmp(app, "Notes")            == 0) return ":notes:";
    if (strcmp(app, "Mail")             == 0) return ":mail:";
    if (strcmp(app, "Tips")             == 0) return ":tips:";
    if (strstr(app, "Maps")          != NULL) return ":maps:";

    return ":default:";
}

#endif
