#include "sketchybar.h"
#include "icon_map.h"
#include "colors.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include <ctype.h>

#define MAX_WORKSPACES 20
#define MAX_ICON_STRIP 1024

struct workspace {
    char name[32];
    char icons[MAX_ICON_STRIP];
    bool focused;
    bool occupied;
};

void handler(env env) {
    char* sender = env_get_value_for_key(env, "SENDER");
    char* focused_env = env_get_value_for_key(env, "FOCUSED_WORKSPACE");

    if (sender[0] == '\0') return;

    bool has_focused = (focused_env != NULL && focused_env[0] != '\0');
    char focused_ws[32] = "";
    if (has_focused) {
        strncpy(focused_ws, focused_env, 31);
    }

    char cmd[512];
    if (has_focused) {
        snprintf(cmd, sizeof(cmd),
                 "aerospace list-workspaces --all 2>/dev/null && echo '===' && "
                 "aerospace list-windows --all --format \"%%{workspace}|%%{app-name}|%%{window-title}\" 2>/dev/null");
    } else {
        snprintf(cmd, sizeof(cmd),
                 "aerospace list-workspaces --focused 2>/dev/null && echo '===' && "
                 "aerospace list-workspaces --all 2>/dev/null && echo '===' && "
                 "aerospace list-windows --all --format \"%%{workspace}|%%{app-name}|%%{window-title}\" 2>/dev/null");
    }

    FILE *fp = popen(cmd, "r");
    if (!fp) return;

    char line[1024];
    int stage = has_focused ? 1 : 0;

    struct workspace ws_list[MAX_WORKSPACES];
    int ws_count = 0;

    while (fgets(line, sizeof(line), fp)) {
        line[strcspn(line, "\r\n")] = 0;

        if (strcmp(line, "===") == 0) {
            stage++;
            continue;
        }

        if (stage == 0) {
            strncpy(focused_ws, line, 31);
        }
        else if (stage == 1) {
            if (strlen(line) == 0 || ws_count >= MAX_WORKSPACES) continue;
            strncpy(ws_list[ws_count].name, line, 31);
            ws_list[ws_count].icons[0] = '\0';
            ws_list[ws_count].focused = (strcmp(line, focused_ws) == 0);
            ws_list[ws_count].occupied = false;
            ws_count++;
        }
        else if (stage == 2) {
            char *sep1 = strchr(line, '|');
            if (!sep1) continue;
            *sep1 = '\0';
            char *ws_name = line;

            char *sep2 = strchr(sep1 + 1, '|');
            if (!sep2) continue;
            *sep2 = '\0';
            char *app_name = sep1 + 1;
            char *window_title = sep2 + 1;

            if (strcasecmp(app_name, "alacritty") == 0) {
                if (strcmp(window_title, "launcher") == 0) { continue; }
                else if (strcmp(window_title, "alacritty-float") == 0) { app_name = "alacritty"; }
                else if (strcmp(window_title, "vifm") == 0) { app_name = "vifm"; }
                else if (strcmp(window_title, "vifm-float") == 0) { app_name = "vifm"; }
                else if (strcmp(window_title, "attic") == 0) { app_name = "attic"; }
                else if (strcmp(window_title, "btop") == 0) { app_name = "btop"; }
                else if (strcmp(window_title, "nvim") == 0) { app_name = "nvim"; }
                else if (strcmp(window_title, "git") == 0) { app_name = "git"; }
            }

            if (strcasecmp(app_name, "attic-graph") == 0) { app_name = "attic"; }

            for (int i = 0; i < ws_count; i++) {
                if (strcmp(ws_list[i].name, ws_name) == 0) {
                    const char* icon = get_icon_for_app(app_name);
                    if (strstr(ws_list[i].icons, icon) == NULL) {
                        strcat(ws_list[i].icons, icon);
                        ws_list[i].occupied = true;
                    }
                    break;
                }
            }
        }
    }
    pclose(fp);

    char full_cmd[16384] = "";
    int offset = 0;

    for (int i = 0; i < ws_count; i++) {
        bool is_numeric = (strlen(ws_list[i].name) == 1 && isdigit(ws_list[i].name[0]));
        int i_pl = 0, i_pr = 0, l_pl = 0, l_pr = 0, bg_p = 0;
        char *bg_c = TRANSPARENT, *br_c = TRANSPARENT;
        char *ic_c = TRANSPARENT, *la_c = TRANSPARENT;

        if (ws_list[i].focused || ws_list[i].occupied) {
            bg_p = 2;
            if (is_numeric) {
                i_pl = 10; i_pr = 5; l_pl = 5; l_pr = 10;
            } else {
                i_pl = 8; i_pr = 6; l_pl = 0; l_pr = 0;
            }

            if (!ws_list[i].occupied) { i_pl = 0; i_pr = 0; l_pl = 10; l_pr = 10; }

            if (ws_list[i].focused) {
                bg_c = BAR_COLOR; br_c = BORDER_COLOR; ic_c = ICON_COLOR; la_c = LABEL_COLOR;
            } else {
                ic_c = ICON_COLOR; la_c = LABEL_COLOR;
            }
        }

        int written = snprintf(full_cmd + offset, sizeof(full_cmd) - offset,
                 "%s--animate tanh 4 --set space.%s background.color=%s background.border_color=%s "
                 "background.padding_left=%d background.padding_right=%d icon=\"%s\" icon.color=%s "
                 "icon.padding_left=%d icon.padding_right=%d label.color=%s label.padding_left=%d "
                 "label.padding_right=%d",
                 (i > 0) ? " " : "", ws_list[i].name, bg_c, br_c, bg_p, bg_p, ws_list[i].icons, ic_c,
                 i_pl, i_pr, la_c, l_pl, l_pr);

        if (written > 0 && written < sizeof(full_cmd) - offset) {
            offset += written;
        }
    }

    if (strlen(full_cmd) > 0) { sketchybar(full_cmd); }
}

int main(int argc, char** argv) {
    event_server_begin(handler, "aerospace_plugin_mach");
    return 0;
}
