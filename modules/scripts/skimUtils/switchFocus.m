#import "skimUtils.h"

static NSString *const kMemoryDir    = @"/tmp/aerospace_skim_tabs";
static NSString *const kSkimBundleID = @"net.sourceforge.skim-app.skim";
static NSString *const kAlacritty    = @"alacritty";

/// Run `aerospace <args>` and return trimmed stdout, or @"" on failure.
static NSString *Aerospace(NSArray<NSString *> *args) {
    NSTask *task    = [[NSTask alloc] init];
    task.launchPath = @"/usr/bin/env";
    task.arguments  = [@[@"aerospace"] arrayByAddingObjectsFromArray:args];

    NSPipe *pipe        = [NSPipe pipe];
    task.standardOutput = pipe;
    task.standardError  = [NSFileHandle fileHandleWithNullDevice];

    NSError *err = nil;
    if (![task launchAndReturnError:&err]) return @"";
    [task waitUntilExit];

    NSData   *data = [pipe.fileHandleForReading readDataToEndOfFile];
    NSString *out  = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    return out ? [out stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] : @"";
}

/// Run `aerospace <args>`, discarding output (fire-and-wait).
static void AerospaceRun(NSArray<NSString *> *args) {
    NSTask *task    = [[NSTask alloc] init];
    task.launchPath = @"/usr/bin/env";
    task.arguments  = [@[@"aerospace"] arrayByAddingObjectsFromArray:args];

    task.standardOutput = [NSFileHandle fileHandleWithNullDevice];
    task.standardError  = [NSFileHandle fileHandleWithNullDevice];

    NSError *err = nil;
    if ([task launchAndReturnError:&err]) [task waitUntilExit];
}

/// Split `str` on newlines, drop blank lines, return trimmed lines.
static NSArray<NSString *> *Lines(NSString *str) {
    NSArray<NSString *> *raw = [str componentsSeparatedByString:@"\n"];
    NSMutableArray<NSString *> *result = [NSMutableArray arrayWithCapacity:raw.count];
    NSCharacterSet *ws = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    for (NSString *line in raw) {
        NSString *t = [line stringByTrimmingCharactersInSet:ws];
        if (t.length) [result addObject:t];
    }
    return result;
}

/// Split `line` on `|`, returning parts (never nil elements).
static NSArray<NSString *> *Split(NSString *line) {
    return [line componentsSeparatedByString:@"|"];
}

/// Return the memory-file path for the given workspace.
static NSString *MemoryFile(NSString *workspace) {
    return [NSString stringWithFormat:@"%@/workspace_%@.txt", kMemoryDir, workspace];
}

/// Ensure the memory directory exists.
static void EnsureMemoryDir(void) {
    [[NSFileManager defaultManager] createDirectoryAtPath:kMemoryDir withIntermediateDirectories:YES attributes:nil error:nil];
}

/// Read a saved window-id from disk; returns nil if missing or empty.
static NSString *ReadMemoryFile(NSString *path) {
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) return nil;
    NSString *content = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    NSString *trimmed = [content stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
    return trimmed.length ? trimmed : nil;
}

/// Write `windowId` to `path`.
static BOOL WriteMemoryFile(NSString *path, NSString *windowId) {
    NSError *err = nil;
    [windowId writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:&err];
    return err == nil;
}

int switchFocus(NSString *direction) {

    // ── 1. Current workspace (1 call) ────────────────────────────────────────
    NSString *workspace = Aerospace(@[@"list-workspaces", @"--focused"]);
    if (!workspace.length) return 1;

    EnsureMemoryDir();
    NSString *memFile = MemoryFile(workspace);

    // ── 2. All windows in the focused workspace (1 call, combined format) ────
    //    Format: <window-id>|<app-name>|<window-title>|<app-bundle-id>
    NSArray<NSString *> *allWindows =
        Lines(Aerospace(@[@"list-windows", @"--workspace", @"focused",
                          @"--format", @"%{window-id}|%{app-name}|%{window-title}|%{app-bundle-id}"]));

    NSInteger alacrittyCount     = 0;
    NSInteger alacrittyNvimCount = 0;
    NSMutableArray<NSString *> *skimWindowIDs = [NSMutableArray array];

    for (NSString *line in allWindows) {
        NSArray<NSString *> *p = Split(line);
        if (p.count < 4) continue;

        NSString *appName  = p[1].lowercaseString;
        NSString *title    = p[2].lowercaseString;
        NSString *bundleID = p[3];

        if ([appName hasPrefix:kAlacritty]) {
            alacrittyCount++;
            if ([title containsString:@"nvim"]) alacrittyNvimCount++;
        }

        if ([bundleID isEqualToString:kSkimBundleID]) {
            [skimWindowIDs addObject:p[0]]; // window-id
        }
    }

    NSInteger skimCount = skimWindowIDs.count;

    // ── 3. Guard: conditions not met → normal aerospace focus ─────────────────
    if (alacrittyCount != 1 || alacrittyNvimCount != 1 || skimCount <= 1) {
        AerospaceRun(@[@"focus", direction]);
        return 0;
    }

    // ── 4. Focused window (1 call, combined format) ───────────────────────────
    //    Format: <window-id>|<app-name>|<app-bundle-id>
    NSString *focusedRaw = Aerospace(@[@"list-windows", @"--focused", @"--format", @"%{window-id}|%{app-name}|%{app-bundle-id}"]);

    NSArray<NSString *> *fp = Split(focusedRaw);
    if (fp.count < 3) return 1;

    NSString *currentID     = fp[0];
    NSString *currentApp    = fp[1].lowercaseString;
    NSString *currentBundle = fp[2];

    // ── 5a. Focused window is Alacritty ──────────────────────────────────────
    if ([currentApp hasPrefix:kAlacritty]) {
        if ([direction isEqualToString:@"up"]) {
            return 0; // already at the top
        }

        // direction == "down" → focus remembered (or first) Skim window
        NSString *targetSkim = nil;

        NSString *savedID = ReadMemoryFile(memFile);
        if (savedID && [skimWindowIDs containsObject:savedID]) {
            targetSkim = savedID;
        }

        if (!targetSkim) targetSkim = skimWindowIDs.firstObject;

        if (targetSkim) AerospaceRun(@[@"focus", @"--window-id", targetSkim]);
        return 0;
    }

    // ── 5b. Focused window is Skim ───────────────────────────────────────────
    if ([currentBundle isEqualToString:kSkimBundleID]) {
        // Always persist the currently-focused Skim tab
        WriteMemoryFile(memFile, currentID);

        if ([direction isEqualToString:@"down"]) {
            return 0; // already at the bottom
        }

        // direction == "up" → focus the single Alacritty window
        for (NSString *line in allWindows) {
            NSArray<NSString *> *p = Split(line);
            if (p.count >= 2 && [p[1].lowercaseString hasPrefix:kAlacritty]) {
                AerospaceRun(@[@"focus", @"--window-id", p[0]]);
                break;
            }
        }
        return 0;
    }

    // ── 5c. Some other app is focused → normal aerospace focus ────────────────
    AerospaceRun(@[@"focus", direction]);
    return 0;
}

int recordSkim(NSString *windowId) {
    if (!windowId.length) return 1;

    // 1 call: current workspace
    NSString *workspace = Aerospace(@[@"list-workspaces", @"--focused"]);
    if (!workspace.length) return 1;

    EnsureMemoryDir();
    return WriteMemoryFile(MemoryFile(workspace), windowId) ? 0 : 1;
}
