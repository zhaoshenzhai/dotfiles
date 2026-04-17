#import "skimUtils.h"

pid_t GetSkimPID(void) {
    NSArray<NSRunningApplication *> *apps = [NSRunningApplication runningApplicationsWithBundleIdentifier:@"net.sourceforge.skim-app.skim"];
    return (apps.count > 0) ? apps.firstObject.processIdentifier : 0;
}

SBApplication *GetSkimSBApp(void) {
    return [SBApplication applicationWithBundleIdentifier:@"net.sourceforge.skim-app.skim"];
}

void RunLauncher(NSString *targetPath) {
    if (!targetPath) return;
    NSString *launcherPath = [NSString stringWithFormat:@"/etc/profiles/per-user/%@/bin/launcher", NSUserName()];

    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:launcherPath];
    [task setArguments:@[targetPath]];
    [task setStandardOutput:[NSFileHandle fileHandleWithNullDevice]];
    [task setStandardError:[NSFileHandle fileHandleWithNullDevice]];

    if (@available(macOS 10.13, *)) {
        NSError *error = nil;
        [task launchAndReturnError:&error];
    } else {
        [task launch];
    }
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
    NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
    NSRunningApplication *frontApp = [workspace frontmostApplication];
    if (!frontApp) return nil;

    SBApplication *app = [SBApplication applicationWithProcessIdentifier:frontApp.processIdentifier];
    if (!app) return nil;

    @try {
        SBElementArray *documents = [app valueForKey:@"documents"];
        if (documents && documents.count > 0) {
            return [[documents objectAtIndex:0] valueForKey:@"path"];
        }
    } @catch (NSException *e) { return nil; }

    return nil;
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
