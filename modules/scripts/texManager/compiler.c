#define _DARWIN_C_SOURCE
#include "texManager.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/wait.h>
#include <ftw.h>
#include <fnmatch.h>

static const char *cleanExtensions[] = {
    ".aux", ".fls", ".log", ".blg", ".fdb_latexmk",
    ".bbl", ".bbl-SAVE-ERROR", ".bcf", ".bcf-SAVE-ERROR",
    ".xdv", ".xml", ".run.xml", ".synctex.gz", ".synctex(busy)"
};

void texInitConfig(TexConfig *config) {
    memset(config, 0, sizeof(TexConfig));
    config->background = false;
    config->continuous = false;
    config->nonstop = true;
    strcpy(config->engine, "pdf");
}

bool texIsCompiling(const char *filePath) {
    const char *fileName = strrchr(filePath, '/');
    fileName = fileName ? fileName + 1 : filePath;

    char cmd[512];
    snprintf(cmd, sizeof(cmd), "pgrep -f '[l]atexmk.*%s' > /dev/null 2>&1", fileName);
    int status = system(cmd);

    return (WIFEXITED(status) && WEXITSTATUS(status) == 0);
}

int texCompile(const char *filePath, const TexConfig *config) {
    if (texIsCompiling(filePath)) {
        printf("Already compiling: %s\n", filePath);
        return 0;
    }

    char dirPath[PATH_MAX];
    strncpy(dirPath, filePath, sizeof(dirPath));
    char *slash = strrchr(dirPath, '/');
    const char *fileName = filePath;

    if (slash) {
        *slash = '\0';
        fileName = slash + 1;
    } else {
        strcpy(dirPath, ".");
    }

    char cmd[2048];
    snprintf(cmd, sizeof(cmd),
        "cd '%s' && %s latexmk -%s %s %s '%s' > /dev/null 2>&1 %s",
        dirPath,
        config->background ? "nohup" : "",
        config->engine,
        config->continuous ? "-pvc" : "",
        config->nonstop ? "-interaction=nonstopmode" : "",
        fileName,
        config->background ? "&" : "");

    return system(cmd);
}

static int unlinkCallback(const char *fpath, const struct stat *sb, int typeflag, struct FTW *ftwbuf) {
    if (typeflag == FTW_F) {
        const char *fileName = fpath + ftwbuf->base;

        if (fnmatch("* [0-9].*", fileName, 0) == 0) { unlink(fpath); return 0; }

        size_t numExts = sizeof(cleanExtensions) / sizeof(cleanExtensions[0]);
        size_t nameLen = strlen(fileName);

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

    if (nftw(dirPath, unlinkCallback, 20, flags) == -1) {
        perror("Error traversing directory");
        return 1;
    }

    return 0;
}

void ensureTexPath() {
    const char *currentPath = getenv("PATH");
    char newPath[8192];
    snprintf(newPath, sizeof(newPath),
        "/run/current-system/sw/bin:/etc/profiles/per-user/%s/bin:%s/.nix-profile/bin:/nix/var/nix/profiles/default/bin:/opt/homebrew/bin:/usr/local/bin:%s",
        getenv("USER"), getenv("HOME"), currentPath ? currentPath : "");
    setenv("PATH", newPath, 1);
}
