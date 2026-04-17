#import "skimUtils.h"
#import <ScriptingBridge/ScriptingBridge.h>

int duplicateTab(void) {
    @autoreleasepool {
        SBApplication *skim = GetSkimSBApp();
        if (!skim || ![skim isRunning]) return 0;

        NSArray *documents = [skim valueForKey:@"documents"];
        NSUInteger originalDocCount = documents.count;
        if (!documents || originalDocCount == 0) return 0;

        id originalDoc = documents.firstObject;
        NSString *docPath = nil;
        @try { docPath = [originalDoc valueForKey:@"path"]; } @catch(NSException*e){}

        if (!docPath || [docPath isKindOfClass:[NSNull class]]) return 0;

        // Extract Page Index
        NSNumber *pageIndex = nil;
        @try { pageIndex = [[originalDoc valueForKey:@"currentPage"] valueForKey:@"index"]; } @catch(NSException*e){}

        // Extract Window ID for new tab detection
        NSNumber *originalWindowId = nil;
        @try {
            id activeWindow = [originalDoc valueForKey:@"activeWindow"];
            originalWindowId = [activeWindow valueForKey:@"id"];
        } @catch(NSException*e){}

        // Launch Duplicate
        NSString *launchPath = ResolveCanonicalDocumentPath(docPath);
        RunLauncher(launchPath);

        // Synchronous State Sync (50ms polling loop)
        if (pageIndex && [pageIndex integerValue] > 0) {
            int retries = 60; // 3 second timeout
            NSInteger targetIdx = [pageIndex integerValue];

            while (retries > 0) {
                usleep(50000);

                SBApplication *currentSkim = GetSkimSBApp();
                NSArray *docs = [currentSkim valueForKey:@"documents"];

                // Detect new tab: Either the overall document count increased,
                // OR the active window ID changed (if opened in a separate window).
                BOOL isNewTab = NO;
                if (docs.count > originalDocCount) {
                    isNewTab = YES;
                } else if (docs.count > 0 && originalWindowId) {
                    NSNumber *frontWindowId = nil;
                    @try { frontWindowId = [[docs.firstObject valueForKey:@"activeWindow"] valueForKey:@"id"]; } @catch(NSException*e){}
                    if (frontWindowId && ![frontWindowId isEqualToNumber:originalWindowId]) {
                        isNewTab = YES;
                    }
                }

                if (isNewTab && docs.count > 0) {
                    id frontDoc = docs.firstObject;

                    // Apply Page Only
                    @try {
                        NSArray *pages = [frontDoc valueForKey:@"pages"];
                        if (targetIdx > 0 && targetIdx <= pages.count) {
                            [frontDoc setValue:pages[targetIdx - 1] forKey:@"currentPage"];
                        }
                    } @catch(NSException*e){}

                    break;
                }
                retries--;
            }
        }
    }
    return 0;
}
