#import "skimUtils.h"

int openRelated(NSString *extension) {
    @autoreleasepool {
        NSString *rawPath = GetDocumentPathOfFrontmostApp();
        if (!rawPath) return 0;

        NSString *canonicalPath = ResolveCanonicalDocumentPath(rawPath);
        NSString *targetPath = [[canonicalPath stringByDeletingPathExtension] stringByAppendingPathExtension:extension];

        if ([[NSFileManager defaultManager] fileExistsAtPath:targetPath]) {
            RunLauncher(targetPath);
        }
    }
    return 0;
}
