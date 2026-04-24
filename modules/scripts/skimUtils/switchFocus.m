#import "commonUtils.h"
#import "skimUtils.h"
#import <string.h>
#import <errno.h>

static NSString *const kSkimBundleID = @"net.sourceforge.skim-app.skim";
#define SHM_SIZE 1024

extern AXError _AXUIElementGetWindow(AXUIElementRef element, CGWindowID *id);

typedef struct {
    BOOL skimPresent;
    int  firstNonSkimWinID;
} WorkspaceInfo;

static void SFLog(NSString *fmt, ...) NS_FORMAT_FUNCTION(1,2);
static void SFLog(NSString *fmt, ...) {
    va_list args;
    va_start(args, fmt);
    NSString *msg = [[NSString alloc] initWithFormat:fmt arguments:args];
    va_end(args);

    NSString *line = [NSString stringWithFormat:@"%@ %@\n",
                      [NSDateFormatter localizedStringFromDate:[NSDate date]
                                                     dateStyle:NSDateFormatterNoStyle
                                                     timeStyle:NSDateFormatterMediumStyle],
                      msg];
    NSString *path = @"/tmp/switchFocus_debug.log";
    NSFileHandle *fh = [NSFileHandle fileHandleForWritingAtPath:path];
    if (!fh) {
        [@"" writeToFile:path atomically:NO encoding:NSUTF8StringEncoding error:nil];
        fh = [NSFileHandle fileHandleForWritingAtPath:path];
    }
    [fh seekToEndOfFile];
    [fh writeData:[line dataUsingEncoding:NSUTF8StringEncoding]];
    [fh closeFile];
}

static NSString *GetFocusedWorkspace(void) {
    return AerospaceOutput(@[@"list-workspaces", @"--focused"]);
}

static NSString *WorkspaceSHMName(NSString *workspace) {
    if (!workspace.length) return nil;
    NSCharacterSet *nonAlnum = [[NSCharacterSet alphanumericCharacterSet] invertedSet];
    NSString *safe = [[workspace componentsSeparatedByCharactersInSet:nonAlnum] componentsJoinedByString:@"_"];
    return [NSString stringWithFormat:@"/aerospace_skim_%@", safe];
}

