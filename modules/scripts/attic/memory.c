#include "attic.h"

void freeMemory(void) {
    for (int i = 0; i < noteCapacity; i++) {
        if (notes[i].outLinks) { free(notes[i].outLinks); notes[i].outLinks = NULL; }
        if (notes[i].inLinks) { free(notes[i].inLinks); notes[i].inLinks = NULL; }
        for (int j = 0; j < notes[i].todoCount; j++) { if (notes[i].todos[j].text) free(notes[i].todos[j].text); }
        if (notes[i].todos) { free(notes[i].todos); notes[i].todos = NULL; }
        if (notes[i].keys) { free(notes[i].keys); notes[i].keys = NULL; }
        if (notes[i].metaRefsRaw) { free(notes[i].metaRefsRaw); notes[i].metaRefsRaw = NULL; }
        if (notes[i].metaRefInRaw) { free(notes[i].metaRefInRaw); notes[i].metaRefInRaw = NULL; }

        notes[i].outCount = notes[i].outCapacity = 0;
        notes[i].inCount = notes[i].inCapacity = 0;
        notes[i].todoCount = notes[i].todoCapacity = 0;
    }
}

void addOutLink(int src, int target, int lineNumber) {
    if (notes[src].outCount >= notes[src].outCapacity) {
        notes[src].outCapacity = notes[src].outCapacity == 0 ? 8 : notes[src].outCapacity * 2;
        notes[src].outLinks = (OutLink*)safeRealloc(notes[src].outLinks, notes[src].outCapacity * sizeof(OutLink));
    }
    notes[src].outLinks[notes[src].outCount++] = (OutLink){target, lineNumber};
}

void addInLink(int target, int src) {
    if (notes[target].inCount >= notes[target].inCapacity) {
        notes[target].inCapacity = notes[target].inCapacity == 0 ? 8 : notes[target].inCapacity * 2;
        notes[target].inLinks = safeRealloc(notes[target].inLinks, notes[target].inCapacity * sizeof(int));
    }
    notes[target].inLinks[notes[target].inCount++] = src;
}

void addTodo(int id, int lineNumber, const char *text) {
    if (notes[id].todoCount >= notes[id].todoCapacity) {
        notes[id].todoCapacity = notes[id].todoCapacity == 0 ? 4 : notes[id].todoCapacity * 2;
        notes[id].todos = safeRealloc(notes[id].todos, notes[id].todoCapacity * sizeof(Todo));
    }
    while (isspace(*text)) text++;
    char *textCopy = strdup(text);
    trimEnd(textCopy);
    notes[id].todos[notes[id].todoCount++] = (Todo){textCopy, lineNumber};
}

void loadMemory(void) {
    freeMemory();
    if (notes) { memset(notes, 0, noteCapacity * sizeof(Note)); }

    DIR *dir = opendir(atticDir);
    if (!dir) return;

    struct dirent *entry;
    while ((entry = readdir(dir)) != NULL) {
        if (strlen(entry->d_name) == 5 && isdigit(entry->d_name[0])) {
            int id = atoi(entry->d_name);
            ensureNoteCapacity(id);
            notes[id].active = 1;

            char path[PATH_MAX];
            snprintf(path, sizeof(path), "%s/%05d/%05d.pdf", atticDir, id, id);
            notes[id].hasPdf = (access(path, F_OK) == 0);

            snprintf(path, sizeof(path), "%s/%05d/%05d.key", atticDir, id, id);
            FILE *fkey = fopen(path, "r");
            if (fkey) {
                char tempKeys[1024] = "";
                if (fgets(tempKeys, sizeof(tempKeys), fkey)) {
                    trimEnd(tempKeys);
                    notes[id].keys = strdup(tempKeys);
                }
                fclose(fkey);
            }

            snprintf(path, sizeof(path), "%s/%05d/%05d.dat", atticDir, id, id);
            FILE *fdat = fopen(path, "r");
            if (fdat) {
                char line[4096];
                while (fgets(line, sizeof(line), fdat)) {
                    char *start = line;
                    while (isspace(*start)) start++;
                    if (strncmp(start, "Last modified:", 14) == 0) {
                        sscanf(start + 14, " %63[^\n]", notes[id].modDate);
                        trimEnd(notes[id].modDate);
                    } else if (strncmp(start, "References:", 11) == 0) {
                        trimEnd(start); notes[id].metaRefsRaw = strdup(start);
                    } else if (strncmp(start, "Referenced in:", 14) == 0) {
                        trimEnd(start); notes[id].metaRefInRaw = strdup(start);
                    }
                }
                fclose(fdat);
            }
        }
    }
    closedir(dir);

    for (int i = 0; i < noteCapacity; i++) {
        if (!notes[i].active) continue;

        char path[PATH_MAX];
        snprintf(path, sizeof(path), "%s/%05d/%05d.tex", atticDir, i, i);
        FILE *ftex = fopen(path, "r");
        if (!ftex) continue;

        char *line = NULL; size_t len = 0; int lineNumber = 0;
        while (getline(&line, &len, ftex) != -1) {
            lineNumber++;
            if (strstr(line, "TODO")) addTodo(i, lineNumber, line);

            char *ptr = line;
            while ((ptr = strstr(ptr, "\\aref{")) != NULL) {
                char *scan = ptr + 6;
                while (*scan) {
                    if (strncmp(scan, "}{", 2) == 0 && isdigit(scan[2]) && scan[7] == '}') {
                        int targetID = 0;
                        for (int k = 0; k < 5; k++) targetID = targetID * 10 + (scan[2 + k] - '0');
                        addOutLink(i, targetID, lineNumber);
                        addInLink(targetID, i);
                        break;
                    }
                    scan++;
                }
                ptr += 6;
            }
        }
        free(line); fclose(ftex);
    }
}
