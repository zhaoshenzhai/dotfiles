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
    char* workspace = env_get_value_for_key(env, "AEROSPACE_FOCUSED_WORKSPACE");

    if (name[0] == '\0' || sender[0] == '\0' || strcmp(sender, "front_app_switched") != 0 || info[0] == '\0') {
        return;
    }

    const char* icon = get_icon_for_app(info);

    char command[1024];
    snprintf(command, sizeof(command),
             "--animate tanh 8 --set %s label=\"%s\" icon=\"%s\" icon.font=\"sketchybar-app-font:Regular:16.0\"",
             name, info, icon);
    sketchybar(command);

    if (workspace[0] != '\0') {
        usleep(100000);
        char trigger[256];
        snprintf(trigger, sizeof(trigger), "--trigger aerospace_workspace_change FOCUSED_WORKSPACE=%s", workspace);
        sketchybar(trigger);
    }
}

int main(int argc, char** argv) {
    event_server_begin(handler, "openApp_plugin_mach");
    return 0;
}
