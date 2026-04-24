#import "commonUtils.h"
#import "skimUtils.h"
#import <string.h>
#import <errno.h>

extern AXError _AXUIElementGetWindow(AXUIElementRef element, CGWindowID *id);
static NSString *const kSkimBundleID = @"net.sourceforge.skim-app.skim";
#define SHM_SIZE 1024

static NSString *GetFocusedWorkspace(void) {
    return AerospaceOutput(@[@"list-workspaces", @"--focused"]);
}

static NSString *GetWorkspaceSHM(NSString *workspace) {
    if (!workspace.length) return nil;
    NSCharacterSet *nonAlnum = [[NSCharacterSet alphanumericCharacterSet] invertedSet];
    NSString *safe = [[workspace componentsSeparatedByCharactersInSet:nonAlnum] componentsJoinedByString:@"_"];
    return [NSString stringWithFormat:@"/aerospace_skim_%@", safe];
}

static void SaveSkimID(CGWindowID winID, NSString *workspace) {
    NSString *shmNameStr = GetWorkspaceSHM(workspace);
    const char *shm_name = shmNameStr.UTF8String;

    if (!shm_name) return;

    int fd = shm_open(shm_name, O_CREAT | O_RDWR, 0666);
    if (fd == -1) return;

    char *mem = mmap(NULL, SHM_SIZE, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
    if (mem != MAP_FAILED) {
        snprintf(mem, SHM_SIZE, "%u", winID);
        munmap(mem, SHM_SIZE);
    }
    close(fd);
}

static CGWindowID LoadSkimID(NSString *workspace) {
    NSString *shmNameStr = GetWorkspaceSHM(workspace);
    const char *shm_name = shmNameStr.UTF8String;

    if (!shm_name) return 0;

    int fd = shm_open(shm_name, O_RDONLY, 0666);
    if (fd == -1) return 0;

    char *mem = mmap(NULL, SHM_SIZE, PROT_READ, MAP_SHARED, fd, 0);
    CGWindowID resultID = 0;

    if (mem != MAP_FAILED) {
        resultID = (CGWindowID)strtoul(mem, NULL, 10);
        munmap(mem, SHM_SIZE);
    }
    close(fd);
    return resultID;
}

static NSDictionary *GetFocusedWorkspaceDetails(void) {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    dict[@"skimPresent"] = @(NO);
    dict[@"firstNonSkimWinID"] = @(-1);
    NSMutableSet<NSNumber *> *skimWinIDs = [NSMutableSet set];

    NSString *raw = AerospaceOutput(@[@"list-windows", @"--workspace", @"focused", @"--format", @"%{app-bundle-id}|%{window-id}"]);
    if (!raw.length) return dict;

    __block BOOL skimPresent = NO;
    __block int firstNonSkimWinID = -1;

    [raw enumerateLinesUsingBlock:^(NSString *line, BOOL *stop) {
        NSArray<NSString *> *parts = [line componentsSeparatedByString:@"|"];
        if (parts.count < 2) return;

        if ([parts[0] isEqualToString:kSkimBundleID]) {
            skimPresent = YES;
            [skimWinIDs addObject:@(parts[1].intValue)];
        } else if (firstNonSkimWinID == -1) {
            firstNonSkimWinID = parts[1].intValue;
        }
    }];

    dict[@"skimPresent"] = @(skimPresent);
    dict[@"firstNonSkimWinID"] = @(firstNonSkimWinID);
    dict[@"skimWinIDs"] = skimWinIDs;
    return dict;
}

static BOOL FocusSkimWindow(NSRunningApplication *skim, CGWindowID savedWinID, NSSet<NSNumber *> *workspaceSkimIDs) {
    [skim activateWithOptions:NSApplicationActivateAllWindows];

    CFArrayRef wins = CopyAXWindows(skim.processIdentifier);
    if (!wins) return NO;

    CFIndex count = CFArrayGetCount(wins);
    if (count == 0) {
        CFRelease(wins);
        return NO;
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

        CGWindowID currentWinID = 0;
        if (_AXUIElementGetWindow(win, &currentWinID) == kAXErrorSuccess) {
            if (savedWinID > 0 && currentWinID == savedWinID) {
                AXUIElementPerformAction(win, kAXRaiseAction);
                raised = YES;
            } else if (!fallback && [workspaceSkimIDs containsObject:@(currentWinID)]) {
                fallback = win;
            }
        }
    }

    if (!raised && fallback) {
        AXUIElementPerformAction(fallback, kAXRaiseAction);
        raised = YES;
    }

    CFRelease(wins);
    return raised;
}

int switchFocus(NSString *direction) {
    NSRunningApplication *front = [NSWorkspace sharedWorkspace].frontmostApplication;
    BOOL isSkim = [front.bundleIdentifier isEqualToString:kSkimBundleID];

    if (isSkim && [direction isEqualToString:@"down"]) return 0;
    if (!isSkim && ![direction isEqualToString:@"down"] && ![direction isEqualToString:@"up"]) return AerospaceRun(@[@"focus", direction]);

    NSDictionary *wsDetails = GetFocusedWorkspaceDetails();
    BOOL skimPresent = [wsDetails[@"skimPresent"] boolValue];
    int firstNonSkimWinID = [wsDetails[@"firstNonSkimWinID"] intValue];
    NSSet<NSNumber *> *workspaceSkimIDs = wsDetails[@"skimWinIDs"];

    if (!isSkim && [direction isEqualToString:@"down"] && skimPresent) {
        NSRunningApplication *skim = [NSRunningApplication runningApplicationsWithBundleIdentifier:kSkimBundleID].firstObject;
        if (skim) {
            NSString *workspace = GetFocusedWorkspace();
            CGWindowID savedWinID = LoadSkimID(workspace);

            BOOL success = FocusSkimWindow(skim, savedWinID, workspaceSkimIDs);
            if (success) return 0;
        }
    }

    if (isSkim && [direction isEqualToString:@"up"] && firstNonSkimWinID != -1) {
        AXUIElementRef focused = GetFocusedWindowForPID(front.processIdentifier);
        if (focused) {
            CGWindowID winID = 0;
            if (_AXUIElementGetWindow(focused, &winID) == kAXErrorSuccess) {
                SaveSkimID(winID, GetFocusedWorkspace());
            }
            CFRelease(focused);
        }

        return AerospaceRun(@[@"focus", @"--window-id", [NSString stringWithFormat:@"%d", firstNonSkimWinID]]);
    }

    return AerospaceRun(@[@"focus", direction]);
}
