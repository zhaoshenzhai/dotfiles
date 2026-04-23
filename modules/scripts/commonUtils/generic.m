#import "commonUtils.h"
#include <termios.h>

int GetCh(void) {
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

int CompareInt(const void *a, const void *b) {
    return (*(int *)a - *(int *)b);
}

int DedupeIntArray(int *arr, int count) {
    if (count <= 1) return count;
    qsort(arr, count, sizeof(int), CompareInt);
    int j = 1;
    for (int i = 1; i < count; i++) {
        if (arr[i] != arr[i-1]) {
            arr[j++] = arr[i];
        }
    }
    return j;
}

void TrimEnd(char *str) {
    int len = (int)strlen(str);
    while (len > 0 && (isspace(str[len - 1]) || str[len - 1] == '\\')) {
        str[len - 1] = '\0';
        len--;
    }
}

void *SafeMalloc(size_t size) {
    void *p = malloc(size);
    if (!p && size > 0) {
        fprintf(stderr, "\x1b[31mError: Out of memory (malloc failed)\x1b[0m\n");
        exit(1);
    }
    return p;
}

void *SafeRealloc(void *p, size_t size) {
    void *newP = realloc(p, size);
    if (!newP && size > 0) {
        fprintf(stderr, "\x1b[31mError: Out of memory (realloc failed)\x1b[0m\n");
        exit(1);
    }
    return newP;
}

unsigned int HashString(const char *str) {
    unsigned int hash = 5381;
    int c;
    while ((c = *str++)) hash = ((hash << 5) + hash) + c;
    return hash;
}

void EnsureSystemPath(void) {
    const char *currentPath = getenv("PATH");
    char newPath[8192];
    snprintf(newPath, sizeof(newPath),
        "/run/current-system/sw/bin:        \
         /etc/profiles/per-user/zhao/bin:     \
         %s/.nix-profile/bin:               \
         /nix/var/nix/profiles/default/bin: \
         /opt/homebrew/bin:                 \
         /usr/local/bin:%s", getenv("HOME"), currentPath ? currentPath : "");
    setenv("PATH", newPath, 1);
}

int EnsureDirectoryExists(const char *path) {
    @autoreleasepool {
        NSString *nsPath = [NSString stringWithUTF8String:path];
        NSError *error = nil;
        [[NSFileManager defaultManager] createDirectoryAtPath:nsPath
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:&error];
        return error == nil ? 0 : 1;
    }
}

bool IsProcessRunning(const char *pattern) {
    @autoreleasepool {
        NSString *cmd = @"/usr/bin/pgrep";
        NSArray *args = @[@"-f", [NSString stringWithUTF8String:pattern]];
        int status = RunCommandWait(cmd, args);
        return (status == 0);
    }
}

int MoveFile(const char *src, const char *dst) {
    @autoreleasepool {
        NSString *nsSrc = [NSString stringWithUTF8String:src];
        NSString *nsDst = [NSString stringWithUTF8String:dst];
        NSFileManager *fm = [NSFileManager defaultManager];

        [fm removeItemAtPath:nsDst error:nil];
        return [fm moveItemAtPath:nsSrc toPath:nsDst error:nil] ? 0 : 1;
    }
}
