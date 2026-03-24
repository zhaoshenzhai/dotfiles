#include "sketchybar.h"
#include "icon_map.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

void handler(env env) {
    char* name = env_get_value_for_key(env, "NAME");
    char* sender = env_get_value_for_key(env, "SENDER");
    char* info = env_get_value_for_key(env, "INFO");
    char* title = env_get_value_for_key(env, "TITLE");
    char* workspace = env_get_value_for_key(env, "AEROSPACE_FOCUSED_WORKSPACE");

    if (name[0] == '\0' || sender[0] == '\0' || strcmp(sender, "aerospace_custom_app_switched") != 0 || info[0] == '\0') { return; }


    if (title[0] != '\0' && strcasecmp(info, "alacritty") == 0) {
        if (strcmp(title, "launcher") == 0) { return; }
        else if (strcmp(title, "vifm") == 0) { info = "vifm"; }
        else if (strcmp(title, "vifm-float") == 0) { info = "vifm"; }
        else if (strcmp(title, "attic") == 0) { info = "attic"; }
        else if (strcmp(title, "btop") == 0) { info = "btop"; }
        else if (strcmp(title, "nvim") == 0) { info = "nvim"; }
        else if (strcmp(title, "git") == 0) { info = "git"; }
    }

    const char* icon = get_icon_for_app(info);

    char command[1024];
    snprintf(command, sizeof(command),
             "--animate tanh 8 --set %s label=\"%s\" icon=\"%s\" icon.font=\"sketchybar-app-font:Regular:16.0\"",
             name, info, icon);
    sketchybar(command);
}

int main(int argc, char** argv) {
    event_server_begin(handler, "openApp_plugin_mach");
    return 0;
}
