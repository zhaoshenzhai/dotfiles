#pragma once

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <dirent.h>
#include <unistd.h>
#include <termios.h>
#include <sys/stat.h>
#include <sys/wait.h>
#include <time.h>
#include <getopt.h>
#include <limits.h>
#include <libproc.h>
#include <errno.h>

#define SAFE_STR(s) ((s) ? (s) : "")
#define MAX_JOBS 5

#define RED "\x1b[31m"
#define GREEN "\x1b[32m"
#define YELLOW "\x1b[33m"
#define BLUE "\x1b[34m"
#define PURPLE "\x1b[35m"
#define CYAN "\x1b[36m"
#define NC "\x1b[0m"

typedef struct { int targetID; int lineNumber; } OutLink;
typedef struct { char *text; int lineNumber; } Todo;
typedef struct {
    int active; int hasPdf; char modDate[64];
    char *keys; char *metaRefsRaw; char *metaRefInRaw;

    OutLink *outLinks; int outCount;  int outCapacity;
    int *inLinks;      int inCount;   int inCapacity;
    Todo *todos;        int todoCount; int todoCapacity;
} Note;

extern char atticDir[PATH_MAX];
extern char templateFile[PATH_MAX];
extern char launcherPath[PATH_MAX];
extern int isInteractive;

extern Note *notes;
extern int noteCapacity;

void* safeMalloc(size_t size);
void* safeRealloc(void* p, size_t size);
int getch(void);
void trimEnd(char *str);
int cmp_int(const void *a, const void *b);
int dedupe(int *arr, int count);
void formatLinks(int *ids, int count, char *outBuf);
int isCompiling(int id);
void compileNote(int id);
void extracIDs(const char *str, int *arr, int *count);
unsigned int hashString(const char *str);
void ensureNoteCapacity(int maxID);

void freeMemory(void);
void addOutLink(int src, int target, int lineNumber);
void addInLink(int target, int src);
void addTodo(int id, int lineNumber, const char *text);
void loadMemory(void);

int generateMetadata(int id, int updateModified);
void createNote(const char *inKeywords);
void updateMetadata(int id);
void auditNotes(void);
void rebuildNotes(void);
void cleanAttic(void);
void exportGraph(int silent);
void launchGraph(void);
