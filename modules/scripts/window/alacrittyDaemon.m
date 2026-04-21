#import "commonUtils.h"
#include <sys/stat.h>
#include <unistd.h>

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        NSString *socketPath = @"/tmp/alacritty.sock";
        NSString *lockDir = @"/tmp/alacritty_daemon.lock";
        NSFileManager *fm = [NSFileManager defaultManager];

        if ([fm fileExistsAtPath:socketPath]) {
            if (!IsProcessRunning("alacritty")) {
                [fm removeItemAtPath:socketPath error:nil];
                [fm removeItemAtPath:lockDir error:nil];
            }
        }

        setenv("ALACRITTY_SOCKET", socketPath.UTF8String, 1);

        NSMutableArray *args = [NSMutableArray array];
        for (int i = 1; i < argc; i++) {
            [args addObject:[NSString stringWithUTF8String:argv[i]]];
        }

        NSMutableArray *msgArgs = [NSMutableArray arrayWithArray:@[@"alacritty", @"msg", @"create-window"]];
        [msgArgs addObjectsFromArray:args];

        if (RunCommandWait(@"/usr/bin/env", msgArgs) == 0) return 0;

        if (mkdir(lockDir.UTF8String, 0700) == 0) {
            [fm removeItemAtPath:socketPath error:nil];
            RunCommandDetached(@"/usr/bin/env", @[@"alacritty", @"--daemon", @"--socket", socketPath]);

            for (int i = 0; i < 20; i++) {
                if ([fm fileExistsAtPath:socketPath]) break;
                usleep(100000);
            }
        } else {
            for (int i = 0; i < 30; i++) {
                if ([fm fileExistsAtPath:socketPath]) break;
                usleep(100000);
            }
        }

        if (RunCommandWait(@"/usr/bin/env", msgArgs) != 0) {
            NSMutableArray *fallbackArgs = [NSMutableArray arrayWithObject:@"alacritty"];
            [fallbackArgs addObjectsFromArray:args];
            RunCommandDetached(@"/usr/bin/env", fallbackArgs);
        }
    }
    return 0;
}