static void SaveSkimWindowID(CGWindowID winID, NSString *workspace) {
    NSString *shmNameStr = WorkspaceSHMName(workspace);
    const char *shm_name = shmNameStr.UTF8String;

    SFLog(@"[DEBUG] SaveSkimWindowID: Attempting to save winID='%u' to workspace='%@' shm='%s'", winID, workspace, shm_name ?: "NULL");

    if (!shm_name) {
        SFLog(@"[ERROR] SaveSkimWindowID: Generated SHM name is NULL.");
        return;
    }

    int fd = shm_open(shm_name, O_CREAT | O_RDWR, 0666);
    if (fd == -1) {
        SFLog(@"[ERROR] SaveSkimWindowID: shm_open failed. errno=%d (%s)", errno, strerror(errno));
        return;
    }

    // if (ftruncate(fd, SHM_SIZE) == -1) {
    //     SFLog(@"[ERROR] SaveSkimWindowID: ftruncate failed. errno=%d (%s)", errno, strerror(errno));
    // }

    char *mem = mmap(NULL, SHM_SIZE, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
    if (mem != MAP_FAILED) {
        snprintf(mem, SHM_SIZE, "%u", winID);
        SFLog(@"[SUCCESS] SaveSkimWindowID: Wrote ID '%s' to SHM.", mem);
        munmap(mem, SHM_SIZE);
    } else {
        SFLog(@"[ERROR] SaveSkimWindowID: mmap failed. errno=%d (%s)", errno, strerror(errno));
    }
    close(fd);
}

static CGWindowID LoadSkimWindowID(NSString *workspace) {
    NSString *shmNameStr = WorkspaceSHMName(workspace);
    const char *shm_name = shmNameStr.UTF8String;

    SFLog(@"[DEBUG] LoadSkimWindowID: Fetching from workspace='%@' shm='%s'", workspace, shm_name ?: "NULL");

    if (!shm_name) return 0;

    int fd = shm_open(shm_name, O_RDONLY, 0666);
    if (fd == -1) {
        SFLog(@"[INFO] LoadSkimWindowID: shm_open failed. errno=%d (%s). Normal if unset.", errno, strerror(errno));
        return 0;
    }

    char *mem = mmap(NULL, SHM_SIZE, PROT_READ, MAP_SHARED, fd, 0);
    CGWindowID resultID = 0;

    if (mem != MAP_FAILED) {
        resultID = (CGWindowID)strtoul(mem, NULL, 10);
        SFLog(@"[SUCCESS] LoadSkimWindowID: Retrieved Window ID = '%u'", resultID);
        munmap(mem, SHM_SIZE);
    } else {
        SFLog(@"[ERROR] LoadSkimWindowID: mmap failed. errno=%d (%s)", errno, strerror(errno));
    }
    close(fd);
    return resultID;
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

static void FocusSkimWindow(NSRunningApplication *skim, CGWindowID savedWinID) {
    SFLog(@"[DEBUG] FocusSkimWindow: Attempting to focus Skim window ID: '%u'", savedWinID);
    [skim activateWithOptions:NSApplicationActivateAllWindows];

    CFArrayRef wins = CopyAXWindows(skim.processIdentifier);
    if (!wins) {
        SFLog(@"[ERROR] FocusSkimWindow: Failed to copy AX windows for Skim.");
        return;
    }

    CFIndex count = CFArrayGetCount(wins);
    if (count == 0) {
        SFLog(@"[DEBUG] FocusSkimWindow: Skim has no valid AX windows.");
        CFRelease(wins);
        return;
    }

    if (count == 1) {
        SFLog(@"[DEBUG] FocusSkimWindow: Only 1 window found. Raising fallback.");
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

        if (savedWinID > 0) {
            CGWindowID currentWinID = 0;
            if (_AXUIElementGetWindow(win, &currentWinID) == kAXErrorSuccess) {
                if (currentWinID == savedWinID) {
                    SFLog(@"[SUCCESS] FocusSkimWindow: Found exact match for Window ID %u. Raising window.", savedWinID);
                    AXUIElementPerformAction(win, kAXRaiseAction);
                    raised = YES;
                }
            }
        }
    }

    if (!raised && fallback) {
        SFLog(@"[INFO] FocusSkimWindow: Exact match not found. Raising top non-minimized fallback window.");
        AXUIElementPerformAction(fallback, kAXRaiseAction);
    }
    CFRelease(wins);
}

int switchFocus(NSString *direction) {
    NSRunningApplication *front = [NSWorkspace sharedWorkspace].frontmostApplication;
    BOOL isSkim = [front.bundleIdentifier isEqualToString:kSkimBundleID];

    SFLog(@"========== switchFocus direction='%@' frontApp='%@' isSkim=%d ==========", direction, front.bundleIdentifier, isSkim);

    if (isSkim && [direction isEqualToString:@"down"]) return 0;
    if (!isSkim && ![direction isEqualToString:@"down"] && ![direction isEqualToString:@"up"]) return AerospaceRun(@[@"focus", direction]);

    WorkspaceInfo info = GetWorkspaceInfo();

    if (!isSkim && [direction isEqualToString:@"down"] && info.skimPresent) {
        NSRunningApplication *skim = [NSRunningApplication runningApplicationsWithBundleIdentifier:kSkimBundleID].firstObject;
        if (skim) {
            NSString *workspace = GetFocusedWorkspace();
            CGWindowID savedWinID = LoadSkimWindowID(workspace);

            SFLog(@"[DEBUG] Non-Skim + down: target workspace='%@' savedWinID='%u'", workspace, savedWinID);

            FocusSkimWindow(skim, savedWinID);
            return 0;
        }
    }

    if (isSkim && [direction isEqualToString:@"up"] && info.firstNonSkimWinID != -1) {
        AXUIElementRef focused = GetFocusedWindowForPID(front.processIdentifier);
        if (focused) {
            CGWindowID winID = 0;
            if (_AXUIElementGetWindow(focused, &winID) == kAXErrorSuccess) {
                SaveSkimWindowID(winID, GetFocusedWorkspace());
            } else {
                SFLog(@"[ERROR] Skim + up: Could not extract CGWindowID from active Skim window.");
            }
            CFRelease(focused);
        }
        SFLog(@"[DEBUG] Skim + up: Refocusing aerospace to first non-skim window ID=%d", info.firstNonSkimWinID);
        return AerospaceRun(@[@"focus", @"--window-id", [NSString stringWithFormat:@"%d", info.firstNonSkimWinID]]);
    }

    return AerospaceRun(@[@"focus", direction]);
}
