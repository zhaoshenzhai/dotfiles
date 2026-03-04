#include "sketchybar.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <CoreAudio/CoreAudio.h>

void handler(env env) {
    char* name = env_get_value_for_key(env, "NAME");
    char* sender = env_get_value_for_key(env, "SENDER");
    char* info = env_get_value_for_key(env, "INFO");

    if (name[0] == '\0' || sender[0] == '\0' || strcmp(sender, "volume_change") != 0 || info[0] == '\0') return;

    int volume = atoi(info);
    char* icon = "􀊣";

    if (volume >= 60) icon = "􀊩";
    else if (volume >= 30) icon = "􀊥";
    else if (volume > 0) icon = "􀊡";

    AudioObjectID defaultDeviceID = kAudioObjectUnknown;
    UInt32 propertySize = sizeof(defaultDeviceID);
    AudioObjectPropertyAddress propertyAddress = {
        kAudioHardwarePropertyDefaultOutputDevice,
        kAudioObjectPropertyScopeGlobal,
        kAudioObjectPropertyElementMain
    };

    if (AudioObjectGetPropertyData(kAudioObjectSystemObject, &propertyAddress, 0, NULL, &propertySize, &defaultDeviceID) == noErr) {
        char deviceName[256] = {0};
        propertySize = sizeof(deviceName);
        propertyAddress.mSelector = kAudioObjectPropertyName;

        if (AudioObjectGetPropertyData(defaultDeviceID, &propertyAddress, 0, NULL, &propertySize, deviceName) == noErr) {
            if (strstr(deviceName, "Headphone") != NULL ||
                strstr(deviceName, "headphone") != NULL ||
                strstr(deviceName, "AirPods") != NULL) {
                icon = "􀑈";
            }
        }
    }

    char update_message[512];
    snprintf(update_message, sizeof(update_message), "--animate tanh 8 --set %s icon=\"%s\" label=\"%d%%\"", name, icon, volume);

    sketchybar(update_message);
}

int main(int argc, char** argv) {
    event_server_begin(handler, "volume_plugin_mach");
    return 0;
}
