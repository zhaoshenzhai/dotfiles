#import "commonUtils.h"
#import "skimUtils.h"

static NSString *const kSkimBundleID = @"net.sourceforge.skim-app.skim";
#define SHM_SIZE 1024

typedef struct {
    BOOL skimPresent;
    int  firstNonSkimWinID;
} WorkspaceInfo;

static NSString *GetFocusedWorkspace(void) {
    return AerospaceOutput(@[@"list-workspaces", @"--focused"]);
}

static const char *WorkspaceSHMName(NSString *workspace) {
    if (!workspace.length) return NULL;
    NSCharacterSet *nonAlnum = [[NSCharacterSet alphanumericCharacterSet] invertedSet];
    NSString *safe = [[workspace componentsSeparatedByCharactersInSet:nonAlnum] componentsJoinedByString:@"_"];
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
    __block WorkspaceInfo info = { NO, -1 };
    NSString *raw = AerospaceOutput(@[@"list-windows", @"--workspace", @"focused", @"--format", @"%{app-bundle-id}|%{window-id}"]);
    if (!raw.length) return info;

    [raw enumerateLinesUsingBlock:^(NSString *line, BOOL *stop) {
        NSArray<NSString *> *parts = [line componentsSeparatedByString:@"|"];
        if (parts.count < 2) return;

        if ([parts[0] isEqualToString:kSkimBundleID]) {
            info.skimPresent = YES;
        } else if (info.firstNonSkimWinID == -1) {
            info.firstNonSkimWinID = parts[1].intValue;
        }

        if (info.skimPresent && info.firstNonSkimWinID != -1) *stop = YES;
    }];

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
    if (!isSkim && ![direction isEqualToString:@"down"] && ![direction isEqualToString:@"up"]) return AerospaceRun(@[@"focus", direction]);

    WorkspaceInfo info = GetWorkspaceInfo();

    if (!isSkim && [direction isEqualToString:@"down"] && info.skimPresent) {
        NSRunningApplication *skim = [NSRunningApplication runningApplicationsWithBundleIdentifier:kSkimBundleID].firstObject;
        if (skim) {
            FocusSkimWindow(skim, LoadSkimTitle(GetFocusedWorkspace()));
            return 0;
        }
    }

    if (isSkim && [direction isEqualToString:@"up"] && info.firstNonSkimWinID != -1) {
        AXUIElementRef focused = GetFocusedWindowForPID(front.processIdentifier);
        if (focused) {
            SaveSkimTitle(AXWindowTitle(focused) ?: @"", GetFocusedWorkspace());
            CFRelease(focused);
        }
        return AerospaceRun(@[@"focus", @"--window-id", [NSString stringWithFormat:@"%d", info.firstNonSkimWinID]]);
    }

    return AerospaceRun(@[@"focus", direction]);
}
