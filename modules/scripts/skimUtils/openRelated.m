#import "skimUtils.h"
#import <unistd.h>

int openRelated(NSString *extension) {
    @autoreleasepool {
        NSString *rawPath = GetDocumentPathOfFrontmostApp();
        if (!rawPath) return 0;

        NSString *canonicalPath = ResolveCanonicalDocumentPath(rawPath);
        NSString *targetPath = [[canonicalPath stringByDeletingPathExtension] stringByAppendingPathExtension:extension];

        if (access(targetPath.UTF8String, F_OK) == 0) RunLauncher(targetPath);
    }
    return 0;
}
