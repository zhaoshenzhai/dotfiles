#include "attic.h"

int generateMetadata(int id, int updateModified) {
    if (id >= noteCapacity || !notes[id].active) {
        printf("%sError: Note %05d does not exist.%s\n", RED, id, NC);
        return 1;
    }

    char modDate[64] = "";
    if (updateModified || strlen(notes[id].modDate) == 0) {
        struct stat st;
        char texPath[PATH_MAX];
        snprintf(texPath, sizeof(texPath), "%s/%05d/%05d.tex", atticDir, id, id);
        if (stat(texPath, &st) == 0) {
            struct tm *tmInfo = localtime(&st.st_mtime);
            strftime(modDate, sizeof(modDate), "%Y/%m/%d", tmInfo);
        }
    } else {
        strcpy(modDate, notes[id].modDate);
    }

    int tempOut[notes[id].outCount > 0 ? notes[id].outCount : 1];
    for (int j = 0; j < notes[id].outCount; j++) tempOut[j] = notes[id].outLinks[j].targetID;

    char refs[2048], refIn[2048];
    formatLinks(tempOut, notes[id].outCount, refs);
    formatLinks(notes[id].inLinks, notes[id].inCount, refIn);

    char generated[8192];
    snprintf(generated, sizeof(generated),
        "\\begin{flushleft}\n"
        "    \\color{gray}\\footnotesize\\ttfamily\n"
        "    Last modified: %s \\\\\n"
        "    Keywords: [%s] \\\\\n"
        "    References: [%s] \\\\\n"
        "    Referenced in: [%s]\n"
        "\\end{flushleft}\n",
        modDate, SAFE_STR(notes[id].keys), refs, refIn);

    char datPath[PATH_MAX];
    snprintf(datPath, sizeof(datPath), "%s/%05d/%05d.dat", atticDir, id, id);

    FILE *fmeta = fopen(datPath, "w");
    if (!fmeta) {
        fprintf(stderr, "%sError: Could not open %s for writing: %s%s\n", RED, datPath, strerror(errno), NC);
        return 1;
    }
    fputs(generated, fmeta);
    fclose(fmeta);
    return 0;
}

void createNote(const char *inKeywords) {
    char cmd[2048];
    snprintf(cmd, sizeof(cmd), "mkdir -p \"%s\"", atticDir);
    system(cmd);

    int id;
    char path[PATH_MAX];
    srand(time(NULL));
    while (1) {
        id = rand() % 100000;
        snprintf(path, sizeof(path), "%s/%05d", atticDir, id);
        if (access(path, F_OK) != 0) break;
    }

    mkdir(path, 0755);
    snprintf(cmd, sizeof(cmd), "cp \"%s\" \"%s/%05d.tex\"", templateFile, path, id);
    system(cmd);

    char keywords[256] = "";
    if (strcmp(inKeywords, "EMPTY_KEYWORDS") == 0) {
        printf("Note %05d created automatically.\n", id);
    } else if (strlen(inKeywords) > 0) {
        strncpy(keywords, inKeywords, sizeof(keywords)-1);
        printf("Note %05d created automatically.\n", id);
    } else {
        printf("%sEnter keywords for note %05d: %s", PURPLE, id, NC);
        if (fgets(keywords, sizeof(keywords), stdin)) { trimEnd(keywords); }
    }

    char cleanKeys[512] = "";
    int j = 0;
    for(int i = 0; keywords[i] != '\0'; i++) {
        if(keywords[i] == ',') { cleanKeys[j++] = ','; cleanKeys[j++] = ' '; }
        else { cleanKeys[j++] = keywords[i]; }
    }
    char finalKeys[512] = "";
    int k = 0;
    for(int i = 0; cleanKeys[i] != '\0'; i++) {
        if(cleanKeys[i] == ' ' && cleanKeys[i+1] == ' ') continue;
        finalKeys[k++] = cleanKeys[i];
    }

    snprintf(path, sizeof(path), "%s/%05d/%05d.key", atticDir, id, id);
    FILE *fkey = fopen(path, "w");
    if (fkey) { fputs(finalKeys, fkey); fputs("\n", fkey); fclose(fkey); }

    loadMemory();
    generateMetadata(id, 1);
    exportGraph(1);

    snprintf(cmd, sizeof(cmd), "%s --update &", launcherPath);
    system(cmd);
    compileNote(id);

    if (isInteractive) {
        snprintf(cmd, sizeof(cmd), "nohup %s \"%s/%05d/%05d.tex\" >/dev/null 2>&1 &", launcherPath, atticDir, id, id);
        system(cmd);
        usleep(100000);
        exit(0);
    }
}

