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

    while ((opt = getopt(argc, argv, "cCe:so:")) != -1) {
        switch (opt) {
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
                fprintf(stderr, "Usage: %s [-c continuous] [-e engine] [-C clean] [-s svg] [-o outputDir] <fileOrDir>\n", argv[0]);
                return 1;
        }
    }

    if (optind >= argc) {
        fprintf(stderr, "Error: Expected file or directory argument.\n");
        return 1;
    }

    char dirPath[PATH_MAX];
    strncpy(dirPath, argv[optind], sizeof(dirPath));
    char *slash = strrchr(dirPath, '/');
    const char *fileName = argv[optind];

    if (slash) {
        *slash = '\0';
        fileName = argv[optind] + (slash - dirPath + 1);
    } else {
        strcpy(dirPath, ".");
    }

    if (cleanMode) {
        return texCleanAux(argv[optind]);
    } else if (svgMode) {
        return texCompileToSvg(dirPath, fileName, outputDir);
    } else {
        return texCompile(dirPath, fileName, &config);
    }
}
