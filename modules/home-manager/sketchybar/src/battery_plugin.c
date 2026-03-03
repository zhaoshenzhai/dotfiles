#include "sketchybar.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>

int main(int argc, char** argv) {
    char* name = getenv("NAME");
    if (!name) name = "battery";

    char buffer[256];
    FILE *fp = popen("pmset -g batt", "r");
    if (fp == NULL) return 1;

    bool charging = false;
    int percentage = -1;

    while (fgets(buffer, sizeof(buffer), fp) != NULL) {
        if (strstr(buffer, "AC Power") != NULL) {
            charging = true;
        }
        char *ptr = strchr(buffer, '%');
        if (ptr != NULL) {
            char *start = ptr - 1;
            while (start >= buffer && *start >= '0' && *start <= '9') start--;
            percentage = atoi(start + 1);
        }
    }
    pclose(fp);

    if (percentage != -1) {
        char* icon = "􀛩";
        char* color = "0xffe06c75";                                          // RED

        if (charging) {
            if (percentage == 100) {
                icon = "􀛨";
                color = "0xffabb2bf";                                        // WHITE
            } else {
                icon = "􀢋";
                color = "0xff98c379";                                        // GREEN
            }
        } else {
            if (percentage >= 90) { icon = "􀛨"; color = "0xffd19a66"; }      // YELLOW
            else if (percentage >= 60) { icon = "􀺸"; color = "0xffd19a66"; } // YELLOW
            else if (percentage >= 30) { icon = "􀺶"; color = "0xfff5a97f"; } // ORANGE
        }

        char update_message[512];
        snprintf(update_message, sizeof(update_message),
                 "--animate tanh 8 --set %s icon=\"%s\" label=\"%d%%\" icon.color=%s",
                 name, icon, percentage, color);

        sketchybar(update_message);
    }
    return 0;
}
