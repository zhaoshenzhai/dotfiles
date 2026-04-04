#import <Cocoa/Cocoa.h>

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        NSScreen *screen = [NSScreen mainScreen];
        if (!screen) return 1;
        NSRect screenFrame = [screen visibleFrame];

        NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
        NSRunningApplication *frontApp = [workspace frontmostApplication];
        if (!frontApp) return 1;
        pid_t pid = [frontApp processIdentifier];

        AXUIElementRef appElement = AXUIElementCreateApplication(pid);
        if (!appElement) return 1;

        CFTypeRef focusedWindow = NULL;
        AXError result = AXUIElementCopyAttributeValue(appElement, kAXFocusedWindowAttribute, &focusedWindow);
        if (result != kAXErrorSuccess || !focusedWindow) {
            CFRelease(appElement);
            return 1;
        }
        AXUIElementRef axWindow = (AXUIElementRef)focusedWindow;

        CFTypeRef sizeRef = NULL;
        result = AXUIElementCopyAttributeValue(axWindow, kAXSizeAttribute, &sizeRef);
        if (result != kAXErrorSuccess || !sizeRef) {
            CFRelease(axWindow);
            CFRelease(appElement);
            return 1;
        }
        CGSize size = CGSizeZero;
        AXValueGetValue((AXValueRef)sizeRef, kAXValueCGSizeType, &size);
        CFRelease(sizeRef);

        CGFloat primaryScreenHeight = [[[NSScreen screens] objectAtIndex:0] frame].size.height;
        CGFloat axX = screenFrame.origin.x + (screenFrame.size.width - size.width) / 2.0;
        CGFloat axY = primaryScreenHeight - (screenFrame.origin.y + (screenFrame.size.height + size.height) / 2.0);
        CGPoint newPoint = CGPointMake(axX, axY);

        AXValueRef positionValue = AXValueCreate(kAXValueCGPointType, &newPoint);
        if (positionValue) {
            AXUIElementSetAttributeValue(axWindow, kAXPositionAttribute, positionValue);
            CFRelease(positionValue);
        }

        CFRelease(axWindow);
        CFRelease(appElement);
    }
    return 0;
}
