#import "commonUtils.h"
#import "skimUtils.h"

static NSString *const kSkimBundleID = @"net.sourceforge.skim-app.skim";
#define SHM_SIZE 1024

typedef struct {
    BOOL  skimPresent;
    int   firstNonSkimWinID;
} WorkspaceInfo;

static NSString *GetFocusedWorkspace(void) {
    NSString *ws = AerospaceOutput(@[@"list-workspaces", @"--focused"]);
    return [ws stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

static const char *WorkspaceSHMName(NSString *workspace) {
    if (!workspace.length) return NULL;
    NSMutableString *safe = [workspace mutableCopy];
    NSCharacterSet *allowed = [NSCharacterSet alphanumericCharacterSet];
    for (NSUInteger i = 0; i < safe.length; i++) {
        if (![allowed characterIsMember:[safe characterAtIndex:i]])
            [safe replaceCharactersInRange:NSMakeRange(i, 1) withString:@"_"];
    }
    return [NSString stringWithFormat:@"/aerospace_skim_%@", safe].UTF8String;
}

static void SaveSkimTitle(NSString *title, NSString *workspace) {
    const char *shm_name = WorkspaceSHMName(workspace);
    if (!shm_name) return;
    int fd = shm_open(shm_name, O_CREAT | O_RDWR | O_TRUNC, 0666);
    if (fd == -1) return;
    ftruncate(fd, SHM_SIZE);
    char *mem = mmap(NULL, SHM_SIZE, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
    if (mem != MAP_FAILED) {
        const char *src = title.length ? title.UTF8String : "";
        strncpy(mem, src, SHM_SIZE - 1);
        mem[SHM_SIZE - 1] = '\0';
        munmap(mem, SHM_SIZE);
    }
    close(fd);
}

static NSString *LoadSkimTitle(NSString *workspace) {
    const char *shm_name = WorkspaceSHMName(workspace);
    if (!shm_name) return @"";
    int fd = shm_open(shm_name, O_RDONLY, 0666);
    if (fd == -1) return @"";
    char *mem = mmap(NULL, SHM_SIZE, PROT_READ, MAP_SHARED, fd, 0);
    NSString *result = @"";
    if (mem != MAP_FAILED) {
        result = [NSString stringWithUTF8String:mem] ?: @"";
        munmap(mem, SHM_SIZE);
    }
    close(fd);
    return [result stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

static WorkspaceInfo GetWorkspaceInfo(void) {
    WorkspaceInfo info = { NO, -1 };
    NSString *raw = AerospaceOutput(@[@"list-windows", @"--workspace", @"focused", @"--format", @"%{app-bundle-id}|%{window-id}"]);
    if (!raw.length) return info;

    char *rawInfo = strdup(raw.UTF8String);
    if (!rawInfo) return info;

    char *lineSavePtr  = NULL;
    char *tokenSavePtr = NULL;

    char *line = strtok_r(rawInfo, "\n", &lineSavePtr);
    while (line != NULL) {
        char *bundleID = strtok_r(line, "|", &tokenSavePtr);
        char *winIDStr = strtok_r(NULL, "|", &tokenSavePtr);

        if (bundleID && winIDStr) {
            if (strcmp(bundleID, "net.sourceforge.skim-app.skim") == 0) {
                info.skimPresent = YES;
            } else if (info.firstNonSkimWinID == -1) {
                info.firstNonSkimWinID = atoi(winIDStr);
            }
        }

        if (info.skimPresent && info.firstNonSkimWinID != -1) break;
        line = strtok_r(NULL, "\n", &lineSavePtr);
    }

    free(rawInfo);
    return info;
}

static void FocusSkimWindow(NSRunningApplication *skim, NSString *savedTitle) {
    [skim activateWithOptions:NSApplicationActivateAllWindows];

    CFArrayRef wins = CopyAXWindows(skim.processIdentifier);
    if (!wins) return;

    CFIndex count = CFArrayGetCount(wins);
    if (count == 0) { CFRelease(wins); return; }

    if (count == 1) {
        AXUIElementPerformAction((AXUIElementRef)CFArrayGetValueAtIndex(wins, 0), kAXRaiseAction);
        CFRelease(wins);
        return;
    }

    AXUIElementRef fallback = NULL;
    BOOL raised = NO;

    for (CFIndex i = 0; i < count && !raised; i++) {
        AXUIElementRef win = (AXUIElementRef)CFArrayGetValueAtIndex(wins, i);

        CFTypeRef minimisedVal = NULL;
        BOOL isMin = NO;
        if (AXUIElementCopyAttributeValue(win, kAXMinimizedAttribute, &minimisedVal) == kAXErrorSuccess) {
            isMin = [(__bridge NSNumber *)minimisedVal boolValue];
            if (minimisedVal) CFRelease(minimisedVal);
        }

        if (isMin) continue;
        if (!fallback) fallback = win;

        if (savedTitle.length) {
            NSString *t = AXWindowTitle(win);
            if (t && [t isEqualToString:savedTitle]) {
                AXUIElementPerformAction(win, kAXRaiseAction);
                raised = YES;
            }
        }
    }

    if (!raised && fallback) AXUIElementPerformAction(fallback, kAXRaiseAction);
    CFRelease(wins);
}

int switchFocus(NSString *direction) {
    NSRunningApplication *front = [NSWorkspace sharedWorkspace].frontmostApplication;
    BOOL isSkim = [front.bundleIdentifier isEqualToString:kSkimBundleID];

    if (isSkim && [direction isEqualToString:@"down"]) return 0;
    if (!isSkim && ![direction isEqualToString:@"down"] && ![direction isEqualToString:@"up"]) {
        return AerospaceRun(@[@"focus", direction]);
    }


    WorkspaceInfo info = GetWorkspaceInfo();

    if (!isSkim && [direction isEqualToString:@"down"] && info.skimPresent) {
        NSRunningApplication *skim =
            [NSRunningApplication runningApplicationsWithBundleIdentifier:kSkimBundleID].firstObject;
        if (skim) {
            NSString *workspace  = GetFocusedWorkspace();
            NSString *savedTitle = LoadSkimTitle(workspace);
            FocusSkimWindow(skim, savedTitle);
            return 0;
        }
    }

    if (isSkim && [direction isEqualToString:@"up"] && info.firstNonSkimWinID != -1) {
        NSString *workspace   = GetFocusedWorkspace();
        AXUIElementRef focused = GetFocusedWindowForPID(front.processIdentifier);
        if (focused) {
            NSString *title = AXWindowTitle(focused);
            SaveSkimTitle(title ?: @"", workspace);
            CFRelease(focused);
        }
        NSString *winIDStr = [NSString stringWithFormat:@"%d", info.firstNonSkimWinID];
        return AerospaceRun(@[@"focus", @"--window-id", winIDStr]);
    }

    return AerospaceRun(@[@"focus", direction]);
}
