#include "attic.h"

char atticDir[PATH_MAX];
char templateFile[PATH_MAX];
char launcherPath[PATH_MAX];
int isInteractive = 0;

Note *notes = NULL;
int noteCapacity = 0;

void* safeMalloc(size_t size) {
    void* p = malloc(size);
    if (!p && size > 0) {
        fprintf(stderr, "%sError: Out of memory (malloc failed)%s\n", RED, NC);
        exit(1);
    }
    return p;
}

void* safeRealloc(void* p, size_t size) {
    void* newP = realloc(p, size);
    if (!newP && size > 0) {
        fprintf(stderr, "%sError: Out of memory (realloc failed)%s\n", RED, NC);
        exit(1);
    }
    return newP;
}

void ensureNoteCapacity(int maxID) {
    if (maxID >= noteCapacity) {
        int oldCap = noteCapacity;
        noteCapacity = maxID + 1;
        if (noteCapacity < oldCap * 2) noteCapacity = oldCap * 2;
        if (noteCapacity < 128) noteCapacity = 128;

        notes = (Note*)safeRealloc(notes, noteCapacity * sizeof(Note));
        memset(notes + oldCap, 0, (noteCapacity - oldCap) * sizeof(Note));
    }
}

int getch(void) {
    struct termios oldattr, newattr;
    int ch;
    tcgetattr(STDIN_FILENO, &oldattr);
    newattr = oldattr;
    newattr.c_lflag &= ~(ICANON | ECHO);
    tcsetattr(STDIN_FILENO, TCSANOW, &newattr);
    ch = getchar();
    tcsetattr(STDIN_FILENO, TCSANOW, &oldattr);
    return ch;
}

void trimEnd(char *str) {
    int len = strlen(str);
    while (len > 0 && (isspace(str[len - 1]) || str[len - 1] == '\\')) {
        str[len - 1] = '\0';
        len--;
    }
}

int cmp_int(const void *a, const void *b) {
    return (*(int *)a - *(int *)b);
}

int dedupe(int *arr, int count) {
    if (count == 0) return 0;
    qsort(arr, count, sizeof(int), cmp_int);
    int j = 0;
    for (int i = 1; i < count; i++) {
        if (arr[i] != arr[j]) {
            j++;
            arr[j] = arr[i];
        }
    }
    return j + 1;
}

void formatLinks(int *ids, int count, char *outBuf) {
    outBuf[0] = '\0';
    int uniqueCount = dedupe(ids, count);
    for (int i = 0; i < uniqueCount; i++) {
        if (i > 0) strcat(outBuf, ", ");
        char temp[32];
        snprintf(temp, sizeof(temp), "\\aref{%05d}{%05d}", ids[i], ids[i]);
        strcat(outBuf, temp);
    }
}

int isCompiling(int id) {
    char cmd[256];
    snprintf(cmd, sizeof(cmd), "pgrep -f '[l]atexmk.*%05d\\.tex' > /dev/null 2>&1", id);
    int status = system(cmd);

    return (WIFEXITED(status) && WEXITSTATUS(status) == 0);
}

void compileNote(int id) {
    if (isCompiling(id)) return;
    char cmd[2048];
    snprintf(cmd, sizeof(cmd),
        "cd '%s/%05d' && nohup latexmk -pdf -pvc- -interaction=nonstopmode %05d.tex > /dev/null 2>&1 &", atticDir, id, id);
    system(cmd);
}

void extracIDs(const char *str, int *arr, int *count) {
    const char *ptr = str;
    while (*ptr) {
        if (isdigit(*ptr)) {
            int valid = 1;
            for (int i = 0; i < 5; i++) if (!isdigit(ptr[i])) valid = 0;
            if (valid) {
                arr[(*count)++] = atoi(ptr);
                ptr += 4;
            }
        }
        ptr++;
    }
}

unsigned int hashString(const char *str) {
    unsigned int hash = 5381;
    int c;
    while ((c = *str++)) hash = ((hash << 5) + hash) + c;
    return hash;
}
