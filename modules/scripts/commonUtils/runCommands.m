#import "commonUtils.h"
#import <spawn.h>

extern char **environ;

static char **CreateArgv(NSString *cmdPath, NSArray<NSString *> *argsArray, int *outArgc) {
    int argc = (int)argsArray.count + 1;
    char **argv = malloc((argc + 1) * sizeof(char *));
    argv[0] = strdup(cmdPath.lastPathComponent.UTF8String);
    for (int i = 0; i < argsArray.count; i++) {
        argv[i + 1] = strdup(argsArray[i].UTF8String);
    }
    argv[argc] = NULL;
    *outArgc = argc;
    return argv;
}

static void FreeArgv(char **argv, int argc) {
    for (int i = 0; i < argc; i++) free(argv[i]);
    free(argv);
}

int RunCommandWait(NSString *cmdPath, NSArray<NSString *> *argsArray) {
    int argc;
    char **argv = CreateArgv(cmdPath, argsArray, &argc);
    pid_t pid;
    posix_spawn_file_actions_t actions;

    posix_spawn_file_actions_init(&actions);
    posix_spawn_file_actions_addopen(&actions, STDOUT_FILENO, "/dev/null", O_WRONLY, 0);
    posix_spawn_file_actions_addopen(&actions, STDERR_FILENO, "/dev/null", O_WRONLY, 0);

    int status = -1;
    if (posix_spawn(&pid, cmdPath.UTF8String, &actions, NULL, argv, environ) == 0) {
        waitpid(pid, &status, 0);
    }

    posix_spawn_file_actions_destroy(&actions);
    FreeArgv(argv, argc);
    return status;
}

NSString *RunCommandOutput(NSString *cmdPath, NSArray<NSString *> *argsArray) {
    int pipefd[2];
    if (pipe(pipefd) != 0) return @"";

    int argc;
    char **argv = CreateArgv(cmdPath, argsArray, &argc);
    pid_t pid;

    posix_spawn_file_actions_t actions;
    posix_spawn_file_actions_init(&actions);
    posix_spawn_file_actions_adddup2(&actions, pipefd[1], STDOUT_FILENO);
    posix_spawn_file_actions_addclose(&actions, pipefd[0]);

    if (posix_spawn(&pid, cmdPath.UTF8String, &actions, NULL, argv, environ) != 0) {
        posix_spawn_file_actions_destroy(&actions);
        close(pipefd[0]); close(pipefd[1]);
        FreeArgv(argv, argc);
        return @"";
    }

    posix_spawn_file_actions_destroy(&actions);
    close(pipefd[1]);

    NSMutableData *data = [[NSMutableData alloc] initWithCapacity:4096];
    char buffer[4096];
    ssize_t bytesRead;

    while ((bytesRead = read(pipefd[0], buffer, sizeof(buffer))) > 0) {
        [data appendBytes:buffer length:bytesRead];
    }
    close(pipefd[0]);
    waitpid(pid, NULL, 0);

    FreeArgv(argv, argc);
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

void RunCommandDetached(NSString *cmdPath, NSArray<NSString *> *argsArray) {
    int argc;
    char **argv = CreateArgv(cmdPath, argsArray, &argc);
    pid_t pid;

    posix_spawn_file_actions_t actions;
    posix_spawn_file_actions_init(&actions);
    posix_spawn_file_actions_addopen(&actions, STDOUT_FILENO, "/dev/null", O_WRONLY, 0);
    posix_spawn_file_actions_addopen(&actions, STDERR_FILENO, "/dev/null", O_WRONLY, 0);

    posix_spawnattr_t attr;
    posix_spawnattr_init(&attr);
    posix_spawnattr_setflags(&attr, POSIX_SPAWN_SETSID);

    posix_spawn(&pid, cmdPath.UTF8String, &actions, &attr, argv, environ);

    posix_spawnattr_destroy(&attr);
    posix_spawn_file_actions_destroy(&actions);
    FreeArgv(argv, argc);
}

int RunInteractive(NSString *cmdPath, NSArray<NSString *> *argsArray) {
    @autoreleasepool {
        NSTask *task = [[NSTask alloc] init];
        task.executableURL = [NSURL fileURLWithPath:cmdPath];
        task.arguments = argsArray;
        [task launch];
        [task waitUntilExit];
        return [task terminationStatus];
    }
}

int AerospaceRun(NSArray<NSString *> *args) {
    return RunCommandWait(kAerospacePath, args);
}

NSString *AerospaceOutput(NSArray<NSString *> *args) {
    NSString *outStr = RunCommandOutput(kAerospacePath, args);
    return [outStr stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

void AerospaceClose() {
    AerospaceRun(@[@"move-node-to-workspace", @"0"]);
    usleep(500000);

    NSString *ghostIDs = AerospaceOutput(@[@"list-windows", @"--workspace", @"0", @"--format", @"%{window-id}"]);
    for (NSString *line in [ghostIDs componentsSeparatedByString:@"\n"]) {
        NSString *trimmedID = [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (trimmedID.length > 0) {
            AerospaceRun(@[@"close", @"--window-id", trimmedID, @"--quit-if-last-window"]);
        }
    }
}

void RunLauncher(NSString *targetPath) {
    if (targetPath) RunCommandDetached(kLauncherPath, @[targetPath]);
}
