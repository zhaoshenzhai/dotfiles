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

unsigned int HashString(const char *str) {
    unsigned int hash = 5381;
    int c;
    while ((c = *str++)) hash = ((hash << 5) + hash) + c;
    return hash;
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

        unsigned int h = HashString(currentLatex);
        char cacheDir[512], pngPath[1024];
        const char* home = getenv("HOME");
        snprintf(cacheDir, sizeof(cacheDir), "%s/.cache/attic/math", home ? home : "/tmp");
        snprintf(pngPath, sizeof(pngPath), "%s/%u.png", cacheDir, h);

        if (access(pngPath, F_OK) != 0) {
            char mkdirCmd[1024];
            snprintf(mkdirCmd, sizeof(mkdirCmd), "mkdir -p \"%s\"", cacheDir);
            system(mkdirCmd);

            char texPath[1024], cmd[2048];
            snprintf(texPath, sizeof(texPath), "/tmp/attic_%u.tex", h);
            FILE *f = fopen(texPath, "w");
            fprintf(f, "\\documentclass[preview,border=2pt]{standalone}\n"
                       "\\usepackage{amsmath,amssymb,amsfonts,xcolor,mlmodern}\n"
                       "\\definecolor{atticfg}{HTML}{FFFFFF}\n"
                       "\\begin{document}\\color{atticfg}%s\\end{document}", currentLatex);
            fclose(f);

            snprintf(cmd, sizeof(cmd),
                "zsh -l -c \"latex -interaction=nonstopmode -output-directory=/tmp %s && "
                "dvipng -bg Transparent -D 600 -o %s /tmp/attic_%u.dvi\" > /tmp/attic_error.log 2>&1",
                texPath, pngPath, h);
            system(cmd);
            remove(texPath);
        }

        pthread_mutex_lock(&queueMutex);
        renderQueue[jobIndex].state = 3;
        pthread_mutex_unlock(&queueMutex);
    }
    return NULL;
}

Texture2D renderLatex(const char* latex) {
    for (int i = 0; i < sessionCacheCount; i++) {
        if (strcmp(sessionCache[i].latex, latex) == 0) return sessionCache[i].tex;
    }

    unsigned int h = HashString(latex);
    char pngPath[1024];
    const char* home = getenv("HOME");
    snprintf(pngPath, sizeof(pngPath), "%s/.cache/attic/math/%u.png", home ? home : "/tmp", h);

    if (access(pngPath, F_OK) == 0) {
        Image img = LoadImage(pngPath);
        Texture2D tex = LoadTextureFromImage(img);
        UnloadImage(img);

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
