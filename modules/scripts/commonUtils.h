#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString *const kBaseDir;
extern NSString *const kAerospacePath;
extern NSString *const kNvimPath;
extern NSString *const kLauncherPath;

int RunCommandWait(NSString *cmdPath, NSArray<NSString *> *argsArray);
NSString *RunCommandOutput(NSString *cmdPath, NSArray<NSString *> *argsArray);
void RunCommandDetached(NSString *cmdPath, NSArray<NSString *> *argsArray);

static inline int AerospaceRun(NSArray<NSString *> *args) {
    return RunCommandWait(kAerospacePath, args);
}

static inline NSString *AerospaceOutput(NSArray<NSString *> *args) {
    NSString *outStr = RunCommandOutput(kAerospacePath, args);
    return [outStr stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

NS_ASSUME_NONNULL_END
