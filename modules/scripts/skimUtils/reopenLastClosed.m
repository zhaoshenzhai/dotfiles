#import "skimUtils.h"

int reopenLastClosed(void) {
    pid_t pid = GetSkimPID();
    if (pid == 0) return 1;

    AXUIElementRef skimApp = AXUIElementCreateApplication(pid);
    AXUIElementRef menuBar = NULL;
    AXUIElementCopyAttributeValue(skimApp, kAXMenuBarAttribute, (CFTypeRef *)&menuBar);

    if (menuBar) {
        AXUIElementRef fileMenuItem = FindChildWithTitle(menuBar, @"File");
        if (fileMenuItem) {
            AXUIElementRef fileMenu = GetSubmenu(fileMenuItem);
            if (fileMenu) {
                AXUIElementRef openRecentItem = FindChildWithTitle(fileMenu, @"Open Recent");
                if (openRecentItem) {
                    AXUIElementRef recentMenu = GetSubmenu(openRecentItem);
                    if (recentMenu) {
                        CFTypeRef items = NULL;
                        if (AXUIElementCopyAttributeValue(recentMenu, kAXChildrenAttribute, &items) == kAXErrorSuccess) {
                            if (CFArrayGetCount((CFArrayRef)items) > 0) {
                                // Trigger the first item (most recently closed)
                                AXUIElementPerformAction((AXUIElementRef)CFArrayGetValueAtIndex((CFArrayRef)items, 0), kAXPressAction);
                            }
                            CFRelease(items);
                        }
                        CFRelease(recentMenu);
                    }
                    CFRelease(openRecentItem);
                }
                CFRelease(fileMenu);
            }
            CFRelease(fileMenuItem);
        }
        CFRelease(menuBar);
    }
    CFRelease(skimApp);
    return 0;
}
