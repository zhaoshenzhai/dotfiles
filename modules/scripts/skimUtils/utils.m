#import "skimUtils.h"

pid_t GetSkimPID(void) {
    NSArray<NSRunningApplication *> *apps = [NSRunningApplication runningApplicationsWithBundleIdentifier:@"net.sourceforge.skim-app.skim"];
    return (apps.count > 0) ? apps.firstObject.processIdentifier : 0;
}

SBApplication *GetSkimSBApp(void) {
    return [SBApplication applicationWithBundleIdentifier:@"net.sourceforge.skim-app.skim"];
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
