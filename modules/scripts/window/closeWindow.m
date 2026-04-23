#import "commonUtils.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        EnsureSystemPath();
        if (argc < 2) return 1;

        NSString *windowID = [NSString stringWithUTF8String:argv[1]];
        CloseWindow(windowID);
    }
    return 0;
}
