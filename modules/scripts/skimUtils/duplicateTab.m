#import "skimUtils.h"
#import <ScriptingBridge/ScriptingBridge.h>

int duplicateTab(void) {
    @autoreleasepool {
        // 1. Connect via Scripting Bridge (Zero AppleScript text parsing)
        SBApplication *skim = [SBApplication applicationWithBundleIdentifier:@"net.sourceforge.skim-app.skim"];
        if (!skim || ![skim isRunning]) return 0;

        NSArray *documents = [skim valueForKey:@"documents"];
        if (!documents || documents.count == 0) return 0;

        id frontDoc = documents.firstObject;
        NSString *docPath = [frontDoc valueForKey:@"path"];
        if (!docPath || [docPath isKindOfClass:[NSNull class]] || docPath.length == 0) return 0;

        id currentPage = [frontDoc valueForKey:@"currentPage"];
        NSNumber *pageIndex = [currentPage valueForKey:@"index"];

        // 2. Resolve target launch path
        NSString *launchPath = docPath;
        if ([docPath containsString:@"/tmp/skim_pdfs/"]) {
            NSString *origFile = [docPath stringByAppendingString:@".orig"];
            if ([[NSFileManager defaultManager] fileExistsAtPath:origFile]) {
                NSString *origContent = [NSString stringWithContentsOfFile:origFile encoding:NSUTF8StringEncoding error:nil];
                if (origContent) {
                    launchPath = [origContent stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                }
            }
        }

        // 3. Trigger launcher via NSTask
        const char *user = getenv("USER");
        if (!user) user = "root";
        NSString *launcherPath = [NSString stringWithFormat:@"/etc/profiles/per-user/%s/bin/launcher", user];

        NSTask *task = [[NSTask alloc] init];
        [task setLaunchPath:launcherPath];
        [task setArguments:@[launchPath]];

        // Suppress stdout/stderr
        [task setStandardOutput:[NSFileHandle fileHandleWithNullDevice]];
        [task setStandardError:[NSFileHandle fileHandleWithNullDevice]];

        @try {
            [task launch];
        } @catch (NSException *e) {
            fprintf(stderr, "Failed to launch: %s\n", [[e reason] UTF8String]);
            return 1;
        }

        // 4. Background poll using pure Objective-C / Scripting Bridge
        if (pageIndex && [pageIndex integerValue] > 0) {
            // fork() allows the parent process to exit immediately, returning control to zsh/Aerospace
            pid_t pid = fork();
            if (pid == 0) {
                // Child process polling loop
                SBApplication *bgSkim = [SBApplication applicationWithBundleIdentifier:@"net.sourceforge.skim-app.skim"];
                int retries = 25;
                NSInteger targetIdx = [pageIndex integerValue];

                while (retries > 0) {
                    usleep(50000); // 50ms native sleep
                    NSArray *docs = [bgSkim valueForKey:@"documents"];
                    if (docs.count > 0) {
                        id currentFrontDoc = docs.firstObject;
                        NSString *currentPath = [currentFrontDoc valueForKey:@"path"];

                        // If the front document path is different, the new tab has loaded
                        if (currentPath && ![currentPath isEqualToString:docPath]) {
                            NSArray *pages = [currentFrontDoc valueForKey:@"pages"];
                            // ScriptingBridge arrays are 0-indexed, but Skim pages are 1-indexed.
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
