#include "sketchybar.h"
#include "icon_map.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

int main(int argc, char** argv) {
    char* name = getenv("NAME");
    char* sender = getenv("SENDER");
    char* info = getenv("INFO"); 
    char* workspace = getenv("AEROSPACE_FOCUSED_WORKSPACE");

    if (!name || !sender || strcmp(sender, "front_app_switched") != 0) return 0;
    const char* icon = get_icon_for_app(info);

    char command[1024];
    snprintf(command, sizeof(command), 
             "--animate tanh 8 --set %s label=\"%s\" icon=\"%s\" icon.font=\"sketchybar-app-font:Regular:16.0\"", 
             name, info, icon);
    sketchybar(command);

    usleep(100000); 
    if (workspace) {
        char trigger[256];
        snprintf(trigger, sizeof(trigger), "--trigger aerospace_workspace_change FOCUSED_WORKSPACE=%s", workspace);
        sketchybar(trigger);
    }

    return 0;
}
