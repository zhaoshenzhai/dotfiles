#import "skimUtils.h"

NSString *ResolveCanonicalDocumentPath(NSString *rawPath) {
    if (!rawPath || [rawPath isEqualToString:@"missing value"]) return nil;

    NSString *resolvedPath = rawPath;

    // Resolve /tmp/skim_pdfs cache pointers
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
