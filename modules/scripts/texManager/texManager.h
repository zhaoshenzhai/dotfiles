#pragma once

#include <stdbool.h>
#include <limits.h>
#include <sys/types.h>

typedef struct {
    bool background;
    bool continuous;
    bool nonstop;
    char engine[32];
    char buildDir[PATH_MAX];
} TexConfig;

void ensureTexPath();
void texInitConfig(TexConfig *config);
int texCompile(const char *filePath, const TexConfig *config);
int texCompileToSvg(const char *filePath, const char *outputDir);
bool texIsCompiling(const char *filePath);
int texCleanAux(const char *dirPath);
