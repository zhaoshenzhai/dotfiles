#import "commonUtils.h"
#import "skimUtils.h"

int switchTab(int targetTab) {
    @autoreleasepool {
        pid_t pid = GetSkimPID();
        if (pid == 0) return 1;

        AXUIElementRef skimApp = AXUIElementCreateApplication(pid);
        CFTypeRef window = NULL;
        AXUIElementRef tabGroup = NULL;
        CFTypeRef tabs = NULL;

        if (AXUIElementCopyAttributeValue(skimApp, kAXMainWindowAttribute, &window) != kAXErrorSuccess) goto cleanup;

        tabGroup = GetFirstChildWithRole((AXUIElementRef)window, kAXTabGroupRole);
        if (!tabGroup) goto cleanup;

        if (AXUIElementCopyAttributeValue(tabGroup, kAXChildrenAttribute, &tabs) == kAXErrorSuccess) {
            CFIndex radioIndex = 1;
            for (CFIndex i = 0; i < CFArrayGetCount((CFArrayRef)tabs); i++) {
                AXUIElementRef child = (AXUIElementRef)CFArrayGetValueAtIndex((CFArrayRef)tabs, i);
                if (radioIndex == targetTab) {
                    AXUIElementPerformAction(child, kAXPressAction);
                    break;
                }
                radioIndex++;
            }
        }

    cleanup:
        if (tabs) CFRelease(tabs);
        if (tabGroup) CFRelease(tabGroup);
        if (window) CFRelease(window);
        if (skimApp) CFRelease(skimApp);
    }
    return 0;
}
