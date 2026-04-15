#define _DARWIN_C_SOURCE
#include "texManager.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/wait.h>
#include <ftw.h>
#include <fnmatch.h>
#include <fcntl.h>

static const char *cleanExtensions[] = {
    ".aux", ".fls", ".log", ".blg", ".fdb_latexmk",
    ".bbl", ".bbl-SAVE-ERROR", ".bcf", ".bcf-SAVE-ERROR",
    ".xdv", ".xml", ".run.xml", ".synctex.gz", ".synctex(busy)",
    ".dvi", ".out.ps"
};

void texInitConfig(TexConfig *config) {
    memset(config, 0, sizeof(TexConfig));
    config->continuous = false;
    config->nonstop = true;
    strcpy(config->engine, "pdf");
}

bool texIsCompiling(const char *fileName) {
    char cmd[512];
    snprintf(cmd, sizeof(cmd), "pgrep -f '[l]atexmk.*%s' > /dev/null 2>&1", fileName);
    int status = system(cmd);
    return (WIFEXITED(status) && WEXITSTATUS(status) == 0);
}

int texCompile(const char *dirPath, const char *fileName, const TexConfig *config) {
    if (texIsCompiling(fileName)) {
        printf("Already compiling: %s\n", fileName);
        return 0;
    }

    char baseName[256];
    strncpy(baseName, fileName, sizeof(baseName));
    baseName[sizeof(baseName) - 1] = '\0';
    char *dot = strrchr(baseName, '.');
    if (dot) *dot = '\0';

    unsigned int dirHash = 5381;
    for (int i = 0; dirPath[i] != '\0'; i++) {
        dirHash = ((dirHash << 5) + dirHash) + dirPath[i];
    }

    char cacheDir[PATH_MAX];
    const char *home = getenv("HOME");

    snprintf(cacheDir, sizeof(cacheDir), "%s/.cache/texManager/pdf/%u_%s", home ? home : "/tmp", dirHash, baseName);

    char cmd[2048];
    snprintf(cmd, sizeof(cmd), "mkdir -p '%s'", cacheDir);
    system(cmd);

    pid_t pid = fork();
    if (pid == 0) {
        if (chdir(dirPath) != 0) exit(1);

        char *args[12];
        int i = 0;
        args[i++] = "latexmk";

        char engineArg[64];
        snprintf(engineArg, sizeof(engineArg), "-%s", config->engine);
        args[i++] = engineArg;
        args[i++] = "-synctex=1";

        if (config->continuous) args[i++] = "-pvc";
        if (config->nonstop) args[i++] = "-interaction=nonstopmode";

        char outdirArg[PATH_MAX + 32];
        snprintf(outdirArg, sizeof(outdirArg), "-outdir=%s", cacheDir);
        args[i++] = outdirArg;

        args[i++] = (char *)fileName;
        args[i++] = NULL;

        int devnull = open("/dev/null", O_WRONLY);
        if (devnull != -1) {
            dup2(devnull, STDOUT_FILENO);
            dup2(devnull, STDERR_FILENO);
            close(devnull);
        }

        execvp("latexmk", args);
        exit(1);
    } else if (pid > 0) {
        int status;
        waitpid(pid, &status, 0);
        int exitCode = WIFEXITED(status) ? WEXITSTATUS(status) : 1;

        if (exitCode == 0) {
            char mvCmd[2048];
            snprintf(mvCmd, sizeof(mvCmd),
                "mv -f '%s/%s.pdf' '%s/%s.pdf'; "
                "mv -f '%s/%s.synctex.gz' '%s/%s.synctex.gz' 2>/dev/null",
                cacheDir, baseName, dirPath, baseName,
                cacheDir, baseName, dirPath, baseName);
            system(mvCmd);
        }

        return exitCode;
    }
    return 1;
}

int texCompileToSvg(const char *dirPath, const char *fileName, const char *outputDir) {
    char baseName[256];
    strncpy(baseName, fileName, sizeof(baseName));
    baseName[sizeof(baseName) - 1] = '\0';
    char *dot = strrchr(baseName, '.');
    if (dot) *dot = '\0';

    unsigned int dirHash = 5381;
    for (int i = 0; dirPath[i] != '\0'; i++) {
        dirHash = ((dirHash << 5) + dirHash) + dirPath[i];
    }

    char cmd[2048];
    char cacheDir[PATH_MAX];
    const char *home = getenv("HOME");

    snprintf(cacheDir, sizeof(cacheDir), "%s/.cache/texManager/svg/%u_%s", home ? home : "/tmp", dirHash, baseName);

    snprintf(cmd, sizeof(cmd), "mkdir -p '%s' '%s'", outputDir, cacheDir);
    system(cmd);

    snprintf(cmd, sizeof(cmd),
        "cd '%s' && "
        "latex -interaction=nonstopmode -output-directory='%s' -jobname='%s_web' '\\def\\isweb{}\\input{%s}' >> /dev/null 2>&1",
        dirPath, cacheDir, baseName, fileName);

    int status = system(cmd);
    if (!WIFEXITED(status) || WEXITSTATUS(status) != 0) return 1;

    snprintf(cmd, sizeof(cmd),
        "cd '%s' && dvisvgm --font-format=woff2 --exact --page=1 '%s_web.dvi' -o '%s.svg' >> /dev/null 2>&1",
        cacheDir, baseName, baseName);

    status = system(cmd);
    if (!WIFEXITED(status) || WEXITSTATUS(status) != 0) return 1;

    snprintf(cmd, sizeof(cmd), "mv -f '%s/%s.svg' '%s/%s.svg'", cacheDir, baseName, outputDir, baseName);
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

void ensureTexPath() {
    const char *currentPath = getenv("PATH");
    char newPath[8192];
    snprintf(newPath, sizeof(newPath),
        "/run/current-system/sw/bin:/etc/profiles/per-user/%s/bin:%s/.nix-profile/bin:/nix/var/nix/profiles/default/bin:/opt/homebrew/bin:/usr/local/bin:%s",
        getenv("USER"), getenv("HOME"), currentPath ? currentPath : "");
    setenv("PATH", newPath, 1);
}
