#import "skimUtils.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        NSString *command = [NSString stringWithUTF8String:argv[1]];
        NSString *arguments = [NSString stringWithUTF8String:argv[2]];

        if ([command isEqualToString:@"search"]) return skimSearch(arguments);
        if ([command isEqualToString:@"moveTab"]) return moveTab(atoi(argv[2]));
        if ([command isEqualToString:@"switchTab"]) return switchTab(atoi(argv[2]));
        if ([command isEqualToString:@"switchFocus"]) return switchFocus(arguments);
        if ([command isEqualToString:@"openRelated"]) return openRelated(arguments);
        if ([command isEqualToString:@"duplicateTab"]) return duplicateTab();
        if ([command isEqualToString:@"cleanDuplicates"]) return cleanDuplicates();
        if ([command isEqualToString:@"reopenLastClosed"]) return reopenLastClosed();

        return 1;
    }
}
