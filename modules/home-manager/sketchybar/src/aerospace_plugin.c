#include "sketchybar.h"
#include "icon_map.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include <ctype.h>

#define MAX_WORKSPACES 20
#define MAX_ICON_STRIP 1024

#define BAR_COLOR         "0xaa1e2127"
#define BORDER_COLOR      "0xff444444"
#define ICON_COLOR        "0xffabb2bf"
#define LABEL_COLOR       "0xffabb2bf"
#define TRANSPARENT       "0x00000000"

struct workspace {
    char name[32];
    char icons[MAX_ICON_STRIP];
    bool focused;
    bool occupied;
};

int main(int argc, char** argv) {
    char* focused_env = getenv("FOCUSED_WORKSPACE");
    char focused_ws[32] = "";
    if (focused_env && strlen(focused_env) > 0) {
        strncpy(focused_ws, focused_env, 31);
    } else {
        FILE *fp = popen("aerospace list-workspaces --focused 2>/dev/null", "r");
        if (fp) {
            if (fgets(focused_ws, sizeof(focused_ws), fp)) {
                focused_ws[strcspn(focused_ws, "\r\n")] = 0;
            }
            pclose(fp);
        }
    }

    struct workspace ws_list[MAX_WORKSPACES];
    int ws_count = 0;
    FILE *fp_ws = popen("aerospace list-workspaces --all 2>/dev/null", "r");
    if (fp_ws) {
        char line[32];
        while (fgets(line, sizeof(line), fp_ws) && ws_count < MAX_WORKSPACES) {
            line[strcspn(line, "\r\n")] = 0;
            if (strlen(line) == 0) continue;
            strncpy(ws_list[ws_count].name, line, 31);
            ws_list[ws_count].icons[0] = '\0';
            ws_list[ws_count].focused = (strcmp(line, focused_ws) == 0);
            ws_list[ws_count].occupied = false;
            ws_count++;
        }
        pclose(fp_ws);
    }

    FILE *fp_win = popen("aerospace list-windows --all --format \"%{workspace}|%{app-name}\" 2>/dev/null", "r");
    if (fp_win) {
        char line[1024];
        while (fgets(line, sizeof(line), fp_win)) {
            line[strcspn(line, "\r\n")] = 0;
            char *sep = strchr(line, '|');
            if (!sep) continue;
            *sep = '\0';
            char *ws_name = line;
            char *app_name = sep + 1;

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
        pclose(fp_win);
    }

    char full_cmd[16384] = ""; 
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

        char item_args[1024];
        snprintf(item_args, sizeof(item_args),
                 "--animate tanh 8 --set space.%s background.color=%s background.border_color=%s "
                 "background.padding_left=%d background.padding_right=%d icon=\"%s\" icon.color=%s "
                 "icon.padding_left=%d icon.padding_right=%d label.color=%s label.padding_left=%d "
                 "label.padding_right=%d",
                 ws_list[i].name, bg_c, br_c, bg_p, bg_p, ws_list[i].icons, ic_c, 
                 i_pl, i_pr, la_c, l_pl, l_pr);
        
        if (i > 0) strcat(full_cmd, " ");
        strcat(full_cmd, item_args);
    }

    if (strlen(full_cmd) > 0) { sketchybar(full_cmd); }
    return 0;
}
