#import "commonUtils.h"
#import <spawn.h>
#import <sys/wait.h>
#import <fcntl.h>
#import <unistd.h>

extern char **environ;

NSString *const kBaseDir = @"/Users/zhao/iCloud";
NSString *const kAerospacePath = @"/etc/profiles/per-user/zhao/bin/aerospace";
NSString *const kNvimPath = @"/etc/profiles/per-user/zhao/bin/nvim";
NSString *const kLauncherPath = @"/run/current-system/sw/bin/launcher";

// --- Command Execution ---

static char **CreateArgv(NSString *cmdPath, NSArray<NSString *> *argsArray, int *outArgc) {
    int argc = (int)argsArray.count + 1;
    char **argv = malloc((argc + 1) * sizeof(char *));
    argv[0] = strdup(cmdPath.lastPathComponent.UTF8String);
    for (int i = 0; i < argsArray.count; i++) {
        argv[i + 1] = strdup(argsArray[i].UTF8String);
    }
    argv[argc] = NULL;
    *outArgc = argc;
    return argv;
}

static void FreeArgv(char **argv, int argc) {
    for (int i = 0; i < argc; i++) free(argv[i]);
    free(argv);
}

int RunCommandWait(NSString *cmdPath, NSArray<NSString *> *argsArray) {
    int argc;
    char **argv = CreateArgv(cmdPath, argsArray, &argc);
    pid_t pid;
    posix_spawn_file_actions_t actions;

    posix_spawn_file_actions_init(&actions);
    posix_spawn_file_actions_addopen(&actions, STDOUT_FILENO, "/dev/null", O_WRONLY, 0);
    posix_spawn_file_actions_addopen(&actions, STDERR_FILENO, "/dev/null", O_WRONLY, 0);

    int status = -1;
    if (posix_spawn(&pid, cmdPath.UTF8String, &actions, NULL, argv, environ) == 0) {
        waitpid(pid, &status, 0);
    }

    posix_spawn_file_actions_destroy(&actions);
    FreeArgv(argv, argc);
    return status;
}

