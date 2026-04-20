#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString *const kCommonBaseDir;
extern NSString *const kCommonAerospacePath;
extern NSString *const kCommonNvimPath;
extern NSString *const kCommonLauncherPath;

int RunCommandWait(NSString *cmdPath, NSArray<NSString *> *argsArray);
NSString *RunCommandOutput(NSString *cmdPath, NSArray<NSString *> *argsArray);
void RunCommandDetached(NSString *cmdPath, NSArray<NSString *> *argsArray);

static inline int AerospaceRun(NSArray<NSString *> *args) {
    return RunCommandWait(kCommonAerospacePath, args);
}

static inline NSString *AerospaceOutput(NSArray<NSString *> *args) {
    NSString *outStr = RunCommandOutput(kCommonAerospacePath, args);
    return [outStr stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

NS_ASSUME_NONNULL_END
