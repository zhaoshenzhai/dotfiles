#pragma once

#import <ApplicationServices/ApplicationServices.h>
#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#include <stdbool.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString *const kBaseDir;
extern NSString *const kAerospacePath;
extern NSString *const kNvimPath;
extern NSString *const kLauncherPath;

// --- Command Execution ---
int RunCommandWait(NSString *cmdPath, NSArray<NSString *> *argsArray);
NSString *RunCommandOutput(NSString *cmdPath, NSArray<NSString *> *argsArray);
void RunCommandDetached(NSString *cmdPath, NSArray<NSString *> *argsArray);

// --- Process and Accessibility Utilities ---
AXUIElementRef _Nullable GetFocusedWindowForPID(pid_t pid);
CFArrayRef _Nullable CopyAXWindows(pid_t pid);
NSString * _Nullable AXWindowTitle(AXUIElementRef win);
AXUIElementRef _Nullable FindChildWithTitle(AXUIElementRef parent, NSString *title);
AXUIElementRef _Nullable GetFirstChildWithRole(AXUIElementRef parent, CFStringRef role);
AXUIElementRef _Nullable GetSubmenu(AXUIElementRef element);

// -- File and Directory Utilities
void EnsureSystemPath(void);
unsigned int DJB2Hash(const char *str);
bool IsProcessRunning(const char *pattern);
int EnsureDirectoryExists(const char *path);
int MoveFile(const char *src, const char *dst);

// --- Input Simulation ---
void PostKeystrokeToPID(pid_t pid, CGKeyCode keyCode, CGEventFlags flags);

// --- Aerospace and Launcher Execution ---
static inline int AerospaceRun(NSArray<NSString *> *args) {
    return RunCommandWait(kAerospacePath, args);
}
static inline NSString *AerospaceOutput(NSArray<NSString *> *args) {
    NSString *outStr = RunCommandOutput(kAerospacePath, args);
    return [outStr stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}
static inline void RunLauncher(NSString *targetPath) {
    if (targetPath) RunCommandDetached(kLauncherPath, @[targetPath]);
}

NS_ASSUME_NONNULL_END
