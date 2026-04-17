#import "skimUtils.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        if (argc < 2) {
            fprintf(stderr, "Usage: %s <command> [args...]\n", argv[0]);
            return 1;
        }

        NSString *command = [NSString stringWithUTF8String:argv[1]];

        if ([command isEqualToString:@"switchTab"]) {
            if (argc != 3) {
                fprintf(stderr, "Usage: %s switchTab <1-9>\n", argv[0]);
                return 1;
            }
            int targetTab = atoi(argv[2]);
            if (targetTab < 1 || targetTab > 9) return 1;
            return switchTab(targetTab);
        }
        else if ([command isEqualToString:@"duplicateTab"]) {
            return duplicateTab();
        }
        else if ([command isEqualToString:@"cleanDuplicates"]) {
            return cleanDuplicates();
        }
        else if ([command isEqualToString:@"openRelated"]) {
            if (argc != 3) {
                fprintf(stderr, "Usage: %s openRelated <extension>\n", argv[0]);
                return 1;
            }
            NSString *ext = [NSString stringWithUTF8String:argv[2]];
            return openRelated(ext);
        }
        else {
            fprintf(stderr, "Unknown command: %s\n", argv[1]);
            return 1;
        }
    }
    return 0;
}
