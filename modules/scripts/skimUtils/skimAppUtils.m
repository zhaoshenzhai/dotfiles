#import "skimUtils.h"

pid_t GetSkimPID(void) {
    NSArray<NSRunningApplication *> *apps = [NSRunningApplication runningApplicationsWithBundleIdentifier:@"net.sourceforge.skim-app.skim"];
    if (apps.count > 0) {
        return apps.firstObject.processIdentifier;
    }
    return 0;
}

AXUIElementRef GetFocusedWindowForPID(pid_t pid) {
    if (pid == 0) return NULL;

    AXUIElementRef appElement = AXUIElementCreateApplication(pid);
    AXUIElementRef focusedWindow = NULL;

    AXError error = AXUIElementCopyAttributeValue(appElement, kAXFocusedWindowAttribute, (CFTypeRef *)&focusedWindow);
    CFRelease(appElement);

    if (error == kAXErrorSuccess) {
        return focusedWindow;
    }
    return NULL;
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
