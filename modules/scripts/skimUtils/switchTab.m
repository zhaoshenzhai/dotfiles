#import "skimUtils.h"

int switchTab(int targetTab) {
    NSArray *apps = [NSRunningApplication runningApplicationsWithBundleIdentifier:@"net.sourceforge.skim-app.skim"];
    pid_t pid = 0;
    for (NSRunningApplication *app in apps) {
        if (app.activationPolicy == NSApplicationActivationPolicyRegular) {
            pid = app.processIdentifier;
            break;
        }
    }
    if (pid == 0) return 1;

    AXUIElementRef skimApp = AXUIElementCreateApplication(pid);
    if (!skimApp) return 1;

    CFTypeRef window = NULL;
    if (AXUIElementCopyAttributeValue(skimApp, kAXMainWindowAttribute, &window) == kAXErrorSuccess) {
        CFTypeRef children = NULL;
        if (AXUIElementCopyAttributeValue((AXUIElementRef)window, kAXChildrenAttribute, &children) == kAXErrorSuccess) {
            AXUIElementRef tabGroup = NULL;
            CFIndex count = CFArrayGetCount((CFArrayRef)children);

            for (CFIndex i = 0; i < count; i++) {
                AXUIElementRef child = (AXUIElementRef)CFArrayGetValueAtIndex((CFArrayRef)children, i);
                CFTypeRef role = NULL;
                if (AXUIElementCopyAttributeValue(child, kAXRoleAttribute, &role) == kAXErrorSuccess) {
                    if (CFStringCompare((CFStringRef)role, kAXTabGroupRole, 0) == kCFCompareEqualTo) {
                        tabGroup = (AXUIElementRef)CFRetain(child);
                    }
                    CFRelease(role);
                }
                if (tabGroup) break;
            }

            if (tabGroup) {
                CFTypeRef tabs = NULL;
                if (AXUIElementCopyAttributeValue(tabGroup, kAXChildrenAttribute, &tabs) == kAXErrorSuccess) {
                    CFIndex tabCount = CFArrayGetCount((CFArrayRef)tabs);
                    CFIndex radioIndex = 1;

                    for (CFIndex i = 0; i < tabCount; i++) {
                        AXUIElementRef child = (AXUIElementRef)CFArrayGetValueAtIndex((CFArrayRef)tabs, i);
                        CFTypeRef role = NULL;
                        if (AXUIElementCopyAttributeValue(child, kAXRoleAttribute, &role) == kAXErrorSuccess) {
                            if (CFStringCompare((CFStringRef)role, kAXRadioButtonRole, 0) == kCFCompareEqualTo) {
                                if (radioIndex == targetTab) {
                                    AXUIElementPerformAction(child, kAXPressAction);
                                    CFRelease(role);
                                    break;
                                }
                                radioIndex++;
                            }
                            CFRelease(role);
                        }
                    }
                    CFRelease(tabs);
                }
                CFRelease(tabGroup);
            }
            CFRelease(children);
        }
        CFRelease(window);
    }

    CFRelease(skimApp);
    return 0;
}
