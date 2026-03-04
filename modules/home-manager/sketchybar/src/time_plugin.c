#include "sketchybar.h"
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <unistd.h>

int main(int argc, char** argv) {
    char* name = (argc > 1) ? argv[1] : "calendar";

    time_t rawtime;
    struct tm * timeinfo;
    char buffer[80];
    char update_message[512];

    while (1) {
        time(&rawtime);
        timeinfo = localtime(&rawtime);
        strftime(buffer, sizeof(buffer), "%a %d %b %H:%M:%S", timeinfo);

        snprintf(update_message, sizeof(update_message), "--set %s label=\"%s\"", name, buffer);

        sketchybar(update_message);
        sleep(1);
    }

    return 0;
}
