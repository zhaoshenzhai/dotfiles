#import "skimUtils.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        if (argc < 2) {
            fprintf(stderr, "Usage: %s <command> [args...]\n", argv[0]);
            fprintf(stderr, "Commands:\n");
            fprintf(stderr, "  tab <1-9>\n");
            fprintf(stderr, "  duplicate\n");
            return 1;
        }

        NSString *command = [NSString stringWithUTF8String:argv[1]];

        if ([command isEqualToString:@"tab"]) {
            if (argc != 3) {
                fprintf(stderr, "Usage: %s tab <1-9>\n", argv[0]);
                return 1;
            }
            int targetTab = atoi(argv[2]);
            if (targetTab < 1 || targetTab > 9) return 1;
            return switchTab(targetTab);
        }
        else if ([command isEqualToString:@"duplicate"]) {
            return duplicateTab();
        }
        else {
            fprintf(stderr, "Unknown command: %s\n", argv[1]);
            return 1;
        }
    }
    return 0;
}
