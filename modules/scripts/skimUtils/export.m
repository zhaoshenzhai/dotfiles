#import "commonUtils.h"
#import "skimUtils.h"

int exportTex(void) {
    @autoreleasepool {
        SBApplication *skim = GetSkimSBApp();
        if (!skim || ![skim isRunning]) return 0;

        NSArray *documents = [skim valueForKey:@"documents"];
        if (documents.count == 0) return 0;

        id originalDoc = documents.firstObject;

        NSString *docPath = nil;
        @try { docPath = [originalDoc valueForKey:@"path"]; } @catch(NSException *e) {}
        if (!docPath || [docPath isKindOfClass:[NSNull class]]) return 0;

        NSString *origFilePath = [docPath stringByAppendingString:@".orig"];
        NSFileManager *fm = [NSFileManager defaultManager];

        if ([fm fileExistsAtPath:origFilePath]) {
            NSError *readError = nil;
            NSString *origContent = [NSString stringWithContentsOfFile:origFilePath encoding:NSUTF8StringEncoding error:&readError];
            if (origContent) {
                docPath = [origContent stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            }
        }

        NSString *noteID = [[docPath lastPathComponent] stringByDeletingPathExtension];
        if (!noteID || noteID.length == 0) return 0;

        NSString *sourcePath = [NSString stringWithFormat:@"%@/Projects/_attic/notes/%@/%@.tex", kBaseDir, noteID, noteID];
        NSString *destPath = [NSString stringWithFormat:@"%@/Downloads/%@.tex", NSHomeDirectory(), noteID];

        if ([fm fileExistsAtPath:sourcePath]) {
            if ([fm fileExistsAtPath:destPath]) {
                [fm removeItemAtPath:destPath error:nil];
            }
            [fm copyItemAtPath:sourcePath toPath:destPath error:nil];
        }
    }
    return 0;
}
