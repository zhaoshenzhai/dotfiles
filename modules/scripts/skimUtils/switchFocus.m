#import "skimUtils.h"

// ─────────────────────────────────────────────────────────────────────────────
// Constants
// ─────────────────────────────────────────────────────────────────────────────

static NSString *const kSkimBundleID = @"net.sourceforge.skim-app.skim";
static NSString *const kMemoryDir    = @"/tmp/aerospace_skim_tabs";

// ─────────────────────────────────────────────────────────────────────────────
// Aerospace helpers
//
// AerospaceOutput – captures stdout, used for workspace queries.
// AerospaceRun    – discards stdout, used for focus commands.
// Both are called at most once per keypress.
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
    return out ? [out stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]
               : @"";
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
//
// ONE aerospace call scoped to the focused workspace gives us window counts
// and titles for all three issues:
//   • alacrittyCount > 1  → don't intercept, let aerospace do normal tiling
//   • alacrittyTitles[0]  → used to match the right AX window in the workspace
//   • skimCount           → decide whether to intercept the Alacritty→Skim jump
// ─────────────────────────────────────────────────────────────────────────────

typedef struct {
    NSInteger               alacrittyCount;
    NSMutableArray<NSString *> *alacrittyTitles;  // AX window titles, for matching
    NSInteger               skimCount;
} WorkspaceInfo;

static WorkspaceInfo GetWorkspaceInfo(void) {
    WorkspaceInfo info = { 0, [NSMutableArray array], 0 };

    NSString *raw = AerospaceOutput(@[@"list-windows", @"--workspace", @"focused",
                                      @"--format", @"%{app-name}|%{window-title}|%{app-bundle-id}"]);
    if (!raw.length) return info;

    NSCharacterSet *ws = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    for (NSString *line in [raw componentsSeparatedByString:@"\n"]) {
        NSString *trimmed = [line stringByTrimmingCharactersInSet:ws];
        if (!trimmed.length) continue;

        NSArray<NSString *> *p = [trimmed componentsSeparatedByString:@"|"];
        if (p.count < 3) continue;

        NSString *appName  = p[0].lowercaseString;
        NSString *title    = p[1];
        NSString *bundleID = p[2];

        if ([appName hasPrefix:@"alacritty"]) {
            info.alacrittyCount++;
            [info.alacrittyTitles addObject:title];
        } else if ([bundleID isEqualToString:kSkimBundleID]) {
            info.skimCount++;
        }
    }
    return info;
}

// ─────────────────────────────────────────────────────────────────────────────
// AX helpers
// ─────────────────────────────────────────────────────────────────────────────

/// Returns +1-retained CFArray of AXUIElementRef windows for pid, or NULL.
/// Caller must CFRelease.
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

/// Returns the kAXTitleAttribute of win, or nil.
static NSString *AXWindowTitle(AXUIElementRef win) {
    CFTypeRef val = NULL;
    if (AXUIElementCopyAttributeValue(win, kAXTitleAttribute, &val) != kAXErrorSuccess)
        return nil;
    NSString *title = [(__bridge NSString *)val copy];
    CFRelease(val);
    return title;
}

/// Raises win to front within its process, then activates app.
static void RaiseAndActivate(AXUIElementRef win, NSRunningApplication *app) {
    AXUIElementPerformAction(win, kAXRaiseAction);
    [app activateWithOptions:0];
}

// ─────────────────────────────────────────────────────────────────────────────
// Memory helpers
//
// Keyed by Alacritty PID (unique per session ≈ per workspace).
// Stores the AX window title of the last-focused Skim tab.
// ─────────────────────────────────────────────────────────────────────────────

static NSString *MemoryFilePath(pid_t alacrittyPID) {
    return [NSString stringWithFormat:@"%@/skim_%d.txt", kMemoryDir, alacrittyPID];
}

