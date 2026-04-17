#import "skimUtils.h"

int cleanDuplicates(void) {
    @autoreleasepool {
        NSFileManager *fm = [NSFileManager defaultManager];
        NSURL *cacheDirURL = [NSURL fileURLWithPath:@"/tmp/skim_pdfs" isDirectory:YES];

        NSDirectoryEnumerator *enumerator = [fm enumeratorAtURL:cacheDirURL
                                     includingPropertiesForKeys:@[NSURLIsDirectoryKey]
                                                        options:NSDirectoryEnumerationSkipsSubdirectoryDescendants
                                                   errorHandler:nil];

        NSTimeInterval currentTime = [[NSDate date] timeIntervalSince1970];

        for (NSURL *fileURL in enumerator) {
            NSNumber *isDirectory;
            [fileURL getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:nil];

            if ([isDirectory boolValue]) {
                NSString *dirname = [fileURL lastPathComponent];
                NSScanner *scanner = [NSScanner scannerWithString:dirname];
                NSInteger timestamp = 0;

                if ([scanner scanInteger:&timestamp] && [scanner isAtEnd]) {
                    NSTimeInterval age = currentTime - (NSTimeInterval)timestamp;
                    if (age > 86400.0) [fm removeItemAtURL:fileURL error:nil];
                }
            }
        }
    }
    return 0;
}