void updateMetadata(int id) {
    if (id >= noteCapacity || !notes[id].active) return;

    char cachePath[PATH_MAX];
    const char* home = getenv("HOME");
    if (home) {
        unsigned int h = hashString(SAFE_STR(notes[id].keys));
        snprintf(cachePath, sizeof(cachePath), "%s/.cache/attic/labels/%u.png", home, h);
        unlink(cachePath);
    }

    int oldIds[1000];
    int oldCount = 0;
    extracIDs(SAFE_STR(notes[id].metaRefsRaw), oldIds, &oldCount);
    oldCount = dedupe(oldIds, oldCount);

    int newIds[1000];
    int newCount = notes[id].outCount;
    for (int i = 0; i < newCount; i++) newIds[i] = notes[id].outLinks[i].targetID;
    newCount = dedupe(newIds, newCount);

    int linksChanged = 0;
    if (oldCount != newCount) {
        linksChanged = 1;
    } else {
        for (int i = 0; i < oldCount; i++) {
            if (oldIds[i] != newIds[i]) {
                linksChanged = 1;
                break;
            }
        }
    }

    generateMetadata(id, 1);
    compileNote(id);

    if (linksChanged) {
        printf("%sLinks changed. Propagating metadata to neighbors...%s\n", YELLOW, NC);

        int combinedRefs[2000];
        int combinedCount = 0;
        for (int i = 0; i < oldCount; i++) combinedRefs[combinedCount++] = oldIds[i];
        for (int i = 0; i < newCount; i++) combinedRefs[combinedCount++] = newIds[i];

        int uniqueCount = dedupe(combinedRefs, combinedCount);

        for (int i = 0; i < uniqueCount; i++) {
            int refId = combinedRefs[i];
            if (refId != id && notes[refId].active) {
                generateMetadata(refId, 0);
                compileNote(refId);
            }
        }
    } else {
        printf("%sNo link changes detected. Skipping neighbor updates.%s\n", GREEN, NC);
    }

    loadMemory();
    exportGraph(1);
}

