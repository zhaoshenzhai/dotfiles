#import "commonUtils.h"

AXUIElementRef GetFocusedWindowForPID(pid_t pid) {
    if (pid == 0) return NULL;
    AXUIElementRef app = AXUIElementCreateApplication(pid);
    CFTypeRef val = NULL;
    AXUIElementRef result = NULL;
    if (AXUIElementCopyAttributeValue(app, kAXFocusedWindowAttribute, &val) == kAXErrorSuccess) {
        result = (AXUIElementRef)CFRetain(val);
        CFRelease(val);
    }
    CFRelease(app);
    return result;
}

CFArrayRef CopyAXWindows(pid_t pid) {
    if (pid == 0) return NULL;
    AXUIElementRef appElem = AXUIElementCreateApplication(pid);
    CFTypeRef val = NULL;
    CFArrayRef result = NULL;

    if (AXUIElementCopyAttributeValue(appElem, kAXWindowsAttribute, &val) == kAXErrorSuccess) {
        result = (CFArrayRef)CFRetain(val);
        CFRelease(val);
    }
    CFRelease(appElem);
    return result;
}

NSString *AXWindowTitle(AXUIElementRef win) {
    if (!win) return nil;
    CFTypeRef val = NULL;
    if (AXUIElementCopyAttributeValue(win, kAXTitleAttribute, &val) != kAXErrorSuccess) return nil;
    NSString *title = [(__bridge NSString *)val copy];
    CFRelease(val);
    return title;
}

AXUIElementRef GetFirstChildWithRole(AXUIElementRef parent, CFStringRef role) {
    if (!parent || !role) return NULL;
    CFTypeRef children = NULL;
    if (AXUIElementCopyAttributeValue(parent, kAXChildrenAttribute, &children) != kAXErrorSuccess) return NULL;

    AXUIElementRef found = NULL;
    CFIndex count = CFArrayGetCount((CFArrayRef)children);

    for (CFIndex i = 0; i < count; i++) {
        AXUIElementRef child = (AXUIElementRef)CFArrayGetValueAtIndex((CFArrayRef)children, i);
        CFTypeRef childRole = NULL;
        if (AXUIElementCopyAttributeValue(child, kAXRoleAttribute, &childRole) == kAXErrorSuccess) {
            if (CFStringCompare((CFStringRef)childRole, role, 0) == kCFCompareEqualTo) {
                found = (AXUIElementRef)CFRetain(child);
            }
            CFRelease(childRole);
            if (found) break;
        }
    }
    CFRelease(children);
    return found;
}

AXUIElementRef GetSubmenu(AXUIElementRef element) {
    return GetFirstChildWithRole(element, kAXMenuRole);
}

AXUIElementRef FindChildWithTitle(AXUIElementRef parent, NSString *title) {
    if (!parent || !title) return NULL;
    CFTypeRef children = NULL;
    if (AXUIElementCopyAttributeValue(parent, kAXChildrenAttribute, &children) != kAXErrorSuccess) return NULL;

    AXUIElementRef found = NULL;
    CFIndex count = CFArrayGetCount((CFArrayRef)children);

    for (CFIndex i = 0; i < count; i++) {
        AXUIElementRef child = (AXUIElementRef)CFArrayGetValueAtIndex((CFArrayRef)children, i);
        CFTypeRef childTitle = NULL;
        if (AXUIElementCopyAttributeValue(child, kAXTitleAttribute, &childTitle) == kAXErrorSuccess) {
            if ([(__bridge NSString *)childTitle isEqualToString:title]) {
                found = (AXUIElementRef)CFRetain(child);
            }
            CFRelease(childTitle);
            if (found) break;
        }
    }
    CFRelease(children);
    return found;
}

void PostKeystrokeToPID(pid_t pid, CGKeyCode keyCode, CGEventFlags flags) {
    if (pid == 0) return;

    CGEventSourceRef source = CGEventSourceCreate(kCGEventSourceStatePrivate);
    CGEventRef keyDown = CGEventCreateKeyboardEvent(source, keyCode, true);
    CGEventRef keyUp = CGEventCreateKeyboardEvent(source, keyCode, false);

    if (flags != 0) {
        CGEventSetFlags(keyDown, flags);
        CGEventSetFlags(keyUp, flags);
    }

    CGEventPostToPid(pid, keyDown);
    CGEventPostToPid(pid, keyUp);

    CFRelease(keyDown);
    CFRelease(keyUp);
    CFRelease(source);
}
