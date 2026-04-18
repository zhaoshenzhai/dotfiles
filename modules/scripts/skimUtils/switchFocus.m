#import "skimUtils.h"

// ─────────────────────────────────────────────────────────────────────────────
// Constants
// ─────────────────────────────────────────────────────────────────────────────

static NSString *const kSkimBundleID = @"net.sourceforge.skim-app.skim";
static NSString *const kMemoryDir    = @"/tmp/aerospace_skim_tabs";

// ─────────────────────────────────────────────────────────────────────────────
// Aerospace helpers
// ─────────────────────────────────────────────────────────────────────────────

static NSString *AerospaceOutput(NSArray<NSString *> *args) {
    NSTask *task    = [[NSTask alloc] init];
    task.launchPath = @"/usr/bin/env";
    task.arguments  = [@[@"aerospace"] arrayByAddingObjectsFromArray:args];

    NSPipe *pipe        = [NSPipe pipe];
    task.standardOutput = pipe;
    task.standardError  = [NSFileHandle fileHandleWithNullDevice];

    NSError *err = nil;
    if (![task launchAndReturnError:&err]) return @"";
    [task waitUntilExit];

    NSData *data = [pipe.fileHandleForReading readDataToEndOfFile];
    NSString *out = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    return out ? [out stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] : @"";
}

static int AerospaceRun(NSArray<NSString *> *args) {
    NSTask *task    = [[NSTask alloc] init];
    task.launchPath = @"/usr/bin/env";
    task.arguments  = [@[@"aerospace"] arrayByAddingObjectsFromArray:args];
    task.standardOutput = [NSFileHandle fileHandleWithNullDevice];
    task.standardError  = [NSFileHandle fileHandleWithNullDevice];

    NSError *err = nil;
    if ([task launchAndReturnError:&err]) [task waitUntilExit];
    return 0;
}

// ─────────────────────────────────────────────────────────────────────────────
// Workspace info
// ─────────────────────────────────────────────────────────────────────────────

typedef struct {
    NSInteger alacrittyCount;
    pid_t     alacrittyPID;
    int       alacrittyWinID;
    NSInteger skimCount;
} WorkspaceInfo;

static WorkspaceInfo GetWorkspaceInfo(void) {
    WorkspaceInfo info = { 0, 0, 0, 0 };

    NSString *raw = AerospaceOutput(@[@"list-windows", @"--workspace", @"focused",
                                      @"--format", @"%{app-name}|%{app-bundle-id}|%{app-pid}|%{window-id}"]);
    if (!raw.length) return info;

    NSArray<NSString *> *lines = [raw componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];

    for (NSString *line in lines) {
        if (!line.length) continue;

        NSArray<NSString *> *p = [line componentsSeparatedByString:@"|"];
        if (p.count < 4) continue;

        // Case-insensitive prefix check avoids allocating a new lowercase string
        if ([p[0] rangeOfString:@"alacritty" options:NSCaseInsensitiveSearch|NSAnchoredSearch].location != NSNotFound) {
            info.alacrittyCount++;
            if (info.alacrittyCount == 1) {
                info.alacrittyPID = [p[2] intValue];
                info.alacrittyWinID = [p[3] intValue];
            }
        } else if ([p[1] isEqualToString:kSkimBundleID]) {
            info.skimCount++;
        }
    }
    return info;
}

// ─────────────────────────────────────────────────────────────────────────────
// AX & Memory helpers
// ─────────────────────────────────────────────────────────────────────────────

static CFArrayRef CopyAXWindows(pid_t pid) {
    AXUIElementRef appElem = AXUIElementCreateApplication(pid);
    CFTypeRef val          = NULL;
    CFArrayRef result      = NULL;

    if (AXUIElementCopyAttributeValue(appElem, kAXWindowsAttribute, &val) == kAXErrorSuccess) {
        result = (CFArrayRef)CFRetain(val);
        CFRelease(val);
    }
    CFRelease(appElem);
    return result;
}

