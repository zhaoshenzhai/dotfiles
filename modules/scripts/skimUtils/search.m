#import "skimUtils.h"

int skimSearch(NSString *action) {
    @autoreleasepool {
        pid_t pid = GetSkimPID();
        if (pid == 0) return 1;

        SBApplication *skim = GetSkimSBApp();
        if (!skim || ![skim isRunning]) return 1;

        NSArray *documents = [skim valueForKey:@"documents"];
        if (documents && documents.count > 0) {
            id frontDoc = documents.firstObject;

            @try {
                id currentPage = [frontDoc valueForKey:@"currentPage"];
                if (currentPage) {
                    id textObj = [currentPage valueForKey:@"text"];
                    NSArray *characters = [textObj valueForKey:@"characters"];
                    if (characters && characters.count > 0) {
                        [frontDoc setValue:[characters objectAtIndex:0] forKey:@"selection"];
                    } else {
                        [frontDoc setValue:nil forKey:@"selection"];
                    }
                }
            } @catch (NSException *e) {}
        }

        if ([action isEqualToString:@"start"]) return 0;

        usleep(15000);

        CGKeyCode keyCode = 0;
        if ([action isEqualToString:@"next"]) {
            keyCode = (CGKeyCode)5;
        } else if ([action isEqualToString:@"prev"]) {
            keyCode = (CGKeyCode)4;
        } else {
            return 1;
        }

        CGEventFlags flags = kCGEventFlagMaskCommand | kCGEventFlagMaskAlternate;
        PostKeystrokeToPID(pid, keyCode, flags);
    }
    return 0;
}
