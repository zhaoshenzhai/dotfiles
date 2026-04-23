#pragma once

#include <ScriptingBridge/ScriptingBridge.h>
#include <Foundation/Foundation.h>
#include <AppKit/AppKit.h>

// --- System and App Process Utilities ---
pid_t GetSkimPID(void);
SBApplication *GetSkimSBApp(void);

// --- Document and File Utilities ---
NSString *GetDocumentPathOfFrontmostApp(void);
NSString *ResolveCanonicalDocumentPath(NSString *rawPath);

// --- Commands ---
int switchTab(int tabIndex);
int moveTab(int targetTab);
int duplicateTab(void);
int openRelated(NSString *extension);
int cleanDuplicates(void);
int reopenLastClosed(void);
int skimSearch(NSString *action);
int switchFocus(NSString *direction);
