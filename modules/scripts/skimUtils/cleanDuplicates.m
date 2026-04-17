#import "skimUtils.h"
#import <CoreGraphics/CoreGraphics.h>

int cleanDuplicates(void) {
    NSFileManager *fm = [NSFileManager defaultManager];

    // // --- Part 1: Clean stale Aerospace focus memory ---
    // // We still need to ask Aerospace for the custom workspace name,
    // // as workspaces are an Aerospace concept, not native macOS spaces.
    // NSTask *task = [[NSTask alloc] init];
    // [task setLaunchPath:@"/bin/sh"];
    // // Ensure homebrew paths are included in case NSTask environment is minimal
    // [task setArguments:@[@"-c", @"export PATH=\"/opt/homebrew/bin:/usr/local/bin:$PATH\"; aerospace list-workspaces --focused"]];

    // NSPipe *pipe = [NSPipe pipe];
    // [task setStandardOutput:pipe];
    // [task setStandardError:[NSFileHandle fileHandleWithNullDevice]];

    // @try {
    //     [task launch];
    //     [task waitUntilExit];

    //     NSData *data = [[pipe fileHandleForReading] readDataToEndOfFile];
    //     NSString *workspace = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

    //     if (workspace && workspace.length > 0) {
    //         NSString *memoryFile = [NSString stringWithFormat:@"/tmp/aerospace_skim_tabs/workspace_%@.txt", workspace];

    //         if ([fm fileExistsAtPath:memoryFile]) {
    //             NSString *savedIdStr = [NSString stringWithContentsOfFile:memoryFile encoding:NSUTF8StringEncoding error:nil];
    //             savedIdStr = [savedIdStr stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

    //             if (savedIdStr && savedIdStr.length > 0) {
    //                 CGWindowID windowID = (CGWindowID)[savedIdStr integerValue];

    //                 // Native macOS API to check if window exists (Instantaneous)
    //                 CFArrayRef windowList = CGWindowListCopyWindowInfo(kCGWindowListOptionIncludingWindow, windowID);
    //                 BOOL windowExists = NO;
    //                 if (windowList) {
    //                     if (CFArrayGetCount(windowList) > 0) {
    //                         windowExists = YES;
    //                     }
    //                     CFRelease(windowList);
    //                 }

    //                 // If the window is gone, delete the stale tracking file
    //                 if (!windowExists) {
    //                     [fm removeItemAtPath:memoryFile error:nil];
    //                 }
    //             }
    //         }
    //     }
    // } @catch (NSException *e) {
    //     fprintf(stderr, "Failed to fetch aerospace workspace: %s\n", e.reason.UTF8String);
    // }

    NSString *pdfCacheDir = @"/tmp/skim_pdfs";
    BOOL isDir;
    if ([fm fileExistsAtPath:pdfCacheDir isDirectory:&isDir] && isDir) {
        NSArray *contents = [fm contentsOfDirectoryAtPath:pdfCacheDir error:nil];
        NSTimeInterval currentTime = [[NSDate date] timeIntervalSince1970];

        for (NSString *item in contents) {
            NSString *fullPath = [pdfCacheDir stringByAppendingPathComponent:item];
            if ([fm fileExistsAtPath:fullPath isDirectory:&isDir] && isDir) {

                NSScanner *scanner = [NSScanner scannerWithString:item];
                NSInteger timestamp = 0;
                if ([scanner scanInteger:&timestamp] && [scanner isAtEnd]) {
                    NSTimeInterval age = currentTime - (NSTimeInterval)timestamp;

                    if (age > 86400.0) [fm removeItemAtPath:fullPath error:nil];
                }
            }
        }
    }

    return 0;
}
