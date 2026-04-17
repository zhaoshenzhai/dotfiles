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

    [task launch];
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
                CFRelease(childRole);
                break;
            }
            CFRelease(childRole);
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
                CFRelease(childTitle);
                break;
            }
            CFRelease(childTitle);
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
            id doc = [documents objectAtIndex:0];
            return [doc valueForKey:@"path"];
        }
    } @catch (NSException *e) {
        return nil;
    }

    return nil;
}

NSString *ResolveCanonicalDocumentPath(NSString *rawPath) {
    if (!rawPath || [rawPath isEqualToString:@"missing value"]) return nil;

    NSString *resolvedPath = rawPath;

    if ([rawPath containsString:@"/tmp/skim_pdfs/"]) {
        NSString *origPathFile = [rawPath stringByAppendingString:@".orig"];
        NSFileManager *fm = [NSFileManager defaultManager];

        if ([fm fileExistsAtPath:origPathFile]) {
            NSError *error = nil;
            NSString *origContent = [NSString stringWithContentsOfFile:origPathFile
                                                              encoding:NSUTF8StringEncoding
                                                                 error:&error];
            if (origContent) {
                resolvedPath = [origContent stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            }
        }
    }

    // Resolve iCloud symlink expansions
    NSString *iCloudSearch = @"Library/Mobile Documents/com~apple~CloudDocs";
    if ([resolvedPath containsString:iCloudSearch]) {
        resolvedPath = [resolvedPath stringByReplacingOccurrencesOfString:iCloudSearch withString:@"iCloud"];
    }

    return resolvedPath;
}

// NSString *GetCurrentAerospaceWorkspace(void) {
//     NSTask *task = [[NSTask alloc] init];
//     [task setLaunchPath:@"/bin/sh"];
//     [task setArguments:@[@"-c", @"export PATH=\"/opt/homebrew/bin:/usr/local/bin:$PATH\"; aerospace list-workspaces --focused"]];
//
//     NSPipe *pipe = [NSPipe pipe];
//     [task setStandardOutput:pipe];
//     [task setStandardError:[NSFileHandle fileHandleWithNullDevice]];
//
//     @try {
//         [task launch];
//         [task waitUntilExit];
//         NSData *data = [[pipe fileHandleForReading] readDataToEndOfFile];
//         return [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
//     } @catch (NSException *e) {
//         return nil;
//     }
// }

// AXUIElementRef GetFocusedWindowForPID(pid_t pid) {
//     if (pid == 0) return NULL;
//
//     AXUIElementRef appElement = AXUIElementCreateApplication(pid);
//     AXUIElementRef focusedWindow = NULL;
//
//     AXError error = AXUIElementCopyAttributeValue(appElement, kAXFocusedWindowAttribute, (CFTypeRef *)&focusedWindow);
//     CFRelease(appElement);
//
//     if (error == kAXErrorSuccess) {
//         return focusedWindow;
//     }
//     return NULL;
// }
