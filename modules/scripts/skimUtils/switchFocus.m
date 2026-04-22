#import "commonUtils.h"
#import "skimUtils.h"

static NSString *const kSkimBundleID = @"net.sourceforge.skim-app.skim";
#define SHM_SIZE 1024

typedef struct {
    NSInteger alacrittyCount;
    pid_t     alacrittyPID;
    int       alacrittyWinID;
    NSInteger skimCount;
} WorkspaceInfo;

static void SaveSkimTitle(NSString *title, pid_t alacrittyPID) {
    if (!title.length) return;
    char shm_name[64];
    snprintf(shm_name, sizeof(shm_name), "/aerospace_skim_%d", alacrittyPID);

    int fd = shm_open(shm_name, O_CREAT | O_RDWR | O_TRUNC, 0666);
    if (fd == -1) return;

    ftruncate(fd, SHM_SIZE);
    char *mem = mmap(NULL, SHM_SIZE, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);

    if (mem != MAP_FAILED) {
        strncpy(mem, title.UTF8String, SHM_SIZE - 1);
        mem[SHM_SIZE - 1] = '\0';
        munmap(mem, SHM_SIZE);
    }
    close(fd);
}

static NSString *LoadSkimTitle(pid_t alacrittyPID) {
    char shm_name[64];
    snprintf(shm_name, sizeof(shm_name), "/aerospace_skim_%d", alacrittyPID);

    int fd = shm_open(shm_name, O_RDONLY, 0666);
    if (fd == -1) return @"";

    char *mem = mmap(NULL, SHM_SIZE, PROT_READ, MAP_SHARED, fd, 0);
    NSString *result = @"";

    if (mem != MAP_FAILED) {
        result = [NSString stringWithUTF8String:mem];
        munmap(mem, SHM_SIZE);
    }

    close(fd);
    shm_unlink(shm_name);
    return [result stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

static WorkspaceInfo GetWorkspaceInfo(void) {
    WorkspaceInfo info = { 0, 0, 0, 0 };
    NSString *raw = AerospaceOutput(@[@"list-windows", @"--workspace", @"focused",
                                      @"--format", @"%{app-name}|%{app-bundle-id}|%{app-pid}|%{window-id}"]);
    if (!raw.length) return info;

    char *rawInfo = strdup(raw.UTF8String);
    if (!rawInfo) return info;

    char *lineSavePtr = NULL;
    char *tokenSavePtr = NULL;

    char *line = strtok_r(rawInfo, "\n", &lineSavePtr);
    while (line != NULL) {
        char *appName   = strtok_r(line, "|", &tokenSavePtr);
        char *bundleID  = strtok_r(NULL, "|", &tokenSavePtr);
        char *appPIDStr = strtok_r(NULL, "|", &tokenSavePtr);
        char *winIDStr  = strtok_r(NULL, "|", &tokenSavePtr);

        if (appName && bundleID && appPIDStr && winIDStr) {
            if (strcasestr(appName, "alacritty")) {
                info.alacrittyCount++;
                if (info.alacrittyCount == 1) {
                    info.alacrittyPID = atoi(appPIDStr);
                    info.alacrittyWinID = atoi(winIDStr);
                }
            } else if (strcmp(bundleID, "net.sourceforge.skim-app.skim") == 0) {
                info.skimCount++;
            }
        }

        line = strtok_r(NULL, "\n", &lineSavePtr);
    }

    free(rawInfo);
    return info;
}

static void FocusSkimWindow(NSRunningApplication *skim, NSString *savedTitle) {
    [skim activateWithOptions:NSApplicationActivateAllWindows];

    if (!savedTitle || savedTitle.length == 0) return;

    CFArrayRef wins = CopyAXWindows(skim.processIdentifier);
    if (!wins) return;

    CFIndex count = CFArrayGetCount(wins);
    if (count <= 1) {
        CFRelease(wins);
        return;
    }

    for (CFIndex i = 0; i < count; i++) {
        AXUIElementRef win = (AXUIElementRef)CFArrayGetValueAtIndex(wins, i);
        NSString *t = AXWindowTitle(win);

        if (t && [t isEqualToString:savedTitle]) {
            CFTypeRef minimisedVal = NULL;
            BOOL isMin = NO;
            if (AXUIElementCopyAttributeValue(win, kAXMinimizedAttribute, &minimisedVal) == kAXErrorSuccess) {
                isMin = [(__bridge NSNumber *)minimisedVal boolValue];
                if (minimisedVal) CFRelease(minimisedVal);
            }

            if (!isMin) {
                AXUIElementPerformAction(win, kAXRaiseAction);
                break;
            }
        }
    }

    CFRelease(wins);
}

int switchFocus(NSString *direction) {
    NSRunningApplication *front = [NSWorkspace sharedWorkspace].frontmostApplication;
    BOOL isAlacritty = [front.localizedName.lowercaseString hasPrefix:@"alacritty"];
    BOOL isSkim      = [front.bundleIdentifier isEqualToString:kSkimBundleID];

    if (!isAlacritty && !isSkim) return AerospaceRun(@[@"focus", direction]);

    WorkspaceInfo info = GetWorkspaceInfo();

    if (isAlacritty && [direction isEqualToString:@"down"] && info.alacrittyCount == 1 && info.skimCount > 0) {
        NSRunningApplication *skim = [NSRunningApplication runningApplicationsWithBundleIdentifier:kSkimBundleID].firstObject;
        if (skim) {
            FocusSkimWindow(skim, LoadSkimTitle(front.processIdentifier));
            return 0;
        }
    }

    if (isSkim && [direction isEqualToString:@"up"] && info.alacrittyCount == 1 && info.alacrittyWinID > 0) {
        AXUIElementRef focusedWin = GetFocusedWindowForPID(front.processIdentifier);
        if (focusedWin) {
            NSString *title = AXWindowTitle(focusedWin);
            if (title) SaveSkimTitle(title, info.alacrittyPID);
            CFRelease(focusedWin);
        }

        NSString *winIDStr = [NSString stringWithFormat:@"%d", info.alacrittyWinID];
        return AerospaceRun(@[@"focus", @"--window-id", winIDStr]);
    }

    return AerospaceRun(@[@"focus", direction]);
}
