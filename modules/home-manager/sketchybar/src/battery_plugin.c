#include "sketchybar.h"
#include "colors.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include <pthread.h>
#include <unistd.h>
#include <CoreFoundation/CoreFoundation.h>
#include <IOKit/ps/IOPowerSources.h>
#include <IOKit/ps/IOPSKeys.h>

char item_name[256] = "battery";
pthread_mutex_t sketchybar_lock = PTHREAD_MUTEX_INITIALIZER;

void update_battery() {
    CFTypeRef power_info = IOPSCopyPowerSourcesInfo();
    CFArrayRef power_sources = IOPSCopyPowerSourcesList(power_info);

    if (!power_sources || CFArrayGetCount(power_sources) == 0) {
        if (power_info) CFRelease(power_info);
        if (power_sources) CFRelease(power_sources);
        return;
    }

    CFDictionaryRef battery_info = IOPSGetPowerSourceDescription(power_info, CFArrayGetValueAtIndex(power_sources, 0));

    bool charging = false;
    int percentage = -1;

    CFStringRef power_state = CFDictionaryGetValue(battery_info, CFSTR(kIOPSPowerSourceStateKey));
    if (power_state && CFStringCompare(power_state, CFSTR(kIOPSACPowerValue), 0) == kCFCompareEqualTo) {
        charging = true;
    }

    CFNumberRef capacity_ref = CFDictionaryGetValue(battery_info, CFSTR(kIOPSCurrentCapacityKey));
    if (capacity_ref) {
        CFNumberGetValue(capacity_ref, kCFNumberIntType, &percentage);
    }

    CFRelease(power_sources);
    CFRelease(power_info);

    if (percentage != -1) {
        char* icon = "􀛩";
        char* color = RED;

        if (charging) {
            if (percentage == 100) {
                icon = "􀛨";
                color = WHITE;
            } else {
                icon = "􀢋";
                color = GREEN;
            }
        } else {
            if (percentage >= 90) { icon = "􀛨"; color = YELLOW; }
            else if (percentage >= 60) { icon = "􀺸"; color = YELLOW; }
            else if (percentage >= 30) { icon = "􀺶"; color = ORANGE; }
        }

        char update_message[512];
        snprintf(update_message, sizeof(update_message),
                 "--animate tanh 8 --set %s icon=\"%s\" label=\"%d%%\" icon.color=%s",
                 item_name, icon, percentage, color);

        pthread_mutex_lock(&sketchybar_lock);
        sketchybar(update_message);
        pthread_mutex_unlock(&sketchybar_lock);
    }
}

void* timer_loop(void* arg) {
    while (1) {
        update_battery();
        sleep(30);
    }
    return NULL;
}

void handler(env env) {
    char* sender = env_get_value_for_key(env, "SENDER");
    if (sender && (strcmp(sender, "power_source_change") == 0 || strcmp(sender, "system_woke") == 0)) {
        update_battery();
    }
}

int main(int argc, char** argv) {
    if (argc > 1) { strncpy(item_name, argv[1], sizeof(item_name) - 1); }

    pthread_t thread_id;
    pthread_create(&thread_id, NULL, timer_loop, NULL);

    event_server_begin(handler, "battery_plugin_mach");

    return 0;
}
