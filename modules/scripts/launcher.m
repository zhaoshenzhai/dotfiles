#import "commonUtils.h"

static NSString *const kFdPath = @FD_PATH;
static NSString *const kFzfPath = @FZF_PATH;
static NSString *const kCacheDir = @"/Users/zhao/.cache/launcher";

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
        if (line.length > 0 && ![line isEqualToString:selected]) {
            [newLines addObject:line];
        }
        if (newLines.count >= 100) break;
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

    NSArray *fdArgs = @[@"-L", @"--type", @"f", @"--hidden", @"--no-ignore",
                        @"--exclude", @".git", @"--exclude", @"*.old", @"--exclude", @"*.png", @"--exclude", @"*.jpg",
                        @"--exclude", @"*.tar.gz", @"--exclude", @"*.zip", @"--exclude", @"*.synctex.gz",
                        @".", @"Documents", @"Dotfiles", @"Projects"];

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
        if (recentStr.length > 0) {
            NSArray *lines = [recentStr componentsSeparatedByString:@"\n"];
            for (NSString *line in lines) {
                if (line.length == 0) continue;

                if ([line containsString:@"\t"]) {
                    [combined appendFormat:@"%@\n", line];
                } else {
                    [combined appendFormat:@"%@\n", FormatFilePath(line)];
                }
            }
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
        selected = [[NSString stringWithUTF8String:path] stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    }
    pclose(fp);
    return selected;
}

static void Launch(NSString *selected) {
    NSArray *parts = [selected componentsSeparatedByString:@"\t"];
    if (parts.count < 2) return;

    NSString *relPath = parts[1];
    NSString *fullPath = [kBaseDir stringByAppendingPathComponent:relPath];

    if ([fullPath hasSuffix:@".pdf"]) {
        NSString *filename = fullPath.lastPathComponent;

        NSString *skims = RunCommandOutput(kAerospacePath, @[@"list-windows", @"--all", @"--format", @"%{app-name}|%{window-title}"]);
        BOOL exists = NO;
        for (NSString *line in [skims componentsSeparatedByString:@"\n"]) {
            if ([line hasPrefix:@"Skim|"] && [line containsString:filename]) {
                exists = YES;
                break;
            }
        }

        NSURL *fileURL;
        if (exists) {
            NSString *timestamp = [NSString stringWithFormat:@"%.0f", [[NSDate date] timeIntervalSince1970]];
            NSString *uniqueDir = [@"/tmp/skim_pdfs" stringByAppendingPathComponent:timestamp];
            [[NSFileManager defaultManager] createDirectoryAtPath:uniqueDir withIntermediateDirectories:YES attributes:nil error:nil];

            NSString *copyPath = [uniqueDir stringByAppendingPathComponent:filename];
            [[NSFileManager defaultManager] copyItemAtPath:fullPath toPath:copyPath error:nil];

            NSString *origTracker = [copyPath stringByAppendingString:@".orig"];
            [fullPath writeToFile:origTracker atomically:YES encoding:NSUTF8StringEncoding error:nil];

            fileURL = [NSURL fileURLWithPath:copyPath];
        } else {
            fileURL = [NSURL fileURLWithPath:fullPath];
        }

        NSURL *skimURL = [[NSWorkspace sharedWorkspace] URLForApplicationWithBundleIdentifier:@"net.sourceforge.skim-app.skim"];
        if (skimURL) {
            NSWorkspaceOpenConfiguration *config = [NSWorkspaceOpenConfiguration configuration];
            [[NSWorkspace sharedWorkspace] openURLs:@[fileURL]
                               withApplicationAtURL:skimURL
                                      configuration:config
                                  completionHandler:nil];
        } else {
            [[NSWorkspace sharedWorkspace] openURL:fileURL];
        }

    } else {
        NSString *workspace = AerospaceOutput(@[@"list-workspaces", @"--focused"]);
        NSString *winQuery = RunCommandOutput(kAerospacePath, @[@"list-windows", @"--workspace", workspace, @"--format", @"%{window-id}|%{app-name}|%{window-title}"]);

        NSString *nvimWinID = nil;

        for (NSString *line in [winQuery componentsSeparatedByString:@"\n"]) {
            NSArray *p = [line componentsSeparatedByString:@"|"];
            if (p.count >= 3) {
                NSString *appName = (NSString *)p[1];
                NSString *winTitle = (NSString *)p[2];

                BOOL isTerminal = [appName localizedCaseInsensitiveContainsString:@"alacritty"];
                BOOL isVim = [winTitle localizedCaseInsensitiveContainsString:@"nvim"];

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

static void QuitAndCloseLauncher(BOOL didLaunch) {
    NSString *launcherID = nil;
    NSString *wins = RunCommandOutput(kAerospacePath, @[@"list-windows", @"--all", @"--format", @"%{window-id}|%{window-title}"]);

    for (NSString *line in [wins componentsSeparatedByString:@"\n"]) {
        NSArray *p = [line componentsSeparatedByString:@"|"];
        if (p.count >= 2 && [p[1] isEqualToString:@"launcher"]) {
            launcherID = p[0];
            break;
        }
    }

    if (!launcherID) exit(0);

    if (didLaunch) {
        NSString *ws = AerospaceOutput(@[@"list-workspaces", @"--focused"]);
        for (int i = 0; i < 15; i++) {
            usleep(100000);
            NSString *wsWins = RunCommandOutput(kAerospacePath, @[@"list-windows", @"--workspace", ws]);
            NSArray *lines = [wsWins componentsSeparatedByString:@"\n"];
            int count = 0;
            for (NSString *l in lines) if (l.length > 0) count++;

            if (count > 1) break;
        }
    }

    AerospaceRun(@[@"close", @"--window-id", launcherID]);
    exit(0);
}

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        [[NSFileManager defaultManager] createDirectoryAtPath:kCacheDir withIntermediateDirectories:YES attributes:nil error:nil];

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

            NSString *home = NSHomeDirectory();
            NSString *realICloud = [home stringByAppendingPathComponent:@"Library/Mobile Documents/com~apple~CloudDocs"];
            NSString *symlinkICloud = [home stringByAppendingPathComponent:@"iCloud"];

            if ([absPath hasPrefix:realICloud]) {
                absPath = [absPath stringByReplacingOccurrencesOfString:realICloud withString:kBaseDir options:0 range:NSMakeRange(0, realICloud.length)];
            } else if ([absPath hasPrefix:symlinkICloud]) {
                absPath = [absPath stringByReplacingOccurrencesOfString:symlinkICloud withString:kBaseDir options:0 range:NSMakeRange(0, symlinkICloud.length)];
            }

            if ([absPath hasPrefix:kBaseDir]) {
                NSString *relPath = [absPath substringFromIndex:kBaseDir.length];
                if ([relPath hasPrefix:@"/"]) {
                    relPath = [relPath substringFromIndex:1];
                }

                if ([[NSFileManager defaultManager] fileExistsAtPath:absPath]) {
                    NSString *formatted = FormatFilePath(relPath);
                    Launch(formatted);
                    QuitAndCloseLauncher(YES);
                    return 0;
                }
            }

            QuitAndCloseLauncher(NO);
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
            QuitAndCloseLauncher(YES);
        } else {
            QuitAndCloseLauncher(NO);
        }
    }
    return 0;
}
