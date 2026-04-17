#import "skimUtils.h"

int openRelated(NSString *extension) {
    NSString *rawPath = GetDocumentPathOfFrontmostApp();
    if (!rawPath) return 0;

    NSString *canonicalPath = ResolveCanonicalDocumentPath(rawPath);
    NSString *targetPath = [[canonicalPath stringByDeletingPathExtension] stringByAppendingPathExtension:extension];

    if ([[NSFileManager defaultManager] fileExistsAtPath:targetPath]) {
        NSString *userName = NSUserName();
        NSString *launcherPath = [NSString stringWithFormat:@"/etc/profiles/per-user/%@/bin/launcher", userName];

        NSTask *task = [[NSTask alloc] init];
        [task setLaunchPath:launcherPath];
        [task setArguments:@[targetPath]];

        [task setStandardOutput:[NSFileHandle fileHandleWithNullDevice]];
        [task setStandardError:[NSFileHandle fileHandleWithNullDevice]];

        NSError *error = nil;
        if (![task launchAndReturnError:&error]) {
            fprintf(stderr, "Failed to execute launcher: %s\n", error.localizedDescription.UTF8String);
            return 1;
        }
    }

    return 0;
}
