#import "skimUtils.h"
#import <ScriptingBridge/ScriptingBridge.h>
#import <CoreGraphics/CoreGraphics.h>

void logToFile(NSString *format, ...) {
    va_list args;
    va_start(args, format);
    NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);

    NSString *logPath = @"/tmp/skim_search_debug.log";
    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:logPath]) [fm createFileAtPath:logPath contents:nil attributes:nil];

    NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:logPath];
    [fileHandle seekToEndOfFile];
    NSString *logLine = [NSString stringWithFormat:@"[%@] %@\n", [NSDate date], message];
    [fileHandle writeData:[logLine dataUsingEncoding:NSUTF8StringEncoding]];
    [fileHandle closeFile];
}

int skimSearch(NSString *action) {
    @autoreleasepool {
        logToFile(@"=== Starting skimSearch: %@ ===", action);

        pid_t pid = GetSkimPID();
        if (pid == 0) return 1;

        SBApplication *skim = GetSkimSBApp();
        if (!skim || ![skim isRunning]) return 1;

        NSArray *documents = [skim valueForKey:@"documents"];
        if (documents && documents.count > 0) {
            id frontDoc = documents.firstObject;

            // 1. Precise Selection Reset
            @try {
                id currentPage = [frontDoc valueForKey:@"currentPage"];
                if (currentPage) {
                    id textObj = [currentPage valueForKey:@"text"];
                    if (textObj) {
                        NSArray *characters = [textObj valueForKey:@"characters"];
                        if (characters && characters.count > 0) {
                            [frontDoc setValue:[characters objectAtIndex:0] forKey:@"selection"];
                        } else {
                            @try { [frontDoc setValue:nil forKey:@"selection"]; } @catch(NSException*e){}
                        }
                    }
                }
            } @catch (NSException *e) {}
        }

        // 2. Route Keystrokes
        if ([action isEqualToString:@"start"]) {
            // EXTREMELY IMPORTANT:
            // We exit immediately. We let Karabiner send Cmd+Opt+F natively.
            // This preserves the macOS type-ahead buffer so fast typing is never lost.
            logToFile(@"Anchor set. Exiting to let macOS handle type-ahead buffer.");
            return 0;
        }

        // Add a micro-delay for next/prev to ensure anchor is locked before searching
        usleep(15000); // 15ms

        CGKeyCode keyCode = 0;
        if ([action isEqualToString:@"next"]) {
            keyCode = (CGKeyCode)5; // 'g'
        } else if ([action isEqualToString:@"prev"]) {
            keyCode = (CGKeyCode)4; // 'h'
        } else {
            return 1;
        }

        // 3. Inject Keystroke DIRECTLY into Skim for n/N
        CGEventSourceRef source = CGEventSourceCreate(kCGEventSourceStatePrivate);
        CGEventRef keyDown = CGEventCreateKeyboardEvent(source, keyCode, true);
        CGEventRef keyUp = CGEventCreateKeyboardEvent(source, keyCode, false);

        CGEventFlags flags = kCGEventFlagMaskCommand | kCGEventFlagMaskAlternate;
        CGEventSetFlags(keyDown, flags);
        CGEventSetFlags(keyUp, flags);

        CGEventPostToPid(pid, keyDown);
        CGEventPostToPid(pid, keyUp);

        CFRelease(keyDown);
        CFRelease(keyUp);
        CFRelease(source);
    }
    return 0;
}
