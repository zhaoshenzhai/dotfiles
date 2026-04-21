#import "commonUtils.h"
#import <Foundation/Foundation.h>
#include <unistd.h>

static const NSUInteger repoCount = 4;
static NSString * const repoNames[] = { @"Courses", @"Dotfiles", @"Projects", @"Website" };
static NSString * const repoPaths[] = {
    @"/Users/zhao/iCloud/University/Courses",
    @"/Users/zhao/iCloud/Dotfiles",
    @"/Users/zhao/iCloud/Projects",
    @"/Users/zhao/iCloud/Projects/_web"
};


static bool PromptExitOrReturn(void) {
    printf("\n%sPress [Y] to return, exiting otherwise...%s ", CYAN, NC);
    fflush(stdout);
    int c = GetCh();

    if (c == 'Y' || c == 'y' || c == '\n' || c == '\r') { system("clear"); return true; }
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
        NSString *status = RunCommandOutput(@"/usr/bin/env", @[@"git", @"status", @"--porcelain"]);
        if (status.length > 0) {
            [changedIndices addObject:@(i)];
        }
    }

    if (changedIndices.count == 0) {
        printf("No changes in any repository.\n");
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
            printf("%c\n\n", subCmd);
            return repoPaths[subChoiceIndex];
        } else {
            system("clear");
        }
    }
}

static void CleanupIgnoredFiles(void) {
    printf("\n");
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
    RunInteractive(@"/usr/bin/env", @[@"git", @"-c", @"color.status=always", @"status"]);
}

static bool HasChangesToCommit(void) {
    NSString *statusCheck = RunCommandOutput(@"/usr/bin/env", @[@"git", @"status"]);
    return ![statusCheck containsString:@"nothing to commit"];
}

static bool HandleDiffPrompt(void) {
    printf("%s\nShow diff? [Y/n/q]%s ", PURPLE, NC);
    fflush(stdout);
    int diffChoice = GetCh();
    printf("%c\n", diffChoice == '\r' || diffChoice == '\n' ? 'Y' : diffChoice);

    if (diffChoice == 'q' || diffChoice == 'Q') {
        return false;
    } else if (diffChoice != 'n' && diffChoice != 'N') {
        printf("\n");
        RunInteractive(@"/usr/bin/env", @[@"git", @"--no-pager", @"-c", @"color.diff=always", @"diff"]);
    }
    return true;
}

static bool HandleCommitPrompt(void) {
    printf("%s\nCommit? [Y/n]%s ", PURPLE, NC);
    fflush(stdout);
    int commitChoice = GetCh();
    printf("%c\n", commitChoice == '\r' || commitChoice == '\n' ? 'Y' : commitChoice);

    if (commitChoice == 'n' || commitChoice == 'N') {
        return false;
    }

    RunCommandWait(@"/usr/bin/env", @[@"git", @"add", @"."]);
    printf("\n");
    ShowStatus();
    return true;
}

static void HandleRemoval(void) {
    char inputBuf[1024];
    while (true) {
        printf("%sRemove files? [N/(string)]%s ", PURPLE, NC);
        fflush(stdout);
        if (!fgets(inputBuf, sizeof(inputBuf), stdin)) break;
        TrimEnd(inputBuf);

        if (strlen(inputBuf) == 0 || strcasecmp(inputBuf, "n") == 0) break;

        NSString *inputStr = [NSString stringWithUTF8String:inputBuf];
        NSArray *filesToRemove = [inputStr componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        NSMutableArray *restoreArgs = [NSMutableArray arrayWithObjects:@"git", @"restore", @"--staged", nil];

        for (NSString *file in filesToRemove) {
            if (file.length > 0) [restoreArgs addObject:file];
        }

        RunCommandWait(@"/usr/bin/env", restoreArgs);
        printf("\n");
        ShowStatus();
    }
}

static void Commit(void) {
    char msgBuf[4096];
    while (true) {
        printf("\n%sMessage:%s ", PURPLE, NC);
        fflush(stdout);
        if (fgets(msgBuf, sizeof(msgBuf), stdin)) {
            TrimEnd(msgBuf);
            if (strlen(msgBuf) > 0) break;
        }
    }

    printf("\n");
    RunInteractive(@"/usr/bin/env", @[@"git", @"commit", @"-m", [NSString stringWithUTF8String:msgBuf]]);
    printf("\n");
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
            printf("\n%sAttempt %d: Authentication failed. Please enter your PAT:%s ", RED, attempt, NC);
            fflush(stdout);

            char patBuf[1024];
            if (fgets(patBuf, sizeof(patBuf), stdin)) {
                TrimEnd(patBuf);
                if (strlen(patBuf) > 0) {
                    RunCommandWait(@"/usr/bin/env", @[@"git", @"config", @"--global", @"credential.helper", @"store"]);
                    NSString *credStr = [NSString stringWithFormat:@"https://zhaoshenzhai:%s@github.com\n", patBuf];
                    NSString *credPath = [NSHomeDirectory() stringByAppendingPathComponent:@".git-credentials"];
                    [credStr writeToFile:credPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
                }
            }
            attempt++;
        } else {
            break;
        }
    }
}

int main(int argc, char **argv) {
    @autoreleasepool {
        EnsureSystemPath();

        while (true) {
            NSString *targetPath = ResolveRepository();

            if (!targetPath) {
                if (PromptExitOrReturn()) continue;
                break;
            }

            [[NSFileManager defaultManager] changeCurrentDirectoryPath:targetPath];

            CleanupIgnoredFiles();
            ShowStatus();

            if (!HasChangesToCommit()) {
                if (PromptExitOrReturn()) continue;
                break;
            }

            if (!HandleDiffPrompt()) {
                if (PromptExitOrReturn()) continue;
                break;
            }

            if (!HandleCommitPrompt()) {
                if (PromptExitOrReturn()) continue;
                break;
            }

            HandleRemoval();
            Commit();
            Push();

            if (PromptExitOrReturn()) continue;
            break;
        }
    }
    return 0;
}
