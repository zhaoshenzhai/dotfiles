#import "skimUtils.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        NSString *command = [NSString stringWithUTF8String:argv[1]];

        if ([command isEqualToString:@"search"]) return skimSearch([NSString stringWithUTF8String:argv[2]]);
        if ([command isEqualToString:@"moveTab"]) return moveTab(atoi(argv[2]));
        if ([command isEqualToString:@"switchTab"]) return switchTab(atoi(argv[2]));
        if ([command isEqualToString:@"exportTex"]) return exportTex();
        if ([command isEqualToString:@"switchFocus"]) return switchFocus([NSString stringWithUTF8String:argv[2]]);
        if ([command isEqualToString:@"openRelated"]) return openRelated([NSString stringWithUTF8String:argv[2]]);
        if ([command isEqualToString:@"duplicateTab"]) return duplicateTab();
        if ([command isEqualToString:@"cleanDuplicates"]) return cleanDuplicates();
        if ([command isEqualToString:@"reopenLastClosed"]) return reopenLastClosed();

        return 1;
    }
}
