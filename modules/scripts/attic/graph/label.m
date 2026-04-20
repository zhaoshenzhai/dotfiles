#include "graph.h"
#include <sys/stat.h>
#include <unistd.h>
#include <pthread.h>

#define CACHE_SIZE 2000
typedef struct { char latex[256]; Texture2D tex; } LatexCacheEntry;
LatexCacheEntry sessionCache[CACHE_SIZE];
int sessionCacheCount = 0;

typedef struct { char latex[256]; int state; } RenderJob;
RenderJob renderQueue[CACHE_SIZE];
pthread_mutex_t queueMutex = PTHREAD_MUTEX_INITIALIZER;
pthread_cond_t queueCond = PTHREAD_COND_INITIALIZER;

void getCachePaths(const char* latex, unsigned int* hashOut, char* cacheDirOut, char* pngPathOut) {
    unsigned int h = DJB2Hash(latex); // <-- Replaced custom hash
    if (hashOut) *hashOut = h;

    const char* home = getenv("HOME");
    if (cacheDirOut) snprintf(cacheDirOut, 512, "%s/.cache/attic/labels", home ? home : "/tmp");
    if (pngPathOut) snprintf(pngPathOut, 1024, "%s/.cache/attic/labels/%u.png", home ? home : "/tmp", h);
}

void* latexWorkerThread(void* arg) {
    while (true) {
        char currentLatex[256] = "";
        int jobIndex = -1;

        pthread_mutex_lock(&queueMutex);
        while (true) {
            for (int i = 0; i < CACHE_SIZE; i++) {
                if (renderQueue[i].state == 1) {
                    jobIndex = i;
                    break;
                }
            }

            if (jobIndex != -1) {
                strncpy(currentLatex, renderQueue[jobIndex].latex, 255);
                renderQueue[jobIndex].state = 2;
                break;
            }
            pthread_cond_wait(&queueCond, &queueMutex);
        }
        pthread_mutex_unlock(&queueMutex);

        unsigned int h;
        char cacheDir[512], pngPath[1024];
        getCachePaths(currentLatex, &h, cacheDir, pngPath);

        if (access(pngPath, F_OK) != 0) {
            EnsureDirectoryExists(cacheDir);

            @autoreleasepool {
                NSString *nsHome = [NSString stringWithUTF8String:(getenv("HOME") ? getenv("HOME") : "/tmp")];
                NSString *src = [NSString stringWithFormat:@"%@/iCloud/Dotfiles/modules/LaTeXTemplate/macros.sty", nsHome];
                NSString *dst = [NSString stringWithFormat:@"%s/macros.sty", cacheDir];
                [[NSFileManager defaultManager] removeItemAtPath:dst error:nil];
                [[NSFileManager defaultManager] createSymbolicLinkAtPath:dst withDestinationPath:src error:nil];
            }

            char texPath[1024], cmd[2048];
            snprintf(texPath, sizeof(texPath), "%s/%u.tex", cacheDir, h);
            FILE *f = fopen(texPath, "w");
            fprintf(f, "\\documentclass[border=2pt]{standalone}\n"
                       "\\usepackage[T1]{fontenc}\n"
                       "\\usepackage{amsfonts, amsmath, amssymb, amsthm}\n"
                       "\\usepackage{mathtools, mathrsfs, dsfont}\n"
                       "\\usepackage{graphicx, xcolor, mlmodern}\n"
                       "\\input{./macros.sty}\n"
                       "\\begin{document}\\color{white}%s\\end{document}", currentLatex);
            fclose(f);

            char tempPngPath[1024];
            snprintf(tempPngPath, sizeof(tempPngPath), "%s/%u_tmp.png", cacheDir, h);

            int status = -1;
            @autoreleasepool {
                NSString *script = [NSString stringWithFormat:@"cd \"%s\" && latex -interaction=nonstopmode %u.tex && dvipng -bg Transparent -D 300 -o \"%s\" %u.dvi", cacheDir, h, tempPngPath, h];
                status = RunCommandWait(@"/bin/zsh", @[@"-l", @"-c", script]);

                if (status == 0) {
                    MoveFile(tempPngPath, pngPath);
                }
            }

            char fpath[1024];
            snprintf(fpath, sizeof(fpath), "%s/%u.tex", cacheDir, h); unlink(fpath);
            snprintf(fpath, sizeof(fpath), "%s/%u.dvi", cacheDir, h); unlink(fpath);
            snprintf(fpath, sizeof(fpath), "%s/%u.aux", cacheDir, h); unlink(fpath);
            snprintf(fpath, sizeof(fpath), "%s/%u.log", cacheDir, h); unlink(fpath);

            pthread_mutex_lock(&queueMutex);
            renderQueue[jobIndex].state = (status == 0) ? 3 : 4;
            pthread_mutex_unlock(&queueMutex);
        } else {
            pthread_mutex_lock(&queueMutex);
            renderQueue[jobIndex].state = 3;
            pthread_mutex_unlock(&queueMutex);
        }
    }
    return NULL;
}

Texture2D renderLatex(const char* latex, bool* hasError) {
    if (hasError) *hasError = false;

    for (int i = 0; i < sessionCacheCount; i++) {
        if (strcmp(sessionCache[i].latex, latex) == 0) return sessionCache[i].tex;
    }

    char pngPath[1024];
    getCachePaths(latex, NULL, NULL, pngPath);

    if (access(pngPath, F_OK) == 0) {
        Image img = LoadImage(pngPath);
        Texture2D tex = LoadTextureFromImage(img);
        UnloadImage(img);

        SetTextureFilter(tex, TEXTURE_FILTER_BILINEAR);

        if (sessionCacheCount < CACHE_SIZE) {
            strncpy(sessionCache[sessionCacheCount].latex, latex, 255);
            sessionCache[sessionCacheCount].tex = tex;
            sessionCacheCount++;
        }
        return tex;
    }

    pthread_mutex_lock(&queueMutex);
    bool found = false;
    for (int i = 0; i < CACHE_SIZE; i++) {
        if (renderQueue[i].state != 0 && strcmp(renderQueue[i].latex, latex) == 0) {
            found = true;
            if (renderQueue[i].state == 4 && hasError) { *hasError = true; }
            break;
        }
    }

    if (!found) {
        for (int i = 0; i < CACHE_SIZE; i++) {
            if (renderQueue[i].state == 0) {
                strncpy(renderQueue[i].latex, latex, 255);
                renderQueue[i].state = 1;
                pthread_cond_signal(&queueCond);
                break;
            }
        }
    }
    pthread_mutex_unlock(&queueMutex);

    return (Texture2D){0};
}

void initializeLabels(void) {
    pthread_t threadId;
    pthread_create(&threadId, NULL, latexWorkerThread, NULL);
    pthread_detach(threadId);
}

void freeLabelsMemory(void) {
    for (int i = 0; i < sessionCacheCount; i++) {
        if (sessionCache[i].tex.id != 0) {
            UnloadTexture(sessionCache[i].tex);
        }
    }
    sessionCacheCount = 0;
}
