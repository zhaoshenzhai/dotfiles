#import "commonUtils.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        if (argc < 2) return 0;

        NSFileManager *fm = [NSFileManager defaultManager];

        for (int i = 1; i < argc; i++) {
            NSString *file = [NSString stringWithUTF8String:argv[i]];

            if ([fm fileExistsAtPath:file] && [[file pathExtension] isEqualToString:@"pdf"]) {
                printf("%sCompressing: %s%s\r", YELLOW, file.UTF8String, NC);
                fflush(stdout);

                NSString *tmpFile = [file stringByAppendingPathExtension:@"tmp"];

                NSArray *gsArgs = @[
                    @"-sDEVICE=pdfwrite",
                    @"-dCompatibilityLevel=1.5",
                    @"-dPDFSETTINGS=/printer",
                    @"-dNOPAUSE",
                    @"-dQUIET",
                    @"-dBATCH",
                    [NSString stringWithFormat:@"-sOutputFile=%@", tmpFile],
                    file
                ];

                RunCommandWait(@"/usr/bin/env", [@[@"gs"] arrayByAddingObjectsFromArray:gsArgs]);

                NSDictionary *oldAttrs = [fm attributesOfItemAtPath:file error:nil];
                NSDictionary *newAttrs = [fm attributesOfItemAtPath:tmpFile error:nil];

                long long oldSize = [oldAttrs fileSize];
                long long newSize = [newAttrs fileSize];

                printf("\033[0K\r");

                if (newSize >= oldSize || newSize == 0) {
                    [fm removeItemAtPath:tmpFile error:nil];
                    printf("%s[No changes] %s%s\n", CYAN, file.UTF8String, NC);
                } else {
                    NSString *oldSizeHuman = [NSByteCountFormatter stringFromByteCount:oldSize countStyle:NSByteCountFormatterCountStyleFile];
                    NSString *newSizeHuman = [NSByteCountFormatter stringFromByteCount:newSize countStyle:NSByteCountFormatterCountStyleFile];

                    printf("%s[%s  ->  %s] %s%s\n", GREEN, oldSizeHuman.UTF8String, newSizeHuman.UTF8String, file.UTF8String, NC);

                    NSString *bakFile = [[file stringByDeletingLastPathComponent] stringByAppendingPathComponent:[NSString stringWithFormat:@"bak_%@", [file lastPathComponent]]];

                    [fm copyItemAtPath:file toPath:bakFile error:nil];
                    [fm removeItemAtPath:file error:nil];
                    [fm moveItemAtPath:tmpFile toPath:file error:nil];
                }
            }
        }
    }
    return 0;
}
