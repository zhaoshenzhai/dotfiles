#import "commonUtils.h"
#include <readline/readline.h>
#include <unistd.h>

static NSString * const repoNames[] = { @"Courses", @"Dotfiles", @"Projects", @"Website" };
static const NSUInteger repoCount = sizeof(repoNames) / sizeof(repoNames[0]);
static NSString *repoPaths[sizeof(repoNames) / sizeof(repoNames[0])];

static bool PromptExitOrReturn(void) {
    printf("\n%sPress [Y] to return, exiting otherwise...%s ", CYAN, NC);
    fflush(stdout);
    int c = GetCh();

    if (c == 'Y' || c == 'y' || c == '\n' || c == '\r') { system("clear"); return true; }
    AerospaceClose(nil);
    exit(0);
}

static NSString *ResolveRepository(void) {
    printf("%sRepositories:%s\n", CYAN, NC);
    for (NSUInteger i = 0; i < repoCount; i++) {
        printf("    %s(%lu): %s%s\n", CYAN, i + 1, [repoNames[i] UTF8String], NC);
    }
    printf("\n%sSelect repository: [1-4]%s ", CYAN, NC);
    fflush(stdout);

    int cmdNum = GetCh();

    if (cmdNum >= '1' && cmdNum <= '4') {
        printf("%c\n", cmdNum);
        return repoPaths[cmdNum - '1'];
    }

    if (cmdNum == 'q' || cmdNum == 'Q') {
        printf("q\n");
        PromptExitOrReturn();
    }

    printf("\n");
    NSMutableArray<NSNumber *> *changedIndices = [NSMutableArray array];
    NSFileManager *fm = [NSFileManager defaultManager];

    for (NSUInteger i = 0; i < repoCount; i++) {
        [fm changeCurrentDirectoryPath:repoPaths[i]];
        NSString *status = RunCommandOutput(@"/usr/bin/env", @[@"git", @"status", @"--porcelain", @"--", @":!attic/notes/*.svg"]);
        if (status.length > 0) {
            [changedIndices addObject:@(i)];
        }
    }

    if (changedIndices.count == 0) {
        return nil;
    } else if (changedIndices.count == 1) {
        NSUInteger idx = [changedIndices[0] unsignedIntegerValue];
        return repoPaths[idx];
    }

    while (true) {
        system("clear");
        printf("%sChanged repositories:%s\n", CYAN, NC);
        for (NSNumber *idxNum in changedIndices) {
            NSUInteger i = [idxNum unsignedIntegerValue];
            printf("    %s(%lu): %s%s\n", CYAN, i + 1, [repoNames[i] UTF8String], NC);
        }
        printf("\n%sSelect repository:%s ", CYAN, NC);
        fflush(stdout);

        int subCmd = GetCh();

        if (subCmd == 'q' || subCmd == 'Q') {
            printf("q\n");
            PromptExitOrReturn();
        }

        int subChoiceIndex = subCmd - '1';
        if ([changedIndices containsObject:@(subChoiceIndex)]) {
            printf("%c\n", subCmd);
            return repoPaths[subChoiceIndex];
        } else {
            system("clear");
        }
    }
}

