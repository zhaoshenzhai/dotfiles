#import "commonUtils.h"
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
            AXUIElementRef targetTabRef = (AXUIElementRef)CFArrayGetValueAtIndex((CFArrayRef)tabs, targetTab - 1);

            for (CFIndex i = 0; i < tabCount; i++) {
                AXUIElementRef child = (AXUIElementRef)CFArrayGetValueAtIndex((CFArrayRef)tabs, i);
                CFTypeRef value = NULL;
                if (AXUIElementCopyAttributeValue(child, kAXValueAttribute, &value) == kAXErrorSuccess) {
                    if ([(__bridge NSNumber *)value intValue] == 1) {
                        currentTabRef = child;
                        break;
                    }
                }
                if (value) CFRelease(value);
            }

            if (currentTabRef && currentTabRef != targetTabRef) {
                CFTypeRef currentPosVal = NULL, currentSizeVal = NULL;
                CFTypeRef targetPosVal = NULL, targetSizeVal = NULL;

                if (AXUIElementCopyAttributeValue(currentTabRef, kAXPositionAttribute, &currentPosVal) == kAXErrorSuccess &&
                    AXUIElementCopyAttributeValue(currentTabRef, kAXSizeAttribute, &currentSizeVal) == kAXErrorSuccess &&
                    AXUIElementCopyAttributeValue(targetTabRef, kAXPositionAttribute, &targetPosVal) == kAXErrorSuccess &&
                    AXUIElementCopyAttributeValue(targetTabRef, kAXSizeAttribute, &targetSizeVal) == kAXErrorSuccess) {

                    CGPoint currentPos, targetPos;
                    CGSize currentSize, targetSize;

                    AXValueGetValue((AXValueRef)currentPosVal, kAXValueCGPointType, &currentPos);
                    AXValueGetValue((AXValueRef)currentSizeVal, kAXValueCGSizeType, &currentSize);
                    AXValueGetValue((AXValueRef)targetPosVal, kAXValueCGPointType, &targetPos);
                    AXValueGetValue((AXValueRef)targetSizeVal, kAXValueCGSizeType, &targetSize);

                    CGPoint startPoint = CGPointMake(currentPos.x + currentSize.width / 2, currentPos.y + currentSize.height / 2);
                    CGPoint endPoint = CGPointMake(targetPos.x + targetSize.width / 2, targetPos.y + targetSize.height / 2);

                    CGEventSourceRef source = CGEventSourceCreate(kCGEventSourceStateHIDSystemState);
                    CGEventRef mouseMove = CGEventCreateMouseEvent(source, kCGEventMouseMoved, startPoint, kCGMouseButtonLeft);
                    CGEventRef mouseDown = CGEventCreateMouseEvent(source, kCGEventLeftMouseDown, startPoint, kCGMouseButtonLeft);
                    CGEventRef mouseDrag = CGEventCreateMouseEvent(source, kCGEventLeftMouseDragged, endPoint, kCGMouseButtonLeft);
                    CGEventRef mouseUp = CGEventCreateMouseEvent(source, kCGEventLeftMouseUp, endPoint, kCGMouseButtonLeft);

                    CGEventPost(kCGHIDEventTap, mouseMove);
                    usleep(5000);
                    CGEventPost(kCGHIDEventTap, mouseDown);
                    usleep(30000);
                    CGEventPost(kCGHIDEventTap, mouseDrag);
                    usleep(30000);
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
