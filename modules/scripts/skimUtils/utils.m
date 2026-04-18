#import "skimUtils.h"
#import <spawn.h>
#import <unistd.h>
#import <fcntl.h>

extern char **environ;

pid_t GetSkimPID(void) {
    NSArray<NSRunningApplication *> *apps = [NSRunningApplication runningApplicationsWithBundleIdentifier:@"net.sourceforge.skim-app.skim"];
    return (apps.count > 0) ? apps.firstObject.processIdentifier : 0;
}

SBApplication *GetSkimSBApp(void) {
    return [SBApplication applicationWithBundleIdentifier:@"net.sourceforge.skim-app.skim"];
}

void RunLauncher(NSString *targetPath) {
    if (!targetPath) return;
    const char *launcherPath = "/etc/profiles/per-user/zhao/bin/launcher";

    pid_t pid;
    posix_spawn_file_actions_t actions;
    posix_spawn_file_actions_init(&actions);

    posix_spawn_file_actions_addopen(&actions, STDOUT_FILENO, "/dev/null", O_WRONLY, 0);
    posix_spawn_file_actions_addopen(&actions, STDERR_FILENO, "/dev/null", O_WRONLY, 0);

    const char *argv[] = {"launcher", targetPath.UTF8String, NULL};

    posix_spawn(&pid, launcherPath, &actions, NULL, (char *const *)argv, environ);
    posix_spawn_file_actions_destroy(&actions);
}

AXUIElementRef GetFirstChildWithRole(AXUIElementRef parent, CFStringRef role) {
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

NSString *GetDocumentPathOfFrontmostApp(void) {
    pid_t pid = GetSkimPID();
    if (pid == 0) return nil;

    AXUIElementRef app = AXUIElementCreateApplication(pid);
    AXUIElementRef frontWindow = NULL;
    NSString *path = nil;

    if (AXUIElementCopyAttributeValue(app, kAXFocusedWindowAttribute, (CFTypeRef *)&frontWindow) == kAXErrorSuccess) {
        CFTypeRef documentVal = NULL;
        if (AXUIElementCopyAttributeValue(frontWindow, kAXDocumentAttribute, &documentVal) == kAXErrorSuccess) {
            NSString *urlStr = (__bridge NSString *)documentVal;
            if ([urlStr hasPrefix:@"file://"]) {
                path = [[NSURL URLWithString:urlStr] path];
            }
            CFRelease(documentVal);
        }
        CFRelease(frontWindow);
    }
    CFRelease(app);
    return path;
}

NSString *ResolveCanonicalDocumentPath(NSString *rawPath) {
    if (!rawPath || [rawPath isEqualToString:@"missing value"]) return nil;
    NSString *resolvedPath = rawPath;

    if ([rawPath hasPrefix:@"/tmp/skim_pdfs/"]) {
        NSString *origPathFile = [rawPath stringByAppendingString:@".orig"];
        NSFileManager *fm = [NSFileManager defaultManager];

        if ([fm fileExistsAtPath:origPathFile]) {
            NSString *origContent = [NSString stringWithContentsOfFile:origPathFile encoding:NSUTF8StringEncoding error:nil];
            if (origContent) {
                resolvedPath = [origContent stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            }
        }
    }

    NSString *iCloudSearch = @"Library/Mobile Documents/com~apple~CloudDocs";
    if ([resolvedPath containsString:iCloudSearch]) {
        resolvedPath = [resolvedPath stringByReplacingOccurrencesOfString:iCloudSearch withString:@"iCloud"];
    }

    return resolvedPath;
}

AXUIElementRef GetFocusedWindowForPID(pid_t pid) {
    if (pid == 0) return NULL;
    AXUIElementRef app = AXUIElementCreateApplication(pid);
    CFTypeRef val      = NULL;
    AXUIElementRef result = NULL;
    if (AXUIElementCopyAttributeValue(app, kAXFocusedWindowAttribute, &val) == kAXErrorSuccess) {
        result = (AXUIElementRef)CFRetain(val);
        CFRelease(val);
    }
    CFRelease(app);
    return result;
}

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