static void SaveSkimTitle(NSString *title, pid_t alacrittyPID) {
    if (!title.length) return;
    [[NSFileManager defaultManager] createDirectoryAtPath:kMemoryDir
                              withIntermediateDirectories:YES
                                             attributes:nil
                                                  error:nil];
    [title writeToFile:MemoryFilePath(alacrittyPID)
            atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

static NSString *LoadSkimTitle(pid_t alacrittyPID) {
    NSString *raw = [NSString stringWithContentsOfFile:MemoryFilePath(alacrittyPID)
                                              encoding:NSUTF8StringEncoding
                                                 error:nil];
    return [raw stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

// ─────────────────────────────────────────────────────────────────────────────
// App lookup helpers
// ─────────────────────────────────────────────────────────────────────────────

static NSRunningApplication *FindAlacritty(void) {
    for (NSRunningApplication *app in [NSWorkspace sharedWorkspace].runningApplications)
        if ([app.localizedName.lowercaseString hasPrefix:@"alacritty"])
            return app;
    return nil;
}

static NSRunningApplication *FindSkim(void) {
    return [NSRunningApplication
            runningApplicationsWithBundleIdentifier:kSkimBundleID].firstObject;
}

// ─────────────────────────────────────────────────────────────────────────────
// Focus helpers
// ─────────────────────────────────────────────────────────────────────────────

/// Focus the Skim window whose AX title matches savedTitle.
/// Falls back to the first non-minimised window.
static void FocusSkimWindow(NSRunningApplication *skim, NSString *savedTitle) {
    CFArrayRef wins = CopyAXWindows(skim.processIdentifier);
    if (!wins) { [skim activateWithOptions:0]; return; }

    CFIndex        count    = CFArrayGetCount(wins);
    AXUIElementRef target   = NULL;
    AXUIElementRef fallback = NULL;

    for (CFIndex i = 0; i < count; i++) {
        AXUIElementRef win = (AXUIElementRef)CFArrayGetValueAtIndex(wins, i);

        CFTypeRef minimisedVal = NULL;
        if (AXUIElementCopyAttributeValue(win, kAXMinimizedAttribute, &minimisedVal) == kAXErrorSuccess) {
            BOOL isMin = [(__bridge NSNumber *)minimisedVal boolValue];
            CFRelease(minimisedVal);
            if (isMin) continue;
        }

        if (!fallback) fallback = win;

        if (savedTitle.length) {
            NSString *t = AXWindowTitle(win);
            if (t && [t isEqualToString:savedTitle]) { target = win; break; }
        }
    }

    AXUIElementRef chosen = target ?: fallback;
    if (chosen) RaiseAndActivate(chosen, skim);
    else        [skim activateWithOptions:0];

    CFRelease(wins);
}

/// Focus the Alacritty window whose AX title matches workspaceTitle.
/// workspaceTitle comes from GetWorkspaceInfo and pins us to the correct
/// workspace window, even if Alacritty has windows in other workspaces.
/// Falls back to the first window if no title match.
static void FocusAlacrittyWindow(NSRunningApplication *alacritty, NSString *workspaceTitle) {
    CFArrayRef wins = CopyAXWindows(alacritty.processIdentifier);
    if (!wins) { [alacritty activateWithOptions:0]; return; }

    CFIndex        count    = CFArrayGetCount(wins);
    AXUIElementRef target   = NULL;
    AXUIElementRef fallback = NULL;

    for (CFIndex i = 0; i < count; i++) {
        AXUIElementRef win = (AXUIElementRef)CFArrayGetValueAtIndex(wins, i);
        if (!fallback) fallback = win;

        if (workspaceTitle.length) {
            NSString *t = AXWindowTitle(win);
            if (t && [t isEqualToString:workspaceTitle]) { target = win; break; }
        }
    }

    AXUIElementRef chosen = target ?: fallback;
    if (chosen) RaiseAndActivate(chosen, alacritty);
    else        [alacritty activateWithOptions:0];

    CFRelease(wins);
}

// ─────────────────────────────────────────────────────────────────────────────
// switchFocus
// ─────────────────────────────────────────────────────────────────────────────

int switchFocus(NSString *direction) {
    NSRunningApplication *front = [NSWorkspace sharedWorkspace].frontmostApplication;

    BOOL isAlacritty = [front.localizedName.lowercaseString hasPrefix:@"alacritty"];
    BOOL isSkim      = [front.bundleIdentifier isEqualToString:kSkimBundleID];

    // Not one of our managed apps → normal aerospace tiling, no workspace query needed
    if (!isAlacritty && !isSkim) return AerospaceRun(@[@"focus", direction]);

    // ── Query the focused workspace (1 aerospace call) ────────────────────────
    // Only reached when Alacritty or Skim is focused.
    WorkspaceInfo info = GetWorkspaceInfo();

    // ── Alacritty is focused ──────────────────────────────────────────────────
    if (isAlacritty) {
        // More than one Alacritty in this workspace: let aerospace traverse them
        // normally. The user will reach the bottom-most one after enough presses,
        // and that press will also fall here — but by then alacrittyCount is still
        // >1, so aerospace will naturally land on the adjacent Skim window.
        // (Issue 1 fix)
        if (info.alacrittyCount != 1) return AerospaceRun(@[@"focus", direction]);

        // Going up from the only Alacritty: nothing above in our scheme
        if ([direction isEqualToString:@"up"]) return AerospaceRun(@[@"focus", direction]);

        // direction == "down": no Skim in this workspace → normal tiling
        if (info.skimCount < 1) return AerospaceRun(@[@"focus", direction]);

        // direction == "down" + exactly 1 Alacritty + Skim present → jump to Skim
        NSRunningApplication *skim = FindSkim();
        if (!skim) return AerospaceRun(@[@"focus", direction]);

        CFArrayRef skimWins  = CopyAXWindows(skim.processIdentifier);
        CFIndex    skimCount = skimWins ? CFArrayGetCount(skimWins) : 0;
        if (skimWins) CFRelease(skimWins);

        if (skimCount <= 1) {
            [skim activateWithOptions:0];
        } else {
            NSString *savedTitle = LoadSkimTitle(front.processIdentifier);
            FocusSkimWindow(skim, savedTitle);
        }
        return 0;
    }

    // ── Skim is focused ───────────────────────────────────────────────────────
    if (isSkim) {
        // Going down from Skim → normal aerospace tiling
        if ([direction isEqualToString:@"down"]) return AerospaceRun(@[@"focus", direction]);

        // No Alacritty in this workspace → normal tiling
        // Also covers the >1 case: if multiple Alacritty windows exist,
        // aerospace will land on the adjacent (bottom) one. (Issue 2 + 3 fix)
        if (info.alacrittyCount != 1) return AerospaceRun(@[@"focus", direction]);

        // direction == "up" + exactly 1 Alacritty in workspace → jump to it
        NSRunningApplication *alacritty = FindAlacritty();
        if (!alacritty) return AerospaceRun(@[@"focus", direction]);

        // Persist the title of the Skim window we're leaving
        AXUIElementRef focusedWin = GetFocusedWindowForPID(front.processIdentifier);
        if (focusedWin) {
            NSString *title = AXWindowTitle(focusedWin);
            if (title) SaveSkimTitle(title, alacritty.processIdentifier);
            CFRelease(focusedWin);
        }

        // Use the workspace title to target the correct Alacritty AX window,
        // avoiding windows from other workspaces. (Issue 3 fix)
        NSString *workspaceAlacrittyTitle = info.alacrittyTitles.firstObject;
        FocusAlacrittyWindow(alacritty, workspaceAlacrittyTitle);
        return 0;
    }

    return 0;
}

// ─────────────────────────────────────────────────────────────────────────────
// recordSkim
//
// Called by aerospace's on-window-detected hook. The aerospace window-id is
// ignored; we ask AX which Skim window is currently frontmost and record it.
// ─────────────────────────────────────────────────────────────────────────────

int recordSkim() {
    NSRunningApplication *skim      = FindSkim();
    NSRunningApplication *alacritty = FindAlacritty();
    if (!skim || !alacritty) return 1;

    AXUIElementRef focusedWin = GetFocusedWindowForPID(skim.processIdentifier);
    if (!focusedWin) return 1;

    NSString *title = AXWindowTitle(focusedWin);
    CFRelease(focusedWin);

    if (title) SaveSkimTitle(title, alacritty.processIdentifier);
    return 0;
}
