#include "texManager.h"
#include "attic.h"

int generateMetadata(int id) {
    if (id >= noteCapacity || !notes[id].active) {
        printf("%sError: Note %05d does not exist.%s\n", RED, id, NC);
        return 1;
    }

    char modDate[64] = "";
    if (strlen(notes[id].modDate) == 0) {
        time_t now = time(NULL);
        struct tm *tmInfo = localtime(&now);
        strftime(modDate, sizeof(modDate), "%Y/%m/%d %H:%M:%S", tmInfo);
        strcpy(notes[id].modDate, modDate);
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

    int needsWrite = 1;
    FILE *fcheck = fopen(datPath, "r");
    if (fcheck) {
        char existing[8192] = {0};
        size_t bytes = fread(existing, 1, sizeof(existing) - 1, fcheck);
        existing[bytes] = '\0';
        fclose(fcheck);

        if (strcmp(existing, generated) == 0) { needsWrite = 0; }
    }

    if (needsWrite) {
        FILE *fmeta = fopen(datPath, "w");
        if (!fmeta) {
            fprintf(stderr, "%sError: Could not open %s for writing: %s%s\n", RED, datPath, strerror(errno), NC);
            return 1;
        }
        fputs(generated, fmeta);
        fclose(fmeta);
    }

    return 0;
}

void createNote(const char *inKeywords) {
    EnsureDirectoryExists(atticDir);

    int id;
    char path[PATH_MAX];
    srand(time(NULL));
    while (1) {
        id = rand() % 100000;
        snprintf(path, sizeof(path), "%s/%05d", atticDir, id);
        if (access(path, F_OK) != 0) break;
    }

    EnsureDirectoryExists(path);

    @autoreleasepool {
        NSString *nsTemplate = [NSString stringWithUTF8String:templateFile];
        NSString *nsDest = [NSString stringWithFormat:@"%s/%05d.tex", path, id];
        [[NSFileManager defaultManager] copyItemAtPath:nsTemplate toPath:nsDest error:nil];
    }

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
    generateMetadata(id);
    exportGraph(1);

    @autoreleasepool {
        NSString *nsLauncher = [NSString stringWithUTF8String:launcherPath];
        RunCommandDetached(nsLauncher, @[@"--update"]);
    }

    compileNote(id);

    if (isInteractive) {
        @autoreleasepool {
            NSString *nsLauncher = [NSString stringWithUTF8String:launcherPath];
            NSString *nsTarget = [NSString stringWithFormat:@"%s/%05d/%05d.tex", atticDir, id, id];
            RunCommandDetached(nsLauncher, @[nsTarget]);
        }
        usleep(100000);
        exit(0);
    }
}

void updateMetadata(int id) {
    if (id >= noteCapacity || !notes[id].active) return;

    char cachePath[PATH_MAX];
    const char* home = getenv("HOME");
    if (home) {
        unsigned int h = HashString(SAFE_STR(notes[id].keys));
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

    generateMetadata(id);
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
                generateMetadata(refId);
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

    int *sortedIds = malloc(noteCapacity * sizeof(int));
    if (!sortedIds) {
        fprintf(stderr, "%sError: Failed to allocate memory for sorting notes.%s\n", RED, NC);
        return;
    }

    int activeCount = 0;
    for (int i = 0; i < noteCapacity; i++) {
        if (notes[i].active) sortedIds[activeCount++] = i;
    }

    qsort(sortedIds, activeCount, sizeof(int), compareModDateDesc);

    for (int k = 0; k < activeCount; k++) {
        int i = sortedIds[k];

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

    free(sortedIds);

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
    int *failedIds = safeMalloc(totalNotes * sizeof(int));
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
                    printf("%sNote %05d failed!%s", RED, jobs[j].id, NC); \
                    if (access(bp, F_OK) == 0) rename(bp, dp); else unlink(dp); \
                    failedIds[totalFailed++] = jobs[j].id; \
                } \
                \
                if (diff > 0) printf("\033[%dB", diff); \
                printf("\r"); \
                fflush(stdout); \
                \
                jobs[j].pid = 0; \
                jobs[j].row = -1; \
                runningJobs--; \
                break; \
            } \
        } \
    } while(0)

    for (int i = 0; i < noteCapacity; i++) {
        if (!notes[i].active) continue;

        totalProcessed++;

        if (isCompiling(i)) { continue; }

        char dp[PATH_MAX], bp[PATH_MAX];
        snprintf(dp, sizeof(dp), "%s/%05d/%05d.dat", atticDir, i, i);
        snprintf(bp, sizeof(bp), "%s/%05d/%05d.dat.bak", atticDir, i, i);
        rename(dp, bp);

        generateMetadata(i);

        int status;
        pid_t pid;
        while ((pid = waitpid(-1, &status, WNOHANG)) > 0) {
            PROCESS_FINISHED_JOB(pid, status);
        }

        while (runningJobs >= MAX_JOBS) {
            pid = waitpid(-1, &status, 0);
            if (pid > 0) {
                PROCESS_FINISHED_JOB(pid, status);
            }
        }

        pid = fork();
        if (pid == 0) {
            int exitCode = compileNoteSync(i);
            exit(exitCode);
        } else if (pid > 0) {
            for (int j = 0; j < MAX_JOBS; j++) {
                if (jobs[j].pid == 0) {
                    jobs[j].pid = pid;
                    jobs[j].id = i;

                    if (jobs[j].row == -1) {
                        jobs[j].row = j;
                        while (totalLines <= j) {
                            if (totalLines > 0) printf("\n");
                            totalLines++;
                        }
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
    // Keeping bash execution here since 'exec -a' is a shell builtin used to rename the process
    snprintf(cmd, sizeof(cmd), "cd '%s/..' && nohup bash -c 'exec -a attic attic-graph' > /dev/null 2>&1 &", atticDir);
    system(cmd);

    // Replaced system("osascript...") with native execution
    RunCommandWait(@"/usr/bin/osascript", @[@"-e", @"tell application \"System Events\" to set visible of front process to false"]);
    exit(0);
}