void auditNotes(void) {
    loadMemory();
    printf("%sVerifying links, missing PDFs, and scanning for TODOs...%s\n", BLUE, NC);
    int broken = 0, todos = 0, desync = 0, missingPdfs = 0;

    for (int i = 0; i < noteCapacity; i++) {
        if (!notes[i].active) continue;

        if (!notes[i].hasPdf) {
            printf("%s[MISSING PDF]%s Note %05d[%s] has no compiled PDF.\n", RED, NC, i, SAFE_STR(notes[i].keys));
            missingPdfs++;
        }

        for (int j = 0; j < notes[i].outCount; j++) {
            int target = notes[i].outLinks[j].targetID;
            int lno = notes[i].outLinks[j].lineNumber;

            char err[32] = "";
            if (!notes[target].active) strcat(err, "TEX");
            if (!notes[target].hasPdf) {
                if (err[0] != '\0') strcat(err, " & ");
                strcat(err, "PDF");
            }

            if (err[0] != '\0') {
                printf("%s[BROKEN LINK]%s ID %05d (Missing %s) referenced in %05d[%s]:%d\n", RED, NC, target, err, i, notes[i].keys, lno);
                broken++;
            }
        }

        for (int j = 0; j < notes[i].todoCount; j++) {
            printf("%s[TODO]%s %05d[%s]:%d -> %s\n", YELLOW, NC, i, notes[i].keys, notes[i].todos[j].lineNumber, notes[i].todos[j].text);
            todos++;
        }

        int tempOut[notes[i].outCount > 0 ? notes[i].outCount : 1];
        for (int j = 0; j < notes[i].outCount; j++) tempOut[j] = notes[i].outLinks[j].targetID;

        char expectedRefs[4096], formattedRefs[2048];
        formatLinks(tempOut, notes[i].outCount, formattedRefs);
        snprintf(expectedRefs, sizeof(expectedRefs), "References: [%s]", formattedRefs);

        char expectedRefIn[4096], formattedRefIn[2048];
        formatLinks(notes[i].inLinks, notes[i].inCount, formattedRefIn);
        snprintf(expectedRefIn, sizeof(expectedRefIn), "Referenced in: [%s]", formattedRefIn);

        if (strcmp(expectedRefs, SAFE_STR(notes[i].metaRefsRaw)) != 0 ||
            strcmp(expectedRefIn, SAFE_STR(notes[i].metaRefInRaw)) != 0) {
            printf("%s[DESYNC]%s Metadata for %05d[%s] out of sync.\n", PURPLE, NC, i, SAFE_STR(notes[i].keys));
            desync++;
        }
    }

    printf("----------------------------------------\n");
    if (broken == 0 && missingPdfs == 0) {
        printf("%sLinks & PDFs: Valid!%s\n", GREEN, NC);
    } else {
        if (broken > 0) printf("%sLinks: Found %d broken link(s).%s\n", RED, broken, NC);
        if (missingPdfs > 0) printf("%sPDFs: Found %d missing PDF(s).%s\n", RED, missingPdfs, NC);
    }

    if (desync == 0) printf("%sMetadata: Valid!%s\n", GREEN, NC);
    else printf("%sMetadata: %d note(s) have desynchronized metadata. Run 'rebuild all' (r) to fix.%s\n", PURPLE, desync, NC);

    if (todos == 0) printf("%sTODOs: None found!%s\n", GREEN, NC);
    else printf("%sTODOs: You have %d pending TODO(s).%s\n", YELLOW, todos, NC);
}

