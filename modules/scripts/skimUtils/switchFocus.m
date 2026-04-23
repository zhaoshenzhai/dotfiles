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

// ── Workspace helpers ────────────────────────────────────────────────────────

static NSString *GetFocusedWorkspace(void) {
    NSString *ws = AerospaceOutput(@[@"list-workspaces", @"--focused"]);
    return [ws stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

/// Returns a POSIX shared-memory name safe for the given workspace label.
static const char *WorkspaceSHMName(NSString *workspace) {
    if (!workspace.length) return NULL;

    NSMutableString *safe = [workspace mutableCopy];
    NSCharacterSet *allowed = [NSCharacterSet alphanumericCharacterSet];
    for (NSUInteger i = 0; i < safe.length; i++) {
        if (![allowed characterIsMember:[safe characterAtIndex:i]])
            [safe replaceCharactersInRange:NSMakeRange(i, 1) withString:@"_"];
    }

    // Returned pointer is valid for the lifetime of the autorelease pool.
    return [NSString stringWithFormat:@"/aerospace_skim_%@", safe].UTF8String;
}

// ── Shared-memory I/O ────────────────────────────────────────────────────────

/// Persist the Skim window title for this workspace.
/// Passing an empty string clears the slot (next load returns @"").
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
    // Do NOT unlink here – the slot must survive until explicitly overwritten.
}

/// Read (but do not destroy) the saved Skim window title for this workspace.
/// Returns @"" when nothing was saved or the SHM segment does not exist.
static NSString *LoadSkimTitle(NSString *workspace) {
    const char *shm_name = WorkspaceSHMName(workspace);
    if (!shm_name) return @"";

    int fd = shm_open(shm_name, O_RDONLY, 0666);
    if (fd == -1) return @"";  // Nothing saved yet – not an error.

    char *mem = mmap(NULL, SHM_SIZE, PROT_READ, MAP_SHARED, fd, 0);
    NSString *result = @"";
    if (mem != MAP_FAILED) {
        // Guard against a corrupt (non-UTF-8) segment.
        result = [NSString stringWithUTF8String:mem] ?: @"";
        munmap(mem, SHM_SIZE);
    }
    close(fd);
    // Do NOT unlink – we want the value to persist for the next focus cycle.
    return [result stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

// ── Workspace window inventory ───────────────────────────────────────────────

static WorkspaceInfo GetWorkspaceInfo(void) {
    WorkspaceInfo info = { 0, 0, 0, 0 };
    NSString *raw = AerospaceOutput(@[@"list-windows", @"--workspace", @"focused",
                                      @"--format", @"%{app-name}|%{app-bundle-id}|%{app-pid}|%{window-id}"]);
    if (!raw.length) return info;

    char *rawInfo = strdup(raw.UTF8String);
    if (!rawInfo) return info;

    char *lineSavePtr  = NULL;
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
                    info.alacrittyPID   = atoi(appPIDStr);
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

// ── Skim focus logic ─────────────────────────────────────────────────────────

/// Focus the best available Skim window:
///   1. The window whose title matches `savedTitle` (if non-empty and present).
///   2. Otherwise the first non-minimised window (fallback for closed/renamed tabs).
static void FocusSkimWindow(NSRunningApplication *skim, NSString *savedTitle) {
    [skim activateWithOptions:NSApplicationActivateAllWindows];

    CFArrayRef wins = CopyAXWindows(skim.processIdentifier);
    if (!wins) return;

    CFIndex count = CFArrayGetCount(wins);
    if (count == 0) { CFRelease(wins); return; }

    // Single window: just raise it and we're done.
    if (count == 1) {
        AXUIElementPerformAction((AXUIElementRef)CFArrayGetValueAtIndex(wins, 0), kAXRaiseAction);
        CFRelease(wins);
        return;
    }

    // Multiple windows: prefer the saved title; keep a fallback pointer.
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

        // Record first non-minimised window as a fallback.
        if (!fallback) fallback = win;

        // Prefer the window whose title we saved when leaving Skim.
        if (savedTitle.length) {
            NSString *t = AXWindowTitle(win);
            if (t && [t isEqualToString:savedTitle]) {
                AXUIElementPerformAction(win, kAXRaiseAction);
                raised = YES;
            }
        }
    }

    // Saved title was empty, stale, or the tab was closed – use the fallback.
    if (!raised && fallback)
        AXUIElementPerformAction(fallback, kAXRaiseAction);

    CFRelease(wins);
}

// ── Entry point ──────────────────────────────────────────────────────────────

int switchFocus(NSString *direction) {
    NSRunningApplication *front = [NSWorkspace sharedWorkspace].frontmostApplication;
    BOOL isAlacritty = [front.localizedName.lowercaseString hasPrefix:@"alacritty"];
    BOOL isSkim      = [front.bundleIdentifier isEqualToString:kSkimBundleID];

    if (!isAlacritty && !isSkim) return AerospaceRun(@[@"focus", direction]);
    if (isSkim && [direction isEqualToString:@"down"]) return 0;

    WorkspaceInfo info = GetWorkspaceInfo();

    // ── Alacritty → Skim (down) ──────────────────────────────────────────────
    if (isAlacritty && [direction isEqualToString:@"down"] && info.alacrittyCount == 1 && info.skimCount > 0) {
        NSRunningApplication *skim =
            [NSRunningApplication runningApplicationsWithBundleIdentifier:kSkimBundleID].firstObject;
        if (skim) {
            NSString *workspace  = GetFocusedWorkspace();
            NSString *savedTitle = LoadSkimTitle(workspace);   // "" if nothing saved
            FocusSkimWindow(skim, savedTitle);                 // falls back gracefully
            return 0;
        }
    }

    // ── Skim → Alacritty (up) ────────────────────────────────────────────────
    if (isSkim && [direction isEqualToString:@"up"] && info.alacrittyCount == 1 && info.alacrittyWinID > 0) {
        NSString *workspace = GetFocusedWorkspace();

        // Record which Skim window we're leaving so we can return to it later.
        AXUIElementRef focusedWin = GetFocusedWindowForPID(front.processIdentifier);
        if (focusedWin) {
            NSString *title = AXWindowTitle(focusedWin);
            SaveSkimTitle(title ?: @"", workspace);   // persist per workspace
            CFRelease(focusedWin);
        }

        NSString *winIDStr = [NSString stringWithFormat:@"%d", info.alacrittyWinID];
        return AerospaceRun(@[@"focus", @"--window-id", winIDStr]);
    }

    return AerospaceRun(@[@"focus", direction]);
}
