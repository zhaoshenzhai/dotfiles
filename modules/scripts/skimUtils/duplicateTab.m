#import "skimUtils.h"
#import <ScriptingBridge/ScriptingBridge.h>

int duplicateTab(void) {
    @autoreleasepool {
        SBApplication *skim = GetSkimSBApp();
        if (!skim || ![skim isRunning]) return 0;

        NSArray *documents = [skim valueForKey:@"documents"];
        if (!documents || documents.count == 0) return 0;

        id frontDoc = documents.firstObject;
        NSString *docPath = [frontDoc valueForKey:@"path"];

        // Use pathUtils helper instead of manual .orig check
        NSString *launchPath = ResolveCanonicalDocumentPath(docPath);
        if (!launchPath) return 0;

        id currentPage = [frontDoc valueForKey:@"currentPage"];
        NSNumber *pageIndex = [currentPage valueForKey:@"index"];

        RunLauncher(launchPath);

        if (pageIndex && [pageIndex integerValue] > 0) {
            pid_t pid = fork();
            if (pid == 0) {
                SBApplication *bgSkim = [SBApplication applicationWithBundleIdentifier:@"net.sourceforge.skim-app.skim"];
                int retries = 25;
                NSInteger targetIdx = [pageIndex integerValue];

                while (retries > 0) {
                    usleep(50000);
                    NSArray *docs = [bgSkim valueForKey:@"documents"];
                    if (docs.count > 0) {
                        id currentFrontDoc = docs.firstObject;
                        NSString *currentPath = [currentFrontDoc valueForKey:@"path"];

                        if (currentPath && ![currentPath isEqualToString:docPath]) {
                            NSArray *pages = [currentFrontDoc valueForKey:@"pages"];
                            if (targetIdx <= pages.count) {
                                id targetPage = [pages objectAtIndex:(targetIdx - 1)];
                                [currentFrontDoc setValue:targetPage forKey:@"currentPage"];
                            }
                            break;
                        }
                    }
                    retries--;
                }
                exit(0);
            } else if (pid < 0) {
                fprintf(stderr, "Fork failed\n");
                return 1;
            }
        }
    }
    return 0;
}