void rebuildNotes(void) {
    int totalNotes = 0;
    for (int i = 0; i < noteCapacity; i++) { if (notes[i].active) totalNotes++; }

    if (totalNotes == 0) {
        printf("%sNo notes found to rebuild.%s\n", GREEN, NC);
        return;
    }

    printf("%sRebuilding notes...%s\n", BLUE, NC);

    int runningJobs = 0, totalProcessed = 0, totalRebuilt = 0, totalFailed = 0;
    int *failedIds = NULL;

    int totalLines = 0;

    typedef struct { pid_t pid; int id; int row; } RebuildJob;
    RebuildJob jobs[MAX_JOBS];
    for (int i = 0; i < MAX_JOBS; i++) {
        jobs[i].pid = 0;
        jobs[i].id = 0;
        jobs[i].row = -1;
    }

    #define PROCESS_FINISHED_JOB(p, s) do { \
        for (int j = 0; j < MAX_JOBS; j++) { \
            if (jobs[j].pid == (p)) { \
                char dp[PATH_MAX], bp[PATH_MAX]; \
                snprintf(dp, sizeof(dp), "%s/%05d/%05d.dat", atticDir, jobs[j].id, jobs[j].id); \
                snprintf(bp, sizeof(bp), "%s/%05d/%05d.dat.bak", atticDir, jobs[j].id, jobs[j].id); \
                \
                int diff = (totalLines > 0 ? totalLines - 1 : 0) - jobs[j].row; \
                if (diff > 0) printf("\033[%dA", diff); \
                printf("\r\033[2K"); \
                \
                if (WIFEXITED((s)) && WEXITSTATUS((s)) == 0) { \
                    unlink(bp); \
                    totalRebuilt++; \
                } else { \
                    printf("%sNote %05d failed to compile!%s", RED, jobs[j].id, NC); \
                    if (access(bp, F_OK) == 0) rename(bp, dp); else unlink(dp); \
                    failedIds[totalFailed++] = jobs[j].id; \
                    jobs[j].row = -1; \
                } \
                \
                if (diff > 0) printf("\033[%dB", diff); \
                printf("\r"); \
                fflush(stdout); \
                \
                jobs[j].pid = 0; \
                runningJobs--; \
                break; \
            } \
        } \
    } while(0)

    for (int i = 0; i < noteCapacity; i++) {
        if (!notes[i].active) continue;

        totalProcessed++;

        char texPath[PATH_MAX], logPath[PATH_MAX];
        struct stat st_tex, st_log;
        snprintf(texPath, sizeof(texPath), "%s/%05d/%05d.tex", atticDir, i, i);
        snprintf(logPath, sizeof(logPath), "%s/%05d/%05d.log", atticDir, i, i);

        int needsRebuild = 0;
        if (stat(texPath, &st_tex) == 0) {
            if (stat(logPath, &st_log) != 0 || st_tex.st_mtime > st_log.st_mtime) {
                needsRebuild = 1;
            }
        }

        if (needsRebuild) {
            char dp[PATH_MAX], bp[PATH_MAX];
            snprintf(dp, sizeof(dp), "%s/%05d/%05d.dat", atticDir, i, i);
            snprintf(bp, sizeof(bp), "%s/%05d/%05d.dat.bak", atticDir, i, i);
            rename(dp, bp);
        }

        generateMetadata(i, 0);

        int status;
        pid_t pid;
        while ((pid = waitpid(-1, &status, WNOHANG)) > 0) {
            PROCESS_FINISHED_JOB(pid, status);
        }

        if (!needsRebuild) {
            continue;
        }

        while (runningJobs >= MAX_JOBS) {
            pid = waitpid(-1, &status, 0);
            if (pid > 0) {
                PROCESS_FINISHED_JOB(pid, status);
            }
        }

        pid = fork();
        if (pid == 0) {
            char dirPath[PATH_MAX]; snprintf(dirPath, sizeof(dirPath), "%s/%05d", atticDir, i);
            if (chdir(dirPath) != 0) exit(1);
            char texFile[32]; snprintf(texFile, sizeof(texFile), "%05d.tex", i);

            freopen("/dev/null", "w", stdout);
            freopen("/dev/null", "w", stderr);

            execlp("latexmk", "latexmk", "-pdf", "-pvc-", "-interaction=nonstopmode", texFile, NULL);
            exit(1);
        } else if (pid > 0) {
            for (int j = 0; j < MAX_JOBS; j++) {
                if (jobs[j].pid == 0) {
                    jobs[j].pid = pid;
                    jobs[j].id = i;

                    if (jobs[j].row == -1) {
                        if (totalLines > 0) printf("\n");
                        jobs[j].row = totalLines;
                        totalLines++;
                    }

                    int diff = (totalLines > 0 ? totalLines - 1 : 0) - jobs[j].row;
                    if (diff > 0) printf("\033[%dA", diff);
                    printf("\r\033[2K%sRebuilding %05d (%d/%d)...%s", YELLOW, i, totalProcessed, totalNotes, NC);
                    if (diff > 0) printf("\033[%dB", diff);
                    printf("\r");
                    fflush(stdout);

                    break;
                }
            }
            runningJobs++;
        }
    }

    while (runningJobs > 0) {
        int status;
        pid_t pid = waitpid(-1, &status, 0);
        if (pid > 0) {
            PROCESS_FINISHED_JOB(pid, status);
        }
    }

    #undef PROCESS_FINISHED_JOB

    if (totalLines > 0) printf("\n");
    printf("\r%sRebuild complete. Processed %d notes, %d were recompiled.%s\n",
        GREEN, totalProcessed, totalRebuilt, NC);

    if (totalFailed > 0) {
        printf("%sWarning: %d note(s) failed to compile.%s\n", RED, totalFailed, NC);
        printf("%sFailed IDs: ", RED);
        for (int i = 0; i < totalFailed; i++) {
            printf("%05d%s", failedIds[i], (i == totalFailed - 1) ? "" : ", ");
        }
        printf("%s\n", NC);
    }

    if (failedIds) free(failedIds);
    loadMemory();
    exportGraph(1);
}

