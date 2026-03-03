#include "sketchybar.h"
#include <stdio.h>
#include <stdlib.h>
#include <sys/param.h>
#include <sys/mount.h>

int main(int argc, char** argv) {
    char* name = getenv("NAME");
    if (!name) name = "disk";

    struct statfs stats;
    if (statfs("/", &stats) != 0) return 1;

    unsigned long long total = stats.f_blocks * stats.f_bsize;
    unsigned long long free = stats.f_bfree * stats.f_bsize;
    int percentage = (int)(((double)(total - free) / (double)total) * 100);

    char update_message[512];
    snprintf(update_message, sizeof(update_message), "--animate tanh 8 --set %s label=\"%d%%\"", name, percentage);

    sketchybar(update_message);
    return 0;
}
