#import "skimUtils.h"

int duplicateTab(void) {
    @autoreleasepool {
        SBApplication *skim = GetSkimSBApp();
        if (!skim || ![skim isRunning]) return 0;

        NSArray *documents = [skim valueForKey:@"documents"];
        NSUInteger originalDocCount = documents.count;
        if (originalDocCount == 0) return 0;

        id originalDoc = documents.firstObject;

        NSString *docPath = nil;
        @try { docPath = [originalDoc valueForKey:@"path"]; } @catch(NSException *e) {}
        if (!docPath || [docPath isKindOfClass:[NSNull class]]) return 0;

        NSString *origFilePath = [docPath stringByAppendingString:@".orig"];
        if ([[NSFileManager defaultManager] fileExistsAtPath:origFilePath]) {
            NSError *readError = nil;
            NSString *origContent = [NSString stringWithContentsOfFile:origFilePath encoding:NSUTF8StringEncoding error:&readError];
            if (origContent) {
                docPath = [origContent stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            }
        }

        NSNumber *pageIndex = nil;
        @try { pageIndex = [[originalDoc valueForKey:@"currentPage"] valueForKey:@"index"]; } @catch(NSException *e) {}

        NSString *launchPath = ResolveCanonicalDocumentPath(docPath);
        RunLauncher(launchPath);

        if (pageIndex && [pageIndex integerValue] > 0) {
            int retries = 60;
            NSInteger targetIdx = [pageIndex integerValue];

            while (retries > 0) {
                usleep(50000);

                SBApplication *currentSkim = GetSkimSBApp();
                NSArray *docs = [currentSkim valueForKey:@"documents"];

                if (docs.count > originalDocCount) {
                    @try {
                        id frontDoc = docs.firstObject;
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