static void CleanupIgnoredFiles(void) {
    NSString *ignoredOut = RunCommandOutput(@"/usr/bin/env", @[@"git", @"ls-files", @"-i", @"-c", @"--exclude-from=.gitignore"]);
    ignoredOut = [ignoredOut stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

    if (ignoredOut.length > 0) {
        NSArray *ignoredFiles = [ignoredOut componentsSeparatedByString:@"\n"];
        NSMutableArray *rmArgs = [NSMutableArray arrayWithObject:@"git"];
        [rmArgs addObject:@"rm"];
        [rmArgs addObject:@"--cached"];
        [rmArgs addObjectsFromArray:ignoredFiles];
        RunCommandWait(@"/usr/bin/env", rmArgs);
    }
}

static void ShowStatus(void) {
    NSString *statusOutput = RunCommandOutput(@"/usr/bin/env",
            @[@"git", @"-c", @"color.status=always", @"status", @"--", @":!attic/notes/*.svg"]);
    statusOutput = [statusOutput stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    printf("\n%s\n", [statusOutput UTF8String]);
}

static bool HasChangesToCommit(void) {
    NSString *statusCheck = RunCommandOutput(@"/usr/bin/env", @[@"git", @"status", @"--porcelain", @"--", @":!attic/notes/*.svg"]);
    return statusCheck.length > 0;
}

static void HandleSilentWebUpdates(NSString *webPath) {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *currentDir = [fm currentDirectoryPath];
    [fm changeCurrentDirectoryPath:webPath];

    RunCommandWait(@"/usr/bin/env", @[@"git", @"add", @"--all", @"attic/notes/*.svg"]);

    NSString *statusOutput = RunCommandOutput(@"/usr/bin/env", @[@"git", @"status", @"--porcelain", @"--staged"]);
    statusOutput = [statusOutput stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

    if (statusOutput.length > 0) {
        RunCommandWait(@"/usr/bin/env", @[@"git", @"commit", @"-m", @"Updated attic notes"]);

        NSTask *task = [[NSTask alloc] init];
        task.executableURL = [NSURL fileURLWithPath:@"/usr/bin/env"];
        task.arguments = @[@"git", @"push"];
        task.standardOutput = [NSFileHandle fileHandleWithNullDevice];
        task.standardError = [NSFileHandle fileHandleWithNullDevice];
        [task launch];
        [task waitUntilExit];
    }

    [fm changeCurrentDirectoryPath:currentDir];
}

static bool HandleDiffPrompt(void) {
    printf("\n%sShow diff? [Y/n/q]%s ", PURPLE, NC);
    fflush(stdout);
    int diffChoice = GetCh();
    printf("%c\n", diffChoice == '\r' || diffChoice == '\n' ? 'Y' : diffChoice);

    if (diffChoice == 'q' || diffChoice == 'Q') {
        return false;
    } else if (diffChoice != 'n' && diffChoice != 'N') {
        printf("\n");
        RunCommandWait(@"/usr/bin/env", @[@"git", @"add", @".", @":!attic/notes/*.svg"]);
        RunInteractive(@"/usr/bin/env", @[@"git", @"--no-pager", @"-c", @"color.diff=always", @"diff", @"--staged"]);
    }
    return true;
}

static bool HandleCommitPrompt(void) {
    printf("\n%sCommit? [Y/n]%s ", PURPLE, NC);
    fflush(stdout);
    int commitChoice = GetCh();
    printf("%c\n", commitChoice == '\r' || commitChoice == '\n' ? 'Y' : commitChoice);

    if (commitChoice == 'q' || commitChoice == 'Q' || commitChoice == 'n' || commitChoice == 'N') return false;

    RunCommandWait(@"/usr/bin/env", @[@"git", @"add", @".", @":!attic/notes/*.svg"]);
    ShowStatus();
    return true;
}

static void HandleRemoval(void) {
    while (true) {
        char prompt[256];
        snprintf(prompt, sizeof(prompt), "\n\001%s\002Remove files? [N/(string)]\001%s\002 ", PURPLE, NC);

        char *inputBuf = readline(prompt);
        if (!inputBuf) break;

        TrimEnd(inputBuf);

        if (strlen(inputBuf) == 0 || strcasecmp(inputBuf, "n") == 0) { free(inputBuf); break; }

        NSString *inputStr = [NSString stringWithUTF8String:inputBuf];
        free(inputBuf);

        NSArray *filesToRemove = [inputStr componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        NSMutableArray *restoreArgs = [NSMutableArray arrayWithObjects:@"git", @"restore", @"--staged", nil];

        for (NSString *file in filesToRemove) {
            if (file.length > 0) [restoreArgs addObject:file];
        }

        RunCommandWait(@"/usr/bin/env", restoreArgs);
        ShowStatus();
    }
}

static void Commit(void) {
    char *msgBuf = NULL;
    bool first = true;

    while (true) {
        if (first) { printf("\n"); first = false; }

        char prompt[256];
        snprintf(prompt, sizeof(prompt), "\001%s\002Message:\001%s\002 ", PURPLE, NC);

        msgBuf = readline(prompt);

        if (msgBuf) {
            TrimEnd(msgBuf);
            if (strlen(msgBuf) > 0) break;

            free(msgBuf);
            msgBuf = NULL;
        } else {
            break;
        }
    }

    if (msgBuf) {
        printf("\n");
        RunInteractive(@"/usr/bin/env", @[@"git", @"commit", @"-m", [NSString stringWithUTF8String:msgBuf]]);
        printf("\n");
        free(msgBuf);
    }
}

static void Push(void) {
    int attempt = 1;
    while (true) {
        NSTask *task = [[NSTask alloc] init];
        task.executableURL = [NSURL fileURLWithPath:@"/usr/bin/env"];
        task.arguments = @[@"git", @"push"];

        NSPipe *errPipe = [NSPipe pipe];
        task.standardError = errPipe;

        [task launch];
        [task waitUntilExit];

        NSData *errData = [[errPipe fileHandleForReading] readDataToEndOfFile];
        NSString *errStr = [[NSString alloc] initWithData:errData encoding:NSUTF8StringEncoding];

        if (errStr.length > 0) printf("%s", [errStr UTF8String]);

        if ([errStr containsString:@"fatal"]) {
            char prompt[256];
            snprintf(prompt, sizeof(prompt), "\n\001%s\002Attempt %d: Authentication failed. Please enter your PAT:\001%s\002 ", RED, attempt, NC);

            char *patBuf = readline(prompt);
            if (patBuf) {
                TrimEnd(patBuf);
                if (strlen(patBuf) > 0) {
                    RunCommandWait(@"/usr/bin/env", @[@"git", @"config", @"--global", @"credential.helper", @"store"]);
                    NSString *credStr = [NSString stringWithFormat:@"https://zhaoshenzhai:%s@github.com\n", patBuf];
                    NSString *credPath = [NSHomeDirectory() stringByAppendingPathComponent:@".git-credentials"];
                    [credStr writeToFile:credPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
                }
                free(patBuf);
            }
            attempt++;
        } else {
            break;
        }
    }
}

int main(int argc, char **argv) {
    @autoreleasepool {
        repoPaths[0] = [kBaseDir stringByAppendingPathComponent:@"University/Courses"];
        repoPaths[1] = [kBaseDir stringByAppendingPathComponent:@"Dotfiles"];
        repoPaths[2] = [kBaseDir stringByAppendingPathComponent:@"Projects"];
        repoPaths[3] = [kBaseDir stringByAppendingPathComponent:@"Projects/_web"];

        EnsureSystemPath();

        while (true) {
            NSString *targetPath = ResolveRepository();
            if (!targetPath) { if (PromptExitOrReturn()) { continue; } break; }
            [[NSFileManager defaultManager] changeCurrentDirectoryPath:targetPath];

            CleanupIgnoredFiles();
            ShowStatus();

            if (!HasChangesToCommit()) { if (PromptExitOrReturn()) { continue; } break; }
            if (!HandleDiffPrompt())   { if (PromptExitOrReturn()) { continue; } break; }
            if (!HandleCommitPrompt()) { if (PromptExitOrReturn()) { continue; } break; }

            HandleRemoval();
            Commit();
            Push();

            if ([targetPath hasSuffix:@"Projects"]) HandleSilentWebUpdates(repoPaths[3]);

            if (PromptExitOrReturn()) { continue; } break;
        }
    }

    AerospaceClose(nil);
    return 0;
}
