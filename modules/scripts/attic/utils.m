#include "texManager.h"
#include "attic.h"

char atticDir[PATH_MAX];
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
    static bool seen[100000];
    memset(seen, 0, sizeof(seen));

    int j = 0;
    for (int i = 0; i < count; i++) {
        if (arr[i] >= 0 && arr[i] < 100000) {
            if (!seen[arr[i]]) {
                seen[arr[i]] = true;
                arr[j++] = arr[i];
            }
        }
    }
    return j;
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
    char pattern[512];
    snprintf(pattern, sizeof(pattern), "[l]atexmk.*%05d.tex", id);
    return IsProcessRunning(pattern) ? 1 : 0;
}

int compileNoteSync(int id) {
    char webOutDir[PATH_MAX];
    snprintf(webOutDir, sizeof(webOutDir), "%s/Projects/_web/attic/notes", kBaseDir.UTF8String);

    char dirPath[PATH_MAX];
    char fileName[64];

    snprintf(dirPath, sizeof(dirPath), "%s/%05d", atticDir, id);
    snprintf(fileName, sizeof(fileName), "%05d.tex", id);

    TexConfig config;
    texInitConfig(&config);
    config.nonstop = true;

    __block int pdf_exit = 1;
    __block int svg_exit = 1;

    char *ptrWebOutDir = webOutDir;
    char *ptrDirPath = dirPath;
    char *ptrFileName = fileName;
    TexConfig *ptrConfig = &config;

    dispatch_group_t group = dispatch_group_create();

    dispatch_group_async(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        pdf_exit = texCompile(ptrDirPath, ptrFileName, ptrConfig);
    });

    dispatch_group_async(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        svg_exit = texCompileToSvg(ptrDirPath, ptrFileName, ptrWebOutDir);
    });

    dispatch_group_wait(group, DISPATCH_TIME_FOREVER);

    return (pdf_exit == 0 && svg_exit == 0) ? 0 : 1;
}

void compileNote(int id) {
    @autoreleasepool {
        NSString *atticExe = [[NSProcessInfo processInfo] arguments].firstObject;
        NSString *idStr = [NSString stringWithFormat:@"%d", id];
        RunCommandDetached(atticExe, @[@"-c", idStr]);
    }
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

int compareModDateDesc(const void *a, const void *b) {
    int idA = *(const int*)a;
    int idB = *(const int*)b;

    int cmp = strcmp(notes[idB].modDate, notes[idA].modDate);
    if (cmp != 0) { return cmp; }
    return idB - idA;
}
