#define _DARWIN_C_SOURCE
#include "commonUtils.h"
#include "texManager.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ftw.h>
#include <fnmatch.h>

static const char *cleanExtensions[] = {
    ".aux", ".fls", ".log", ".blg", ".fdb_latexmk",
    ".bbl", ".bbl-SAVE-ERROR", ".bcf", ".bcf-SAVE-ERROR",
    ".xdv", ".xml", ".run.xml", ".synctex(busy)",
    ".dvi", ".out.ps"
};

void texInitConfig(TexConfig *config) {
    memset(config, 0, sizeof(TexConfig));
    config->continuous = false;
    config->nonstop = true;
    strcpy(config->engine, "pdf");
}

int texCompile(const char *dirPath, const char *fileName, const TexConfig *config) {
    char pattern[512];
    snprintf(pattern, sizeof(pattern), "[l]atexmk.*%s", fileName);
    if (IsProcessRunning(pattern)) return 0;

    char baseName[256];
    strncpy(baseName, fileName, sizeof(baseName));
    baseName[sizeof(baseName) - 1] = '\0';
    char *dot = strrchr(baseName, '.');
    if (dot) *dot = '\0';

    unsigned int dirHash = HashString(dirPath);

    char cacheDir[PATH_MAX];
    const char *home = getenv("HOME");
    snprintf(cacheDir, sizeof(cacheDir), "%s/.cache/texManager/pdf/%u_%s", home ? home : "/tmp", dirHash, baseName);

    EnsureDirectoryExists(cacheDir);

    char cmd[2048];
    snprintf(cmd, sizeof(cmd),
        "cd '%s' && latexmk -%s -synctex=1 %s %s -outdir='%s' '%s' >> /dev/null 2>&1",
        dirPath,
        config->engine,
        config->continuous ? "-pvc" : "",
        config->nonstop ? "-interaction=nonstopmode" : "",
        cacheDir,
        fileName);

    int status = system(cmd);
    int exitCode = WIFEXITED(status) ? WEXITSTATUS(status) : 1;

    if (exitCode == 0) {
        char srcFile[PATH_MAX], dstFile[PATH_MAX];

        snprintf(srcFile, sizeof(srcFile), "%s/%s.pdf", cacheDir, baseName);
        snprintf(dstFile, sizeof(dstFile), "%s/%s.pdf", dirPath, baseName);
        MoveFile(srcFile, dstFile);

        snprintf(srcFile, sizeof(srcFile), "%s/%s.synctex.gz", cacheDir, baseName);
        snprintf(dstFile, sizeof(dstFile), "%s/%s.synctex.gz", dirPath, baseName);
        MoveFile(srcFile, dstFile);
    }

    return exitCode;
}

int texCompileToSvg(const char *dirPath, const char *fileName, const char *outputDir) {
    char baseName[256];
    strncpy(baseName, fileName, sizeof(baseName));
    baseName[sizeof(baseName) - 1] = '\0';
    char *dot = strrchr(baseName, '.');
    if (dot) *dot = '\0';

    unsigned int dirHash = HashString(dirPath);

    char cmd[2048];
    char cacheDir[PATH_MAX];
    const char *home = getenv("HOME");
    snprintf(cacheDir, sizeof(cacheDir), "%s/.cache/texManager/svg/%u_%s", home ? home : "/tmp", dirHash, baseName);

    EnsureDirectoryExists(outputDir);
    EnsureDirectoryExists(cacheDir);

    snprintf(cmd, sizeof(cmd),
        "cd '%s' && "
        "latexmk -g -dvi -interaction=nonstopmode -outdir='%s' -jobname='%s_web' "
        "-latex='latex %%O \"\\def\\isweb{}\\def\\notename{%s}\\input{%%S}\"' '%s' >> /dev/null 2>&1",
        dirPath, cacheDir, baseName, baseName, fileName);

    int status = system(cmd);
    if (!WIFEXITED(status) || WEXITSTATUS(status) != 0) return 1;

    snprintf(cmd, sizeof(cmd),
        "cd '%s' && dvisvgm --font-format=woff2 --exact --page=1- '%s_web.dvi' -o '%s-%%p.svg' >> /dev/null 2>&1",
        cacheDir, baseName, baseName);

    status = system(cmd);
    if (!WIFEXITED(status) || WEXITSTATUS(status) != 0) return 1;

    snprintf(cmd, sizeof(cmd), "mv -f '%s'/%s-*.svg '%s'/", cacheDir, baseName, outputDir);
    system(cmd);

    return 0;
}

static int unlinkCallback(const char *fpath, const struct stat *sb, int typeflag, struct FTW *ftwbuf) {
    if (typeflag == FTW_F) {
        const char *fileName = fpath + ftwbuf->base;
        if (fnmatch("* [0-9].*", fileName, 0) == 0) { unlink(fpath); return 0; }

        size_t nameLen = strlen(fileName);
        size_t numExts = sizeof(cleanExtensions) / sizeof(cleanExtensions[0]);

        for (size_t i = 0; i < numExts; i++) {
            size_t extLen = strlen(cleanExtensions[i]);
            if (nameLen >= extLen && strcmp(fileName + nameLen - extLen, cleanExtensions[i]) == 0) {
                unlink(fpath);
                return 0;
            }
        }
    }
    return 0;
}

int texCleanAux(const char *dirPath) {
    int flags = FTW_PHYS;
    if (nftw(dirPath, unlinkCallback, 20, flags) == -1) return 1;
    return 0;
}
