#import "skimUtils.h"

// High-speed wrapper for AeroSpace CLI
static NSString *Aero(NSArray *args) {
    NSTask *task = [[NSTask alloc] init];
    // Nix-darwin standard path
    [task setLaunchPath:@"/run/current-system/sw/bin/aerospace"];
    [task setArguments:args];

    NSPipe *pipe = [NSPipe pipe];
    [task setStandardOutput:pipe];
    [task setStandardError:[NSFileHandle fileHandleWithNullDevice]];

    if (@available(macOS 10.13, *)) {
        [task launchAndReturnError:nil];
    } else {
        [task launch];
    }

    NSData *data = [[pipe fileHandleForReading] readDataToEndOfFile];
    [task waitUntilExit];

    return [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]
            stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

static NSString *GetSkimMemoryPath(void) {
    NSString *ws = Aero(@[@"list-workspaces", @"--focused"]);
    if (!ws || ws.length == 0) return nil;

    NSString *dir = @"/tmp/aerospace_skim_tabs";
    [[NSFileManager defaultManager] createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil];
    return [dir stringByAppendingFormat:@"/workspace_%@.txt", ws];
}

int recordSkim(NSString *windowId) {
    NSString *path = GetSkimMemoryPath();
    if (path && windowId) {
        [windowId writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:nil];
    }
    return 0;
}

int switchFocus(NSString *direction) {
    @autoreleasepool {
        // One-shot fetch of all window data to minimize process forking
        NSString *raw = Aero(@[@"list-windows", @"--workspace", @"focused", @"--format", @"%{window-id}|%{app-bundle-id}|%{window-title}"]);
        NSArray *lines = [raw componentsSeparatedByString:@"\n"];

        NSString *focusedId = Aero(@[@"list-windows", @"--focused", @"--format", @"%{window-id}"]);
        NSString *focusedBundle = Aero(@[@"list-windows", @"--focused", @"--format", @"%{app-bundle-id}"]);

        NSString *alacrittyId = nil;
        BOOL hasNvim = NO;
        int skimCount = 0;

        for (NSString *line in lines) {
            NSArray *p = [line componentsSeparatedByString:@"|"];
            if (p.count < 3) continue;

            if ([p[1] containsString:@"alacritty"]) {
                alacrittyId = p[0];
                if ([[p[2] lowercaseString] containsString:@"nvim"]) hasNvim = YES;
            }
            if ([p[1] isEqualToString:@"net.sourceforge.skim-app.skim"]) skimCount++;
        }

        // Logic for the Nvim + Skim "IDE" layout
        if (alacrittyId && hasNvim && skimCount >= 1) {
            if ([focusedBundle isEqualToString:@"net.sourceforge.skim-app.skim"]) {
                recordSkim(focusedId);
                if ([direction isEqualToString:@"up"]) {
                    Aero(@[@"focus", @"--window-id", alacrittyId]);
                    return 0;
                }
            } else if ([focusedBundle.lowercaseString containsString:@"alacritty"]) {
                if ([direction isEqualToString:@"down"]) {
                    NSString *mem = [NSString stringWithContentsOfFile:GetSkimMemoryPath() encoding:NSUTF8StringEncoding error:nil];
                    NSString *target = (mem && [raw containsString:mem]) ? mem : nil;

                    if (!target) {
                        for (NSString *l in lines) {
                            if ([l containsString:@"net.sourceforge.skim-app.skim"]) {
                                target = [[l componentsSeparatedByString:@"|"] firstObject];
                                break;
                            }
                        }
                    }
                    if (target) Aero(@[@"focus", @"--window-id", target]);
                    return 0;
                }
            }
        }

        // Standard fallback
        Aero(@[@"focus", direction]);
    }
    return 0;
}

int enforceSkim(void) {
    @autoreleasepool {
        // Reuse the same logic to grab the Alacritty ID and check for Nvim/Skim presence
        NSString *raw = Aero(@[@"list-windows", @"--workspace", @"focused", @"--format", @"%{window-id}|%{app-bundle-id}|%{window-title}"]);
        NSArray *lines = [raw componentsSeparatedByString:@"\n"];

        NSString *alacrittyId = nil;
        BOOL nvim = NO; int skim = 0;

        for (NSString *line in lines) {
            NSArray *p = [line componentsSeparatedByString:@"|"];
            if (p.count < 3) continue;
            if ([p[1] containsString:@"alacritty"]) {
                alacrittyId = p[0];
                if ([[p[2] lowercaseString] containsString:@"nvim"]) nvim = YES;
            }
            if ([p[1] isEqualToString:@"net.sourceforge.skim-app.skim"]) skim++;
        }

        if (alacrittyId && nvim && skim >= 1) {
            Aero(@[@"focus", @"--window-id", alacrittyId]);
            Aero(@[@"layout", @"v_accordion"]);
            Aero(@[@"move", @"up"]);
            Aero(@[@"focus", @"--window-id", alacrittyId]);
        }
    }
    return 0;
}
