#include "texManager.h"
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <getopt.h>

int main(int argc, char **argv) {
    TexConfig config;
    texInitConfig(&config);
    ensureTexPath();

    int opt;
    bool cleanMode = false;

    while ((opt = getopt(argc, argv, "bcCe:")) != -1) {
        switch (opt) {
            case 'b': config.background = true; break;
            case 'c': config.continuous = true; break;
            case 'e': strncpy(config.engine, optarg, sizeof(config.engine) - 1); config.engine[sizeof(config.engine) - 1] = '\0'; break;
            case 'C': cleanMode = true; break;
            default:
                fprintf(stderr, "Usage: %s [-b background] [-c continuous] [-e engine] [-C clean] <fileOrDir>\n", argv[0]);
                return 1;
        }
    }

    if (optind >= argc) {
        fprintf(stderr, "Error: Expected file or directory argument.\n");
        return 1;
    }

    const char *targetPath = argv[optind];

    if (cleanMode) {
        printf("Cleaning auxiliary files in %s\n", targetPath);
        return texCleanAux(targetPath);
    } else {
        printf("Compiling %s...\n", targetPath);
        return texCompile(targetPath, &config);
    }
}
