#import "commonUtils.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        EnsureSystemPath();
        NSString *windowID = nil;

        if (argc >= 2) {
            windowID = [NSString stringWithUTF8String:argv[1]];
        } else {
            NSString *focusedID = AerospaceOutput(@[@"list-windows", @"--focused", @"--format", @"%{window-id}"]);
            windowID = [focusedID stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        }

        if (windowID && windowID.length > 0) {
            AerospaceClose(windowID);
        }
    }
    return 0;
}