static NSString *AXWindowTitle(AXUIElementRef win) {
    CFTypeRef val = NULL;
    if (AXUIElementCopyAttributeValue(win, kAXTitleAttribute, &val) != kAXErrorSuccess) return nil;
    NSString *title = [(__bridge NSString *)val copy];
    CFRelease(val);
    return title;
}

static NSString *MemoryFilePath(pid_t alacrittyPID) {
    return [NSString stringWithFormat:@"%@/skim_%d.txt", kMemoryDir, alacrittyPID];
}

static void SaveSkimTitle(NSString *title, pid_t alacrittyPID) {
    if (!title.length) return;
    [[NSFileManager defaultManager] createDirectoryAtPath:kMemoryDir
                              withIntermediateDirectories:YES attributes:nil error:nil];
    [title writeToFile:MemoryFilePath(alacrittyPID) atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

static NSString *LoadSkimTitle(pid_t alacrittyPID) {
    NSString *raw = [NSString stringWithContentsOfFile:MemoryFilePath(alacrittyPID) encoding:NSUTF8StringEncoding error:nil];
    return [raw stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

// ─────────────────────────────────────────────────────────────────────────────
// Focus execution
// ─────────────────────────────────────────────────────────────────────────────

static void FocusSkimWindow(NSRunningApplication *skim, NSString *savedTitle) {
    CFArrayRef wins = CopyAXWindows(skim.processIdentifier);
    if (!wins) { [skim activateWithOptions:0]; return; }

    CFIndex count = CFArrayGetCount(wins);

    // Quick exit: If Skim only has 0 or 1 window, no need to iterate or match titles.
    if (count <= 1) {
        [skim activateWithOptions:0];
        CFRelease(wins);
        return;
    }

    AXUIElementRef target   = NULL;
    AXUIElementRef fallback = NULL;

    for (CFIndex i = 0; i < count; i++) {
        AXUIElementRef win = (AXUIElementRef)CFArrayGetValueAtIndex(wins, i);

        CFTypeRef minimisedVal = NULL;
        BOOL isMin = NO;
        if (AXUIElementCopyAttributeValue(win, kAXMinimizedAttribute, &minimisedVal) == kAXErrorSuccess) {
            isMin = [(__bridge NSNumber *)minimisedVal boolValue];
            CFRelease(minimisedVal);
        }
        if (isMin) continue;

        if (!fallback) fallback = win;

        if (savedTitle.length) {
            NSString *t = AXWindowTitle(win);
            if (t && [t isEqualToString:savedTitle]) { target = win; break; }
        }
    }

    AXUIElementRef chosen = target ?: fallback;
    if (chosen) {
        AXUIElementPerformAction(chosen, kAXRaiseAction);
        [skim activateWithOptions:0];
    } else {
        [skim activateWithOptions:0];
    }

    CFRelease(wins);
}

// ─────────────────────────────────────────────────────────────────────────────
// Main switchFocus Routing
// ─────────────────────────────────────────────────────────────────────────────

int switchFocus(NSString *direction) {
    NSRunningApplication *front = [NSWorkspace sharedWorkspace].frontmostApplication;
    BOOL isAlacritty = [front.localizedName.lowercaseString hasPrefix:@"alacritty"];
    BOOL isSkim      = [front.bundleIdentifier isEqualToString:kSkimBundleID];

    if (!isAlacritty && !isSkim) return AerospaceRun(@[@"focus", direction]);

    WorkspaceInfo info = GetWorkspaceInfo();

    // Condition 1: Alacritty -> Skim (Downwards)
    if (isAlacritty && [direction isEqualToString:@"down"] && info.alacrittyCount == 1 && info.skimCount > 0) {
        NSRunningApplication *skim = [NSRunningApplication runningApplicationsWithBundleIdentifier:kSkimBundleID].firstObject;
        if (skim) {
            FocusSkimWindow(skim, LoadSkimTitle(front.processIdentifier));
            return 0;
        }
    }

    // Condition 2: Skim -> Alacritty (Upwards)
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

    // Fallback: Normal Aerospace Tiling
    // Handles multi-Alacritty workspaces, up from Alacritty, down from Skim, etc.
    return AerospaceRun(@[@"focus", direction]);
}
