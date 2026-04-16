#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>
#include <time.h>
#include <unistd.h>
#include <ApplicationServices/ApplicationServices.h>

CFTypeRef get_ax_attribute(AXUIElementRef element, CFStringRef attribute, const char* debug_name) {
    CFTypeRef value = NULL;
    AXError err = AXUIElementCopyAttributeValue(element, attribute, &value);

    if (err != kAXErrorSuccess) return NULL;
    return value;
}

pid_t get_skim_pid() {
    FILE *cmd = popen("/usr/bin/pgrep -x Skim", "r");
    if (!cmd) return 0;

    char buf[32];
    pid_t pid = 0;
    if (fgets(buf, sizeof(buf), cmd) != NULL) {
        pid = (pid_t)strtol(buf, NULL, 10);
    }
    pclose(cmd);
    return pid;
}

int main(int argc, const char * argv[]) {
    if (argc != 2) return 1;

    int targetTab = atoi(argv[1]);
    if (!AXIsProcessTrusted()) return 1;

    pid_t pid = get_skim_pid();
    if (pid <= 0) return 1;

    AXUIElementRef skimApp = AXUIElementCreateApplication(pid);
    if (!skimApp) return 1;

    int clickSuccess = 0;
    AXUIElementRef window = (AXUIElementRef)get_ax_attribute(skimApp, kAXMainWindowAttribute, "MainWindow");

    if (window) {
        CFArrayRef children = (CFArrayRef)get_ax_attribute(window, kAXChildrenAttribute, "WindowChildren");
        if (children) {
            AXUIElementRef tabGroup = NULL;
            CFIndex count = CFArrayGetCount(children);

            for (CFIndex i = 0; i < count; i++) {
                AXUIElementRef child = (AXUIElementRef)CFArrayGetValueAtIndex(children, i);
                CFStringRef role = (CFStringRef)get_ax_attribute(child, kAXRoleAttribute, "ChildRole");
                if (role) {
                    if (CFStringCompare(role, kAXTabGroupRole, 0) == kCFCompareEqualTo) {
                        tabGroup = (AXUIElementRef)CFRetain(child);
                    }
                    CFRelease(role);
                }
                if (tabGroup) break;
            }

            if (tabGroup) {
                CFArrayRef tabs = (CFArrayRef)get_ax_attribute(tabGroup, kAXChildrenAttribute, "TabGroupChildren");
                if (tabs) {
                    CFIndex tabCount = CFArrayGetCount(tabs);
                    CFIndex radioIndex = 1;

                    for (CFIndex i = 0; i < tabCount; i++) {
                        AXUIElementRef child = (AXUIElementRef)CFArrayGetValueAtIndex(tabs, i);
                        CFStringRef role = (CFStringRef)get_ax_attribute(child, kAXRoleAttribute, "TabRole");
                        if (role) {
                            if (CFStringCompare(role, kAXRadioButtonRole, 0) == kCFCompareEqualTo) {
                                if (radioIndex == targetTab) {
                                    AXError actionErr = AXUIElementPerformAction(child, kAXPressAction);
                                    if (actionErr == kAXErrorSuccess) clickSuccess = 1;
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
