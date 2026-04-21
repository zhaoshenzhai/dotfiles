#pragma once

#import <ApplicationServices/ApplicationServices.h>
#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

NS_ASSUME_NONNULL_BEGIN

// --- Colors ---
#define RED "\x1b[31m"
#define GREEN "\x1b[32m"
#define YELLOW "\x1b[33m"
#define BLUE "\x1b[34m"
#define PURPLE "\x1b[35m"
#define CYAN "\x1b[36m"
#define NC "\x1b[0m"

// --- Directories and paths ---
extern NSString *const kBaseDir;
extern NSString *const kRealICloudDir;
extern NSString *const kLaTeXTemplateDir;
extern NSString *const kAerospacePath;
extern NSString *const kNvimPath;
extern NSString *const kLauncherPath;

// --- Command execution ---
int RunCommandWait(NSString *cmdPath, NSArray<NSString *> *argsArray);
NSString *RunCommandOutput(NSString *cmdPath, NSArray<NSString *> *argsArray);
void RunCommandDetached(NSString *cmdPath, NSArray<NSString *> *argsArray);
int RunInteractive(NSString *cmdPath, NSArray<NSString *> *argsArray);

// --- Process and accessibility utilities ---
AXUIElementRef _Nullable GetFocusedWindowForPID(pid_t pid);
CFArrayRef _Nullable CopyAXWindows(pid_t pid);
NSString * _Nullable AXWindowTitle(AXUIElementRef win);
AXUIElementRef _Nullable FindChildWithTitle(AXUIElementRef parent, NSString *title);
AXUIElementRef _Nullable GetFirstChildWithRole(AXUIElementRef parent, CFStringRef role);
AXUIElementRef _Nullable GetSubmenu(AXUIElementRef element);
void PostKeystrokeToPID(pid_t pid, CGKeyCode keyCode, CGEventFlags flags);

// --- Generic C utilities ---
int GetCh(void);
int CompareInt(const void *a, const void *b);
int DedupeIntArray(int *arr, int count);
void TrimEnd(char *str);
void *SafeMalloc(size_t size);
void *SafeRealloc(void *p, size_t size);
unsigned int HashString(const char *str);
void EnsureSystemPath(void);
int EnsureDirectoryExists(const char *path);
bool IsProcessRunning(const char *pattern);
int MoveFile(const char *src, const char *dst);

// --- Generic dynamic array reallocator macro ---
#define ENSURE_ARRAY_CAPACITY(ptr, count, cap, type, default_cap) \
do { \
    if ((count) >= (cap)) { \
        (cap) = (cap) == 0 ? (default_cap) : (cap) * 2; \
        (ptr) = (type *)SafeRealloc((ptr), (cap) * sizeof(type)); \
    } \
} while(0)

// --- Aerospace and launcher execution ---
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
