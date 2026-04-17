#import "skimUtils.h"
#import <ScriptingBridge/ScriptingBridge.h>
#import <CoreGraphics/CoreGraphics.h>

// Lightweight logger
void logToFile(NSString *format, ...) {
    va_list args;
    va_start(args, format);
    NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);

    NSString *logPath = @"/tmp/skim_search_debug.log";
    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:logPath]) {
        [fm createFileAtPath:logPath contents:nil attributes:nil];
    }

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
        if (pid == 0) {
            logToFile(@"Error: Could not find Skim PID.");
            return 1;
        }

        SBApplication *skim = GetSkimSBApp();
        if (!skim || ![skim isRunning]) {
            logToFile(@"Error: Skim SBApplication not running.");
            return 1;
        }

        NSArray *documents = [skim valueForKey:@"documents"];
        if (documents && documents.count > 0) {
            id frontDoc = documents.firstObject;

            // 1. Precise Selection Reset
            // We drill down into the page's rich text array to select ONLY the first character.
            @try {
                id currentPage = [frontDoc valueForKey:@"currentPage"];
                if (currentPage) {
                    id textObj = [currentPage valueForKey:@"text"];
                    if (textObj) {
                        NSArray *characters = [textObj valueForKey:@"characters"];
                        if (characters && characters.count > 0) {
                            id firstChar = [characters objectAtIndex:0];
                            [frontDoc setValue:firstChar forKey:@"selection"];
                            logToFile(@"Successfully anchored search to character 1 via KVC.");
                        } else {
                            logToFile(@"Warning: No text found on page. Attempting to clear selection.");
                            @try { [frontDoc setValue:nil forKey:@"selection"]; } @catch(NSException*e){}
                        }
                    }
                }
            } @catch (NSException *e) {
                logToFile(@"Failed to reset selection: %@ - %@", e.name, e.reason);
            }
        }

        // Give Skim's UI thread a tiny moment to process the anchor
        // before hammering it with the search command, preventing dropped keys.
        usleep(25000); // 25ms

        // 2. Determine target keystroke
        CGKeyCode keyCode = 0;
        if ([action isEqualToString:@"start"]) {
            keyCode = (CGKeyCode)3; // 'f'
        } else if ([action isEqualToString:@"next"]) {
            keyCode = (CGKeyCode)5; // 'g'
        } else if ([action isEqualToString:@"prev"]) {
            keyCode = (CGKeyCode)4; // 'h'
        } else {
            logToFile(@"Error: Unknown action '%@'. Use: start, next, or prev", action);
            return 1;
        }

        logToFile(@"Injecting keycode %d (Cmd+Opt) directly to PID %d", keyCode, pid);

        // 3. Inject Keystroke DIRECTLY into Skim
        // kCGEventSourceStatePrivate ensures that if you are holding Shift (for N),
        // it doesn't accidentally combine into Cmd+Opt+Shift+h.
        CGEventSourceRef source = CGEventSourceCreate(kCGEventSourceStatePrivate);

        CGEventRef keyDown = CGEventCreateKeyboardEvent(source, keyCode, true);
        CGEventRef keyUp = CGEventCreateKeyboardEvent(source, keyCode, false);

        CGEventFlags flags = kCGEventFlagMaskCommand | kCGEventFlagMaskAlternate;
        CGEventSetFlags(keyDown, flags);
        CGEventSetFlags(keyUp, flags);

        // Send directly to the process identifier
        CGEventPostToPid(pid, keyDown);
        CGEventPostToPid(pid, keyUp);

        CFRelease(keyDown);
        CFRelease(keyUp);
        CFRelease(source);

        logToFile(@"Keystroke injection complete.");
    }
    return 0;
}
