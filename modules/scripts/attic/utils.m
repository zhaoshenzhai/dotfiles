#import "texManager.h"
#import "attic.h"

char atticDir[PATH_MAX];
int isInteractive = 0;

Note *notes = NULL;
int noteCapacity = 0;

void ensureNoteCapacity(int maxID) {
    if (maxID >= noteCapacity) {
        int oldCap = noteCapacity;
        noteCapacity = maxID + 1;
        if (noteCapacity < oldCap * 2) noteCapacity = oldCap * 2;
        if (noteCapacity < 128) noteCapacity = 128;

        notes = (Note*)SafeRealloc(notes, noteCapacity * sizeof(Note));
        memset(notes + oldCap, 0, (noteCapacity - oldCap) * sizeof(Note));
    }
}

void formatLinks(int *ids, int count, char *outBuf) {
    outBuf[0] = '\0';
    if (count <= 0) return;

    int unique[count];
    int uniqueCount = 0;

    for (int i = 0; i < count; i++) {
        int exists = 0;
        for (int j = 0; j < uniqueCount; j++) {
            if (unique[j] == ids[i]) {
                exists = 1;
                break;
            }
        }
        if (!exists) unique[uniqueCount++] = ids[i];
    }

    for (int i = 0; i < uniqueCount; i++) {
        if (i > 0) strcat(outBuf, ", ");
        char temp[32];
        snprintf(temp, sizeof(temp), "\\aref{%05d}{%05d}", unique[i], unique[i]);
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
