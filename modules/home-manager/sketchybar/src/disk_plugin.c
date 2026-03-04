#include "sketchybar.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/param.h>
#include <sys/mount.h>
#include <unistd.h>

int main(int argc, char** argv) {
    char item_name[256] = "disk";
    if (argc > 1) {
        strncpy(item_name, argv[1], sizeof(item_name) - 1);
    }

    struct statfs stats;
    char update_message[512];

    while (1) {
        if (statfs("/", &stats) == 0) {
            unsigned long long total = stats.f_blocks * stats.f_bsize;
            unsigned long long free = stats.f_bfree * stats.f_bsize;
            int percentage = (int)(((double)(total - free) / (double)total) * 100);

            snprintf(update_message, sizeof(update_message), "--animate tanh 8 --set %s label=\"%d%%\"", item_name, percentage);
            sketchybar(update_message);
        }

        sleep(60);
    }

    return 0;
}
