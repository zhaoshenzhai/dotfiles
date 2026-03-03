#include "sketchybar.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int main(int argc, char** argv) {
    char* name = getenv("NAME");
    char* sender = getenv("SENDER");
    char* info = getenv("INFO");

    if (!name || !sender || strcmp(sender, "volume_change") != 0) return 0;

    int volume = atoi(info);
    char* icon = "􀊣";

    if (volume >= 60) icon = "􀊩";
    else if (volume >= 30) icon = "􀊥";
    else if (volume > 0) icon = "􀊡";

    FILE *fp = popen("SwitchAudioSource -c 2>/dev/null", "r");
    if (fp != NULL) {
        char device[256];
        if (fgets(device, sizeof(device), fp) != NULL) {
            if (strstr(device, "headphone") != NULL || strstr(device, "AirPods") != NULL) {
                icon = "􀑈";
            }
        }
        pclose(fp);
    }

    char update_message[512];
    snprintf(update_message, sizeof(update_message), "--animate tanh 8 --set %s icon=\"%s\" label=\"%d%%\"", name, icon, volume);

    sketchybar(update_message);
    return 0;
}
