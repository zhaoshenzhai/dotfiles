#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <ScriptingBridge/ScriptingBridge.h>
#import <ApplicationServices/ApplicationServices.h>

// System and app process utilities
pid_t GetSkimPID(void);
void RunLauncher(NSString *targetPath);
SBApplication *GetSkimSBApp(void);
void PostKeystrokeToPID(pid_t pid, CGKeyCode keyCode, CGEventFlags flags);

// Accessibility utilities
AXUIElementRef GetFocusedWindowForPID(pid_t pid);
AXUIElementRef FindChildWithTitle(AXUIElementRef parent, NSString *title);
AXUIElementRef GetFirstChildWithRole(AXUIElementRef parent, CFStringRef role);
AXUIElementRef GetSubmenu(AXUIElementRef element);

// Document and file utilities
NSString *GetDocumentPathOfFrontmostApp(void);
NSString *ResolveCanonicalDocumentPath(NSString *rawPath);

// Commands
int switchTab(int tabIndex);
int moveTab(int targetTab);
int duplicateTab(void);
int openRelated(NSString *extension);
int cleanDuplicates(void);
int reopenLastClosed(void);
int skimSearch(NSString *action);
int switchFocus(NSString *direction);
int recordSkim(NSString *windowId);