void cleanAttic(void) {
    printf("%sCleaning auxiliary and files...%s\n", BLUE, NC);
    int cleanedCount = 0;

    const char *extensions[] = {
        ".aux", ".bbl", ".bcf", ".bcf-SAVE-ERROR", ".bbl-SAVE-ERROR",
        ".blg", ".fdb_latexmk", ".fls", ".log", ".run.xml",
        ".synctex.gz", ".synctex(busy)"
    };
    int numexts = sizeof(extensions) / sizeof(extensions[0]);

    for (int i = 0; i < noteCapacity; i++) {
        if (!notes[i].active) continue;

        char dirPath[PATH_MAX];
        snprintf(dirPath, sizeof(dirPath), "%s/%05d", atticDir, i);

        DIR *d = opendir(dirPath);
        if (!d) continue;

        int noteCleaned = 0;
        struct dirent *dir;

        while ((dir = readdir(d)) != NULL) {
            if (strcmp(dir->d_name, ".") == 0 || strcmp(dir->d_name, "..") == 0) continue;

            int len = strlen(dir->d_name);
            int shouldDelete = 0;

            char *spacePtr = strchr(dir->d_name, ' ');
            if (spacePtr != NULL) {
                if (isdigit(spacePtr[1]) && spacePtr[2] == '.') {
                    shouldDelete = 1;
                }
            }

            if (!shouldDelete) {
                for (int j = 0; j < numexts; j++) {
                    int extLen = strlen(extensions[j]);
                    if (len >= extLen && strcmp(dir->d_name + len - extLen, extensions[j]) == 0) {
                        shouldDelete = 1;
                        break;
                    }
                }
            }

            if (shouldDelete) {
                char filepath[PATH_MAX * 2];
                snprintf(filepath, sizeof(filepath), "%s/%s", dirPath, dir->d_name);
                if (unlink(filepath) == 0) {
                    noteCleaned = 1;
                }
            }
        }
        closedir(d);

        if (noteCleaned) {
            cleanedCount++;
        }
    }

    printf("%sCleaned files in %d note directories.%s\n", GREEN, cleanedCount, NC);
    loadMemory();
    exportGraph(1);
}

void exportGraph(int silent) {
    char path[PATH_MAX];
    snprintf(path, sizeof(path), "%s/../graph.json", atticDir);

    FILE *f = fopen(path, "w");
    if (!f) {
        if (!silent) fprintf(stderr, "%sError opening %s for writing: %s%s\n", RED, path, strerror(errno), NC);
        return;
    }

    if (!silent) printf("%sExporting memory graph to JSON...%s\n", BLUE, NC);

    fprintf(f, "{\n  \"nodes\": [\n");
    int firstNode = 1;
    for (int i = 0; i < noteCapacity; i++) {
        if (!notes[i].active) continue;
        if (!firstNode) fprintf(f, ",\n");

        char safeKeys[1024] = "";
        int k = 0;
        const char *kStr = SAFE_STR(notes[i].keys);
        for (int j = 0; kStr[j] != '\0' && k < 1000; j++) {
            if (kStr[j] == '"' || kStr[j] == '\\') safeKeys[k++] = '\\';
            safeKeys[k++] = kStr[j];
        }

        fprintf(f, "    { \"id\": \"%05d\", \"label\": \"%s\", \"hasPdf\": %s, \"modDate\": \"%s\", \"todoCount\": %d }",
            i, safeKeys, notes[i].hasPdf ? "true" : "false", notes[i].modDate, notes[i].todoCount);
        firstNode = 0;
    }

    fprintf(f, "\n  ],\n  \"edges\": [\n");
    int firstedge = 1;
    for (int i = 0; i < noteCapacity; i++) {
        if (!notes[i].active) continue;
        for (int j = 0; j < notes[i].outCount; j++) {
            if (!firstedge) fprintf(f, ",\n");
            fprintf(f, "    { \"source\": \"%05d\", \"target\": \"%05d\", \"lineNumber\": %d }",
                i, notes[i].outLinks[j].targetID, notes[i].outLinks[j].lineNumber);
            firstedge = 0;
        }
    }

    fprintf(f, "\n  ]\n}\n");
    fclose(f);

    if (!silent) printf("%sGraph data successfully exported to %s%s\n", GREEN, path, NC);
}

void launchGraph(void) {
    exportGraph(1);
    char cmd[PATH_MAX + 128];
    snprintf(cmd, sizeof(cmd), "cd '%s/..' && nohup bash -c 'exec -a attic attic-graph' > /dev/null 2>&1 &", atticDir);
    system(cmd);

    system("osascript -e 'tell application \"System Events\" to set visible of front process to false'");
    usleep(100000);
    exit(0);
}
