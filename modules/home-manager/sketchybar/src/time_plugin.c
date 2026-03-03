#include "sketchybar.h"
#include <stdio.h>
#include <stdlib.h>
#include <time.h>

int main(int argc, char** argv) {
    char* name = getenv("NAME");
    if (!name) name = "calendar";

    time_t rawtime;
    struct tm * timeinfo;
    char buffer[80];

    time(&rawtime);
    timeinfo = localtime(&rawtime);
    strftime(buffer, sizeof(buffer), "%a %d %b %H:%M:%S", timeinfo);

    char update_message[512];
    snprintf(update_message, sizeof(update_message), "--animate tanh 8 --set %s label=\"%s\"", name, buffer);

    sketchybar(update_message);
    return 0;
}
