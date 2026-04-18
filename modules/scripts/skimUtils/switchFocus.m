#import <spawn.h>
#import <sys/wait.h>
#import <sys/mman.h>
#import <fcntl.h>
#import <unistd.h>
#import "skimUtils.h"

extern char **environ;

static NSString *const kSkimBundleID = @"net.sourceforge.skim-app.skim";
static const char *const kAerospacePath = "/etc/profiles/per-user/zhao/bin/aerospace";
#define SHM_SIZE 1024

typedef struct {
    NSInteger alacrittyCount;
    pid_t     alacrittyPID;
    int       alacrittyWinID;
    NSInteger skimCount;
} WorkspaceInfo;

static int AerospaceRun(NSArray<NSString *> *argsArray) {
    int argc = (int)argsArray.count + 1;
    char **argv = malloc((argc + 1) * sizeof(char *));
    argv[0] = strdup("aerospace");
    for (int i = 0; i < argsArray.count; i++) {
        argv[i + 1] = strdup(argsArray[i].UTF8String);
    }
    argv[argc] = NULL;

    pid_t pid;
    posix_spawn_file_actions_t actions;
    posix_spawn_file_actions_init(&actions);

    posix_spawn_file_actions_addopen(&actions, STDOUT_FILENO, "/dev/null", O_WRONLY, 0);
    posix_spawn_file_actions_addopen(&actions, STDERR_FILENO, "/dev/null", O_WRONLY, 0);

    if (posix_spawn(&pid, kAerospacePath, &actions, NULL, argv, environ) == 0) {
        waitpid(pid, NULL, 0);
    }

    posix_spawn_file_actions_destroy(&actions);
    for (int i = 0; i < argc; i++) free(argv[i]);
    free(argv);
    return 0;
}

static NSString *AerospaceOutput(NSArray<NSString *> *argsArray) {
    int pipefd[2];
    if (pipe(pipefd) != 0) return @"";

    int argc = (int)argsArray.count + 1;
    char **argv = malloc((argc + 1) * sizeof(char *));
    argv[0] = strdup("aerospace");
    for (int i = 0; i < argsArray.count; i++) {
        argv[i + 1] = strdup(argsArray[i].UTF8String);
    }
    argv[argc] = NULL;

    pid_t pid;
    posix_spawn_file_actions_t actions;
    posix_spawn_file_actions_init(&actions);

    posix_spawn_file_actions_adddup2(&actions, pipefd[1], STDOUT_FILENO);
    posix_spawn_file_actions_addclose(&actions, pipefd[0]);

    if (posix_spawn(&pid, kAerospacePath, &actions, NULL, argv, environ) != 0) {
        posix_spawn_file_actions_destroy(&actions);
        close(pipefd[0]); close(pipefd[1]);
        for (int i = 0; i < argc; i++) free(argv[i]);
        free(argv);
        return @"";
    }

    posix_spawn_file_actions_destroy(&actions);
    close(pipefd[1]);

    NSMutableData *data = [[NSMutableData alloc] initWithCapacity:1024];
    char buffer[1024];
    ssize_t bytesRead;

    while ((bytesRead = read(pipefd[0], buffer, sizeof(buffer))) > 0) {
        [data appendBytes:buffer length:bytesRead];
    }
    close(pipefd[0]);
    waitpid(pid, NULL, 0);

    for (int i = 0; i < argc; i++) free(argv[i]);
    free(argv);

    NSString *outStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    return outStr ? [outStr stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] : @"";
}

static void SaveSkimTitle(NSString *title, pid_t alacrittyPID) {
    if (!title.length) return;
    char shm_name[64];
    snprintf(shm_name, sizeof(shm_name), "/aerospace_skim_%d", alacrittyPID);

    int fd = shm_open(shm_name, O_CREAT | O_RDWR, 0666);
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

    return [result stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

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

static void FocusSkimWindow(NSRunningApplication *skim, NSString *savedTitle) {
    CFArrayRef wins = CopyAXWindows(skim.processIdentifier);
    if (!wins) { [skim activateWithOptions:0]; return; }

    CFIndex count = CFArrayGetCount(wins);
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
