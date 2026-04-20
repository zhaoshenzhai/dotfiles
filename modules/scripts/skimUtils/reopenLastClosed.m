#import "commonUtils.h"
#import "skimUtils.h"

int reopenLastClosed(void) {
    @autoreleasepool {
        pid_t pid = GetSkimPID();
        if (pid == 0) return 1;

        AXUIElementRef skimApp = AXUIElementCreateApplication(pid);
        AXUIElementRef menuBar = NULL;
        AXUIElementRef fileMenuItem = NULL;
        AXUIElementRef fileMenu = NULL;
        AXUIElementRef openRecentItem = NULL;
        AXUIElementRef recentMenu = NULL;
        CFTypeRef items = NULL;

        if (AXUIElementCopyAttributeValue(skimApp, kAXMenuBarAttribute, (CFTypeRef *)&menuBar) != kAXErrorSuccess) goto cleanup;

        fileMenuItem = FindChildWithTitle(menuBar, @"File");
        if (!fileMenuItem) goto cleanup;

        fileMenu = GetSubmenu(fileMenuItem);
        if (!fileMenu) goto cleanup;

        openRecentItem = FindChildWithTitle(fileMenu, @"Open Recent");
        if (!openRecentItem) goto cleanup;

        recentMenu = GetSubmenu(openRecentItem);
        if (!recentMenu) goto cleanup;

        if (AXUIElementCopyAttributeValue(recentMenu, kAXChildrenAttribute, &items) == kAXErrorSuccess) {
            if (CFArrayGetCount((CFArrayRef)items) > 0) {
                AXUIElementPerformAction((AXUIElementRef)CFArrayGetValueAtIndex((CFArrayRef)items, 0), kAXPressAction);
            }
        }

    cleanup:
        if (items) CFRelease(items);
        if (recentMenu) CFRelease(recentMenu);
        if (openRecentItem) CFRelease(openRecentItem);
        if (fileMenu) CFRelease(fileMenu);
        if (fileMenuItem) CFRelease(fileMenuItem);
        if (menuBar) CFRelease(menuBar);
        if (skimApp) CFRelease(skimApp);
    }
    return 0;
}
