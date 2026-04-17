#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <ScriptingBridge/ScriptingBridge.h>

pid_t GetSkimPID(void);
void RunLauncher(NSString *targetPath);
SBApplication *GetSkimSBApp(void);
AXUIElementRef GetFocusedWindowForPID(pid_t pid);
AXUIElementRef FindChildWithTitle(AXUIElementRef parent, NSString *title);
AXUIElementRef GetFirstChildWithRole(AXUIElementRef parent, CFStringRef role);
AXUIElementRef GetSubmenu(AXUIElementRef element);
NSString *GetDocumentPathOfFrontmostApp(void);
NSString *GetCurrentAerospaceWorkspace(void);
NSString *ResolveCanonicalDocumentPath(NSString *rawPath);

int switchTab(int tabIndex);
int duplicateTab(void);
int openRelated(NSString *extension);
int cleanDuplicates(void);
int reopenLastClosed(void);
