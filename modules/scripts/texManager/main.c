#include "texManager.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <getopt.h>

int main(int argc, char **argv) {
    TexConfig config;
    texInitConfig(&config);

    int opt;
    bool cleanMode = false;
    bool svgMode = false;
    char outputDir[PATH_MAX] = ".";

    while ((opt = getopt(argc, argv, "bcCe:so:")) != -1) {
        switch (opt) {
            case 'b': config.background = true; break;
            case 'c': config.continuous = true; break;
            case 'e':
                strncpy(config.engine, optarg, sizeof(config.engine) - 1);
                config.engine[sizeof(config.engine) - 1] = '\0';
                break;
            case 'C': cleanMode = true; break;
            case 's': svgMode = true; break;
            case 'o':
                strncpy(outputDir, optarg, sizeof(outputDir) - 1);
                outputDir[sizeof(outputDir) - 1] = '\0';
                break;
            default:
                fprintf(stderr, "Usage: %s [-b background] [-c continuous] [-e engine] [-C clean] [-s svg] [-o outputDir] <fileOrDir>\n", argv[0]);
                return 1;
        }
    }

    if (optind >= argc) {
        fprintf(stderr, "Error: Expected file or directory argument.\n");
        return 1;
    }

    const char *targetPath = argv[optind];

    if (cleanMode) {
        return texCleanAux(targetPath);
    } else if (svgMode) {
        return texCompileToSvg(targetPath, outputDir);
    } else {
        return texCompile(targetPath, &config);
    }
}