NSString *RunCommandOutput(NSString *cmdPath, NSArray<NSString *> *argsArray) {
    int pipefd[2];
    if (pipe(pipefd) != 0) return @"";

    int argc;
    char **argv = CreateArgv(cmdPath, argsArray, &argc);
    pid_t pid;

    posix_spawn_file_actions_t actions;
    posix_spawn_file_actions_init(&actions);
    posix_spawn_file_actions_adddup2(&actions, pipefd[1], STDOUT_FILENO);
    posix_spawn_file_actions_addclose(&actions, pipefd[0]);

    if (posix_spawn(&pid, cmdPath.UTF8String, &actions, NULL, argv, environ) != 0) {
        posix_spawn_file_actions_destroy(&actions);
        close(pipefd[0]); close(pipefd[1]);
        FreeArgv(argv, argc);
        return @"";
    }

    posix_spawn_file_actions_destroy(&actions);
    close(pipefd[1]);

    NSMutableData *data = [[NSMutableData alloc] initWithCapacity:4096];
    char buffer[4096];
    ssize_t bytesRead;

    while ((bytesRead = read(pipefd[0], buffer, sizeof(buffer))) > 0) {
        [data appendBytes:buffer length:bytesRead];
    }
    close(pipefd[0]);
    waitpid(pid, NULL, 0);

    FreeArgv(argv, argc);
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

void RunCommandDetached(NSString *cmdPath, NSArray<NSString *> *argsArray) {
    int argc;
    char **argv = CreateArgv(cmdPath, argsArray, &argc);
    pid_t pid;

    posix_spawn_file_actions_t actions;
    posix_spawn_file_actions_init(&actions);
    posix_spawn_file_actions_addopen(&actions, STDOUT_FILENO, "/dev/null", O_WRONLY, 0);
    posix_spawn_file_actions_addopen(&actions, STDERR_FILENO, "/dev/null", O_WRONLY, 0);

    posix_spawnattr_t attr;
    posix_spawnattr_init(&attr);
    posix_spawnattr_setflags(&attr, POSIX_SPAWN_SETSID);

    posix_spawn(&pid, cmdPath.UTF8String, &actions, &attr, argv, environ);

    posix_spawnattr_destroy(&attr);
    posix_spawn_file_actions_destroy(&actions);
    FreeArgv(argv, argc);
}

// -- File and Directory Utilities

void EnsureSystemPath(void) {
    const char *currentPath = getenv("PATH");
    char newPath[8192];
    snprintf(newPath, sizeof(newPath),
        "/run/current-system/sw/bin:/etc/profiles/per-user/%s/bin:%s/.nix-profile/bin:/nix/var/nix/profiles/default/bin:/opt/homebrew/bin:/usr/local/bin:%s",
        getenv("USER"), getenv("HOME"), currentPath ? currentPath : "");
    setenv("PATH", newPath, 1);
}

unsigned int HashString(const char *str) {
    unsigned int hash = 5381;
    int c;
    while ((c = *str++)) hash = ((hash << 5) + hash) + c;
    return hash;
}

int EnsureDirectoryExists(const char *path) {
    @autoreleasepool {
        NSString *nsPath = [NSString stringWithUTF8String:path];
        NSError *error = nil;
        [[NSFileManager defaultManager] createDirectoryAtPath:nsPath
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:&error];
        return error == nil ? 0 : 1;
    }
}

int MoveFile(const char *src, const char *dst) {
    @autoreleasepool {
        NSString *nsSrc = [NSString stringWithUTF8String:src];
        NSString *nsDst = [NSString stringWithUTF8String:dst];
        NSFileManager *fm = [NSFileManager defaultManager];

        [fm removeItemAtPath:nsDst error:nil]; // Equivalent to mv -f
        return [fm moveItemAtPath:nsSrc toPath:nsDst error:nil] ? 0 : 1;
    }
}

// --- Process and Accessibility Utilities ---

bool IsProcessRunning(const char *pattern) {
    @autoreleasepool {
        NSString *cmd = @"/usr/bin/pgrep";
        NSArray *args = @[@"-f", [NSString stringWithUTF8String:pattern]];
        // Leverages posix_spawn internally, avoiding shell overhead
        int status = RunCommandWait(cmd, args);
        return (status == 0);
    }
}

AXUIElementRef GetFocusedWindowForPID(pid_t pid) {
    if (pid == 0) return NULL;
    AXUIElementRef app = AXUIElementCreateApplication(pid);
    CFTypeRef val = NULL;
    AXUIElementRef result = NULL;
    if (AXUIElementCopyAttributeValue(app, kAXFocusedWindowAttribute, &val) == kAXErrorSuccess) {
        result = (AXUIElementRef)CFRetain(val);
        CFRelease(val);
    }
    CFRelease(app);
    return result;
}

CFArrayRef CopyAXWindows(pid_t pid) {
    if (pid == 0) return NULL;
    AXUIElementRef appElem = AXUIElementCreateApplication(pid);
    CFTypeRef val = NULL;
    CFArrayRef result = NULL;

    if (AXUIElementCopyAttributeValue(appElem, kAXWindowsAttribute, &val) == kAXErrorSuccess) {
        result = (CFArrayRef)CFRetain(val);
        CFRelease(val);
    }
    CFRelease(appElem);
    return result;
}

NSString *AXWindowTitle(AXUIElementRef win) {
    if (!win) return nil;
    CFTypeRef val = NULL;
    if (AXUIElementCopyAttributeValue(win, kAXTitleAttribute, &val) != kAXErrorSuccess) return nil;
    NSString *title = [(__bridge NSString *)val copy];
    CFRelease(val);
    return title;
}

AXUIElementRef GetFirstChildWithRole(AXUIElementRef parent, CFStringRef role) {
    if (!parent || !role) return NULL;
    CFTypeRef children = NULL;
    if (AXUIElementCopyAttributeValue(parent, kAXChildrenAttribute, &children) != kAXErrorSuccess) return NULL;

    AXUIElementRef found = NULL;
    CFIndex count = CFArrayGetCount((CFArrayRef)children);

    for (CFIndex i = 0; i < count; i++) {
        AXUIElementRef child = (AXUIElementRef)CFArrayGetValueAtIndex((CFArrayRef)children, i);
        CFTypeRef childRole = NULL;
        if (AXUIElementCopyAttributeValue(child, kAXRoleAttribute, &childRole) == kAXErrorSuccess) {
            if (CFStringCompare((CFStringRef)childRole, role, 0) == kCFCompareEqualTo) {
                found = (AXUIElementRef)CFRetain(child);
            }
            CFRelease(childRole);
            if (found) break;
        }
    }
    CFRelease(children);
    return found;
}

AXUIElementRef GetSubmenu(AXUIElementRef element) {
    return GetFirstChildWithRole(element, kAXMenuRole);
}

AXUIElementRef FindChildWithTitle(AXUIElementRef parent, NSString *title) {
    if (!parent || !title) return NULL;
    CFTypeRef children = NULL;
    if (AXUIElementCopyAttributeValue(parent, kAXChildrenAttribute, &children) != kAXErrorSuccess) return NULL;

    AXUIElementRef found = NULL;
    CFIndex count = CFArrayGetCount((CFArrayRef)children);

    for (CFIndex i = 0; i < count; i++) {
        AXUIElementRef child = (AXUIElementRef)CFArrayGetValueAtIndex((CFArrayRef)children, i);
        CFTypeRef childTitle = NULL;
        if (AXUIElementCopyAttributeValue(child, kAXTitleAttribute, &childTitle) == kAXErrorSuccess) {
            if ([(__bridge NSString *)childTitle isEqualToString:title]) {
                found = (AXUIElementRef)CFRetain(child);
            }
            CFRelease(childTitle);
            if (found) break;
        }
    }
    CFRelease(children);
    return found;
}

// --- Input Simulation ---

void PostKeystrokeToPID(pid_t pid, CGKeyCode keyCode, CGEventFlags flags) {
    if (pid == 0) return;

    CGEventSourceRef source = CGEventSourceCreate(kCGEventSourceStatePrivate);
    CGEventRef keyDown = CGEventCreateKeyboardEvent(source, keyCode, true);
    CGEventRef keyUp = CGEventCreateKeyboardEvent(source, keyCode, false);

    if (flags != 0) {
        CGEventSetFlags(keyDown, flags);
        CGEventSetFlags(keyUp, flags);
    }

    CGEventPostToPid(pid, keyDown);
    CGEventPostToPid(pid, keyUp);

    CFRelease(keyDown);
    CFRelease(keyUp);
    CFRelease(source);
}
