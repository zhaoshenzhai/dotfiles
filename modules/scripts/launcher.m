#import "commonUtils.h"

static NSString *const kFdPath = @FD_PATH;
static NSString *const kFzfPath = @FZF_PATH;
static NSString *const kCacheDir = @"/Users/zhao/.cache/launcher";

static const char *excludedPatterns[] = { ".git", "*.old", "*.png", "*.jpg", "*.tar.gz", "*.zip", "*.synctex.gz", "*.svg" };

static void UpdateRecentFiles(NSString *selected) {
    if ([selected containsString:@"Projects/_attic/notes/"] &&
       ([selected hasSuffix:@".tex"] || [selected hasSuffix:@".key"] || [selected hasSuffix:@".dat"])) {
        return;
    }

    NSString *recentFile = [kCacheDir stringByAppendingPathComponent:@"recent.txt"];
    NSString *content = [NSString stringWithContentsOfFile:recentFile encoding:NSUTF8StringEncoding error:nil] ?: @"";
    NSArray *lines = [content componentsSeparatedByString:@"\n"];

    NSMutableArray *newLines = [NSMutableArray arrayWithCapacity:100];
    [newLines addObject:selected];

    for (NSString *line in lines) {
        if (newLines.count >= 100) break;
        if (line.length > 0 && ![line isEqualToString:selected]) [newLines addObject:line];
    }

    NSString *newContent = [[newLines componentsJoinedByString:@"\n"] stringByAppendingString:@"\n"];
    [newContent writeToFile:recentFile atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

static NSString *FormatFilePath(NSString *filePath) {
    if ([filePath hasPrefix:@"Projects/_attic/notes/"] && [filePath hasSuffix:@".pdf"]) {
        NSArray *components = [filePath componentsSeparatedByString:@"/"];
        if (components.count >= 4) {
            NSString *idStr = components[3];
            NSString *keywordsPath = [NSString stringWithFormat:@"%@/Projects/_attic/notes/%@/%@.key", kBaseDir, idStr, idStr];

            if ([[NSFileManager defaultManager] fileExistsAtPath:keywordsPath]) {
                NSError *err;
                NSString *keywords = [NSString stringWithContentsOfFile:keywordsPath encoding:NSUTF8StringEncoding error:&err];
                if (!err && keywords.length > 0) {
                    keywords = [keywords stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                    return [NSString stringWithFormat:@"Projects/attic_%@/[%@].pdf\t%@", idStr, keywords, filePath];
                }
            }
        }
    }
    return [NSString stringWithFormat:@"%@\t%@", filePath, filePath];
}

static void UpdateCache(void) {
    [[NSFileManager defaultManager] changeCurrentDirectoryPath:kBaseDir];

    NSString *recentFile = [kCacheDir stringByAppendingPathComponent:@"recent.txt"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:recentFile]) {
        NSString *recentStr = [NSString stringWithContentsOfFile:recentFile encoding:NSUTF8StringEncoding error:nil];
        if (recentStr.length > 0) {
            NSArray *lines = [recentStr componentsSeparatedByString:@"\n"];
            NSMutableArray *validRecentLines = [NSMutableArray arrayWithCapacity:lines.count];

            for (NSString *line in lines) {
                if (line.length == 0) continue;
                NSArray *parts = [line componentsSeparatedByString:@"\t"];
                if ([[NSFileManager defaultManager] fileExistsAtPath:[kBaseDir stringByAppendingPathComponent:parts.lastObject]]) {
                    [validRecentLines addObject:line];
                }
            }

            if (validRecentLines.count > 0) {
                NSString *newRecent = [[validRecentLines componentsJoinedByString:@"\n"] stringByAppendingString:@"\n"];
                [newRecent writeToFile:recentFile atomically:YES encoding:NSUTF8StringEncoding error:nil];
            }
        }
    }

    NSMutableArray *fdArgs = [NSMutableArray arrayWithObjects:@"-L", @"--type", @"f", @"--hidden", @"--no-ignore", nil];
    for (int i = 0; i < sizeof(excludedPatterns) / sizeof(excludedPatterns[0]); i++) {
        [fdArgs addObject:@"--exclude"];
        [fdArgs addObject:[NSString stringWithUTF8String:excludedPatterns[i]]];
    }
    [fdArgs addObjectsFromArray:@[@".", @"Documents", @"Dotfiles", @"Projects"]];

    NSString *rawFiles = RunCommandOutput(kFdPath, fdArgs);
    NSArray *lines = [rawFiles componentsSeparatedByString:@"\n"];

    NSMutableSet *seen = [NSMutableSet setWithCapacity:lines.count];
    NSMutableString *cacheOutput = [NSMutableString stringWithCapacity:rawFiles.length];

    for (NSString *line in lines) {
        if (line.length == 0) continue;

        if ([line hasPrefix:@"Projects/_attic/notes/"] &&
            ([line hasSuffix:@".tex"] || [line hasSuffix:@".key"] || [line hasSuffix:@".dat"])) {
            continue;
        }

        if (![seen containsObject:line]) {
            [seen addObject:line];
            [cacheOutput appendFormat:@"%@\n", FormatFilePath(line)];
        }
    }

    NSString *cacheFile = [kCacheDir stringByAppendingPathComponent:@"files.txt"];
    [cacheOutput writeToFile:cacheFile atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

static NSString *SelectFiles(void) {
    NSString *cacheFile = [kCacheDir stringByAppendingPathComponent:@"files.txt"];
    NSString *recentFile = [kCacheDir stringByAppendingPathComponent:@"recent.txt"];
    NSMutableString *combined = [NSMutableString string];

    if ([[NSFileManager defaultManager] fileExistsAtPath:recentFile]) {
        NSString *recentStr = [NSString stringWithContentsOfFile:recentFile encoding:NSUTF8StringEncoding error:nil];
        for (NSString *line in [recentStr componentsSeparatedByString:@"\n"]) {
            if (line.length == 0) continue;
            [combined appendFormat:@"%@\n", [line containsString:@"\t"] ? line : FormatFilePath(line)];
        }
    }
    if ([[NSFileManager defaultManager] fileExistsAtPath:cacheFile]) {
        NSString *cacheStr = [NSString stringWithContentsOfFile:cacheFile encoding:NSUTF8StringEncoding error:nil];
        if (cacheStr.length > 0) {
            [combined appendString:cacheStr];
            if (![cacheStr hasSuffix:@"\n"]) [combined appendString:@"\n"];
        }
    }

    NSString *tmpList = @"/tmp/launcher_fzf_in.txt";
    [combined writeToFile:tmpList atomically:YES encoding:NSUTF8StringEncoding error:nil];
    setenv("FZF_DEFAULT_OPTS", "--color='bg+:-1,gutter:-1,pointer:#98c379'", 1);

    NSString *fzfCmd = [NSString stringWithFormat:@"cat %@ | awk '!seen[$0]++' | %@ --reverse --info=hidden --delimiter '\t' --with-nth 1 --tiebreak=index --pointer='➜'", tmpList, kFzfPath];

    FILE *fp = popen(fzfCmd.UTF8String, "r");
    if (!fp) return @"";

    char path[1024];
    NSString *selected = @"";
    if (fgets(path, sizeof(path)-1, fp) != NULL) {
        TrimEnd(path);
        selected = [NSString stringWithUTF8String:path];
    }
    pclose(fp);
    return selected;
}

static void Launch(NSString *selected) {
    NSArray *parts = [selected componentsSeparatedByString:@"\t"];
    if (parts.count < 2) return;

    NSString *fullPath = [kBaseDir stringByAppendingPathComponent:parts[1]];

    if ([fullPath hasSuffix:@".pdf"]) {
        NSString *filename = fullPath.lastPathComponent;
        NSString *skims = AerospaceOutput(@[@"list-windows", @"--all", @"--format", @"%{app-name}|%{window-title}"]);
        BOOL exists = [skims containsString:[NSString stringWithFormat:@"Skim|%@", filename]];

        NSURL *fileURL;
        if (exists) {
            NSString *uniqueDir = [NSString stringWithFormat:@"/tmp/skim_pdfs/%.0f", [[NSDate date] timeIntervalSince1970]];
            EnsureDirectoryExists(uniqueDir.UTF8String);

            NSString *copyPath = [uniqueDir stringByAppendingPathComponent:filename];
            [[NSFileManager defaultManager] copyItemAtPath:fullPath toPath:copyPath error:nil];
            [fullPath writeToFile:[copyPath stringByAppendingString:@".orig"] atomically:YES encoding:NSUTF8StringEncoding error:nil];
            fileURL = [NSURL fileURLWithPath:copyPath];
        } else {
            fileURL = [NSURL fileURLWithPath:fullPath];
        }

        NSURL *skimURL = [[NSWorkspace sharedWorkspace] URLForApplicationWithBundleIdentifier:@"net.sourceforge.skim-app.skim"];
        if (skimURL) {
            [[NSWorkspace sharedWorkspace] openURLs:@[fileURL]
                               withApplicationAtURL:skimURL
                                      configuration:[NSWorkspaceOpenConfiguration configuration]
                                  completionHandler:nil];
        } else {
            [[NSWorkspace sharedWorkspace] openURL:fileURL];
        }
    } else {
        NSString *workspace = AerospaceOutput(@[@"list-workspaces", @"--focused"]);
        NSString *winQuery = AerospaceOutput(@[@"list-windows", @"--workspace", workspace, @"--format", @"%{window-id}|%{app-name}|%{window-title}"]);
        NSString *nvimWinID = nil;

        for (NSString *line in [winQuery componentsSeparatedByString:@"\n"]) {
            NSArray *p = [line componentsSeparatedByString:@"|"];
            if (p.count >= 3) {
                BOOL isTerminal = [p[1] localizedCaseInsensitiveContainsString:@"alacritty"];
                BOOL isVim = [p[2] localizedCaseInsensitiveContainsString:@"nvim"];
                if (isTerminal && isVim) { nvimWinID = p[0]; break; }
            }
        }

        if (nvimWinID) {
            NSString *sockPath = [NSString stringWithFormat:@"/tmp/nvim-window-%@.sock", nvimWinID];
            if (access(sockPath.UTF8String, F_OK) == 0) {
                AerospaceRun(@[@"focus", @"--window-id", nvimWinID]);
                RunCommandDetached(kNvimPath, @[@"--server", sockPath, @"--remote-tab", fullPath]);
                return;
            }
        }
        RunCommandDetached(@"/run/current-system/sw/bin/alacrittyDaemon", @[@"-e", kNvimPath, fullPath]);
    }
}

static void QuitAndCloseLauncher() {
    NSString *wins = AerospaceOutput(@[@"list-windows", @"--all", @"--format", @"%{window-id}|%{window-title}"]);
    NSString *launcherID = nil;

    for (NSString *line in [wins componentsSeparatedByString:@"\n"]) {
        NSArray *p = [line componentsSeparatedByString:@"|"];
        if (p.count >= 2 && [p[1] isEqualToString:@"launcher"]) {
            launcherID = p[0];
            break;
        }
    }

    if (launcherID) AerospaceClose(launcherID);
    exit(0);
}

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        EnsureSystemPath();
        EnsureDirectoryExists(kCacheDir.UTF8String);

        if (argc > 1) {
            NSString *arg = [NSString stringWithUTF8String:argv[1]];
            if ([arg isEqualToString:@"--update"]) {
                UpdateCache();
                return 0;
            }

            NSString *absPath = [arg stringByExpandingTildeInPath];
            if (![absPath isAbsolutePath]) {
                absPath = [[[NSFileManager defaultManager] currentDirectoryPath] stringByAppendingPathComponent:absPath];
            }
            absPath = [absPath stringByStandardizingPath];

            if ([absPath hasPrefix:kRealICloudDir]) {
                absPath = [absPath stringByReplacingOccurrencesOfString:kRealICloudDir withString:kBaseDir options:0 range:NSMakeRange(0, kRealICloudDir.length)];
            }

            if ([absPath hasPrefix:kBaseDir] && [[NSFileManager defaultManager] fileExistsAtPath:absPath]) {
                NSString *relPath = [absPath substringFromIndex:kBaseDir.length + ([absPath characterAtIndex:kBaseDir.length] == '/' ? 1 : 0)];
                Launch(FormatFilePath(relPath));
            }

            QuitAndCloseLauncher();
            return 0;
        }

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            UpdateCache();
        });

        NSString *selected = SelectFiles();
        AerospaceRun(@[@"mode", @"main"]);

        if (selected.length > 0) {
            UpdateRecentFiles(selected);
            Launch(selected);
        }

        QuitAndCloseLauncher();
    }
    return 0;
}
