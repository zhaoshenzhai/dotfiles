#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <ScriptingBridge/ScriptingBridge.h>

pid_t GetSkimPID(void);
AXUIElementRef GetFocusedWindowForPID(pid_t pid);
NSString *GetDocumentPathOfFrontmostApp(void);
SBApplication *GetSkimSBApp(void);
void RunLauncher(NSString *targetPath);
NSString *GetCurrentAerospaceWorkspace(void);
NSString *ResolveCanonicalDocumentPath(NSString *rawPath);

int switchTab(int tabIndex);
int duplicateTab(void);
int openRelated(NSString *extension);
int cleanDuplicates(void);
