#import "skimUtils.h"

int moveTab(int targetTab) {
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
            CFIndex tabCount = CFArrayGetCount((CFArrayRef)tabs);
            if (targetTab < 1 || targetTab > tabCount) goto cleanup;

            AXUIElementRef currentTabRef = NULL;
            // Arrays are 0-indexed, so targetTab 1 is index 0
            AXUIElementRef targetTabRef = (AXUIElementRef)CFArrayGetValueAtIndex((CFArrayRef)tabs, targetTab - 1);

            // Find the currently selected tab (the one with value == 1)
            for (CFIndex i = 0; i < tabCount; i++) {
                AXUIElementRef child = (AXUIElementRef)CFArrayGetValueAtIndex((CFArrayRef)tabs, i);
                CFTypeRef value = NULL;
                if (AXUIElementCopyAttributeValue(child, kAXValueAttribute, &value) == kAXErrorSuccess) {
                    if ([(__bridge NSNumber *)value intValue] == 1) {
                        currentTabRef = child;
                        CFRelease(value);
                        break;
                    }
                    CFRelease(value);
                }
            }

            if (currentTabRef && currentTabRef != targetTabRef) {
                CFTypeRef currentPosVal = NULL, currentSizeVal = NULL;
                CFTypeRef targetPosVal = NULL, targetSizeVal = NULL;
                CGPoint currentPos, targetPos;
                CGSize currentSize, targetSize;

                // Extract screen coordinates and sizes
                if (AXUIElementCopyAttributeValue(currentTabRef, kAXPositionAttribute, &currentPosVal) == kAXErrorSuccess &&
                    AXUIElementCopyAttributeValue(currentTabRef, kAXSizeAttribute, &currentSizeVal) == kAXErrorSuccess &&
                    AXUIElementCopyAttributeValue(targetTabRef, kAXPositionAttribute, &targetPosVal) == kAXErrorSuccess &&
                    AXUIElementCopyAttributeValue(targetTabRef, kAXSizeAttribute, &targetSizeVal) == kAXErrorSuccess) {

                    AXValueGetValue((AXValueRef)currentPosVal, kAXValueCGPointType, &currentPos);
                    AXValueGetValue((AXValueRef)currentSizeVal, kAXValueCGSizeType, &currentSize);
                    AXValueGetValue((AXValueRef)targetPosVal, kAXValueCGPointType, &targetPos);
                    AXValueGetValue((AXValueRef)targetSizeVal, kAXValueCGSizeType, &targetSize);

                    // Calculate the dead-center of both tabs
                    CGPoint startPoint = CGPointMake(currentPos.x + currentSize.width / 2.0, currentPos.y + currentSize.height / 2.0);
                    CGPoint endPoint = CGPointMake(targetPos.x + targetSize.width / 2.0, targetPos.y + targetSize.height / 2.0);

                    // Perform high-speed CoreGraphics Mouse Drag
                    CGEventSourceRef source = CGEventSourceCreate(kCGEventSourceStateHIDSystemState);

                    CGEventRef mouseMove = CGEventCreateMouseEvent(source, kCGEventMouseMoved, startPoint, kCGMouseButtonLeft);
                    CGEventRef mouseDown = CGEventCreateMouseEvent(source, kCGEventLeftMouseDown, startPoint, kCGMouseButtonLeft);
                    CGEventRef mouseDrag = CGEventCreateMouseEvent(source, kCGEventLeftMouseDragged, endPoint, kCGMouseButtonLeft);
                    CGEventRef mouseUp = CGEventCreateMouseEvent(source, kCGEventLeftMouseUp, endPoint, kCGMouseButtonLeft);

                    // Post events with micro-delays to ensure the macOS UI thread registers the drag
                    CGEventPost(kCGHIDEventTap, mouseMove);
                    usleep(5000); // 5ms
                    CGEventPost(kCGHIDEventTap, mouseDown);
                    usleep(30000); // 30ms
                    CGEventPost(kCGHIDEventTap, mouseDrag);
                    usleep(30000); // 30ms
                    CGEventPost(kCGHIDEventTap, mouseUp);

                    CFRelease(mouseMove);
                    CFRelease(mouseDown);
                    CFRelease(mouseDrag);
                    CFRelease(mouseUp);
                    CFRelease(source);
                }

                if (currentPosVal) CFRelease(currentPosVal);
                if (currentSizeVal) CFRelease(currentSizeVal);
                if (targetPosVal) CFRelease(targetPosVal);
                if (targetSizeVal) CFRelease(targetSizeVal);
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
