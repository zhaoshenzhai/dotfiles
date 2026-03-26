#include "sketchybar.h"
#include "colors.h"
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <mach/mach.h>
#include <mach/processor_info.h>
#include <mach/mach_host.h>

void get_cpu_ticks(unsigned long long* total, unsigned long long* used) {
    host_cpu_load_info_data_t cpu_load;
    mach_msg_type_number_t count = HOST_CPU_LOAD_INFO_COUNT;
    kern_return_t kr = host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, (host_info_t)&cpu_load, &count);

    if (kr != KERN_SUCCESS) { *total = 0; *used = 0; return; }

    *used = cpu_load.cpu_ticks[CPU_STATE_USER] + cpu_load.cpu_ticks[CPU_STATE_SYSTEM] + cpu_load.cpu_ticks[CPU_STATE_NICE];
    *total = *used + cpu_load.cpu_ticks[CPU_STATE_IDLE];
}

void push_load(unsigned long long start_total, unsigned long long start_used,
               unsigned long long end_total, unsigned long long end_used) {
    float load = 0.0f;
    if (end_total > start_total) {
        load = (float)(end_used - start_used) / (float)(end_total - start_total);
    }

    char* color;
    char* color_fill;

    if (load > 0.5f) {
        color = RED;
        color_fill = RED_;
    } else if (load > 0.25f) {
        color = ORANGE;
        color_fill = ORANGE_;
    } else {
        color = WHITE;
        color_fill = WHITE_;
    }

    char command[512];
    snprintf(command, sizeof(command),
             "--push cpu %f --set cpu graph.color=%s graph.fill_color=%s --set cpu.label icon.color=%s",
             load, color, color_fill, color);

    sketchybar(command);
}

int main() {
    unsigned long long t_minus_1_total, t_minus_1_used;
    unsigned long long t_minus_05_total, t_minus_05_used;

    get_cpu_ticks(&t_minus_1_total, &t_minus_1_used);
    usleep(500000);
    get_cpu_ticks(&t_minus_05_total, &t_minus_05_used);

    while (1) {
        usleep(500000);

        unsigned long long curr_total, curr_used;
        get_cpu_ticks(&curr_total, &curr_used);
        push_load(t_minus_1_total, t_minus_1_used, curr_total, curr_used);

        t_minus_1_total = t_minus_05_total;
        t_minus_1_used  = t_minus_05_used;

        t_minus_05_total = curr_total;
        t_minus_05_used  = curr_used;
    }

    return 0;
}
