#import "commonUtils.h"
#import "skimUtils.h"

static NSString *const kSkimBundleID = @"net.sourceforge.skim-app.skim";
#define SHM_SIZE 1024

typedef struct {
    NSInteger alacrittyCount;
    pid_t     alacrittyPID;
    int       alacrittyWinID;
    NSInteger skimCount;
    NSString  *firstSkimTitle;
} WorkspaceInfo;

static void SaveToSHM(NSString *key, NSString *value) {
    if (!key || !value) return;
    char shm_name[128];
    snprintf(shm_name, sizeof(shm_name), "/%s", key.UTF8String);

    int fd = shm_open(shm_name, O_CREAT | O_RDWR | O_TRUNC, 0666);
    if (fd == -1) return;

    ftruncate(fd, SHM_SIZE);
    char *mem = mmap(NULL, SHM_SIZE, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);

    if (mem != MAP_FAILED) {
        strncpy(mem, value.UTF8String, SHM_SIZE - 1);
        mem[SHM_SIZE - 1] = '\0';
        munmap(mem, SHM_SIZE);
    }
    close(fd);
}

static NSString *LoadFromSHM(NSString *key) {
    if (!key) return @"";
    char shm_name[128];
    snprintf(shm_name, sizeof(shm_name), "/%s", key.UTF8String);

    int fd = shm_open(shm_name, O_RDONLY, 0666);
    if (fd == -1) return @"";

    char *mem = mmap(NULL, SHM_SIZE, PROT_READ, MAP_SHARED, fd, 0);
    NSString *result = @"";

    if (mem != MAP_FAILED) {
        result = [NSString stringWithUTF8String:mem];
        munmap(mem, SHM_SIZE);
    }

    close(fd);
    return [result stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

static WorkspaceInfo GetWorkspaceInfo(void) {
    WorkspaceInfo info = { 0, 0, 0, 0, nil };
    NSString *raw = AerospaceOutput(@[@"list-windows", @"--workspace", @"focused",
                                      @"--format", @"%{app-name}|%{app-bundle-id}|%{app-pid}|%{window-id}|%{window-title}"]);
    if (!raw.length) return info;

    NSArray *lines = [raw componentsSeparatedByString:@"\n"];
    for (NSString *line in lines) {
        NSArray *parts = [line componentsSeparatedByString:@"|"];
        if (parts.count >= 5) {
            NSString *appName = parts[0];
            NSString *bundleID = parts[1];
            int pid = [parts[2] intValue];
            int winID = [parts[3] intValue];

            NSString *title = [[parts subarrayWithRange:NSMakeRange(4, parts.count - 4)] componentsJoinedByString:@"|"];

            if ([appName.lowercaseString containsString:@"alacritty"]) {
                info.alacrittyCount++;
                if (info.alacrittyCount == 1) {
                    info.alacrittyPID = pid;
                    info.alacrittyWinID = winID;
                }
            } else if ([bundleID isEqualToString:kSkimBundleID]) {
                info.skimCount++;
                if (!info.firstSkimTitle) {
                    info.firstSkimTitle = title;
                }
            }
        }
    }

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

    if (isSkim && [direction isEqualToString:@"down"]) return 0;
    if (!isAlacritty && !isSkim) return AerospaceRun(@[@"focus", direction]);

    NSString *workspace = AerospaceOutput(@[@"list-workspaces", @"--focused"]);
    if (!workspace || workspace.length == 0) workspace = @"UNKNOWN";

    NSString *skimShmKey = [NSString stringWithFormat:@"aerospace_skim_%@", workspace];
    NSString *alaShmKey  = [NSString stringWithFormat:@"aerospace_alacritty_%@", workspace];

    WorkspaceInfo info = GetWorkspaceInfo();

    if (isAlacritty && [direction isEqualToString:@"down"] && info.skimCount > 0) {
        if (info.alacrittyWinID > 0) SaveToSHM(alaShmKey, [NSString stringWithFormat:@"%d", info.alacrittyWinID]);

        NSString *savedSkimTitle = LoadFromSHM(skimShmKey);

        if (!savedSkimTitle || savedSkimTitle.length == 0) {
            if (info.firstSkimTitle && info.firstSkimTitle.length > 0) {
                savedSkimTitle = info.firstSkimTitle;
                SaveToSHM(skimShmKey, savedSkimTitle);
            }
        }

        NSRunningApplication *skim = [NSRunningApplication runningApplicationsWithBundleIdentifier:kSkimBundleID].firstObject;
        if (skim) {
            FocusSkimWindow(skim, savedSkimTitle);
            return 0;
        }
    }

    if (isSkim && [direction isEqualToString:@"up"]) {
        AXUIElementRef focusedWin = GetFocusedWindowForPID(front.processIdentifier);
        if (focusedWin) {
            NSString *title = AXWindowTitle(focusedWin);
            if (title) SaveToSHM(skimShmKey, title);
            CFRelease(focusedWin);
        }

        int targetWinID = [LoadFromSHM(alaShmKey) intValue];

        if (targetWinID <= 0 && info.alacrittyWinID > 0) targetWinID = info.alacrittyWinID;

        if (targetWinID > 0) {
            NSString *winIDStr = [NSString stringWithFormat:@"%d", targetWinID];
            return AerospaceRun(@[@"focus", @"--window-id", winIDStr]);
        }
    }

    return AerospaceRun(@[@"focus", direction]);
}
