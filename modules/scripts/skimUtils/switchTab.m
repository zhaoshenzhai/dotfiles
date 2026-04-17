#import "skimUtils.h"

int switchTab(int targetTab) {
    pid_t pid = GetSkimPID();
    if (pid == 0) return 1;

    AXUIElementRef skimApp = AXUIElementCreateApplication(pid);
    CFTypeRef window = NULL;
    if (AXUIElementCopyAttributeValue(skimApp, kAXMainWindowAttribute, &window) == kAXErrorSuccess) {
        AXUIElementRef tabGroup = GetFirstChildWithRole((AXUIElementRef)window, kAXTabGroupRole);

        if (tabGroup) {
            CFTypeRef tabs = NULL;
            if (AXUIElementCopyAttributeValue(tabGroup, kAXChildrenAttribute, &tabs) == kAXErrorSuccess) {
                CFIndex radioIndex = 1;
                for (CFIndex i = 0; i < CFArrayGetCount((CFArrayRef)tabs); i++) {
                    AXUIElementRef child = (AXUIElementRef)CFArrayGetValueAtIndex((CFArrayRef)tabs, i);
                    // Standard Radio Button check
                    if (radioIndex == targetTab) {
                        AXUIElementPerformAction(child, kAXPressAction);
                        break;
                    }
                    radioIndex++;
                }
                CFRelease(tabs);
            }
            CFRelease(tabGroup);
        }
        CFRelease(window);
    }
    CFRelease(skimApp);
    return 0;
}
