#pragma once

#include <stdbool.h>
#include <limits.h>
#include <sys/types.h>

typedef struct {
    bool continuous;
    bool nonstop;
    char engine[32];
    char buildDir[PATH_MAX];
} TexConfig;

void texInitConfig(TexConfig *config);
int texCompile(const char *dirPath, const char *fileName, const TexConfig *config);
int texCompileToSvg(const char *dirPath, const char *fileName, const char *outputDir);
int texCleanAux(const char *dirPath);
