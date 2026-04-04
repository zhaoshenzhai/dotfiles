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

        CGFloat targetWidth = screenFrame.size.width * 0.75;
        CGFloat targetHeight = screenFrame.size.height * 0.80;
        CGSize targetSize = CGSizeMake(targetWidth, targetHeight);

        AXValueRef targetSizeValue = AXValueCreate(kAXValueCGSizeType, &targetSize);
        if (targetSizeValue) {
            AXUIElementSetAttributeValue(axWindow, kAXSizeAttribute, targetSizeValue);
            CFRelease(targetSizeValue);
        }

        CFTypeRef actualSizeRef = NULL;
        CGSize actualSize = targetSize;
        if (AXUIElementCopyAttributeValue(axWindow, kAXSizeAttribute, &actualSizeRef) == kAXErrorSuccess && actualSizeRef) {
            AXValueGetValue((AXValueRef)actualSizeRef, kAXValueCGSizeType, &actualSize);
            CFRelease(actualSizeRef);
        }

        CGFloat primaryScreenHeight = [[[NSScreen screens] objectAtIndex:0] frame].size.height;
        CGFloat axX = screenFrame.origin.x + (screenFrame.size.width - actualSize.width) / 2.0;
        CGFloat axY = primaryScreenHeight - (screenFrame.origin.y + (screenFrame.size.height + actualSize.height) / 2.0);
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
