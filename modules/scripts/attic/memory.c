#include "attic.h"

void free_memory(void) {
    for (int i = 0; i < MAX_NOTES; i++) {
        if (notes[i].out_links) { free(notes[i].out_links); notes[i].out_links = NULL; }
        if (notes[i].in_links) { free(notes[i].in_links); notes[i].in_links = NULL; }
        for (int j = 0; j < notes[i].todo_count; j++) {
            if (notes[i].todos[j].text) free(notes[i].todos[j].text);
        }
        if (notes[i].todos) { free(notes[i].todos); notes[i].todos = NULL; }

        // Free the new dynamically allocated strings
        if (notes[i].keys) { free(notes[i].keys); notes[i].keys = NULL; }
        if (notes[i].meta_refs_raw) { free(notes[i].meta_refs_raw); notes[i].meta_refs_raw = NULL; }
        if (notes[i].meta_ref_in_raw) { free(notes[i].meta_ref_in_raw); notes[i].meta_ref_in_raw = NULL; }

        notes[i].out_count = notes[i].out_capacity = 0;
        notes[i].in_count = notes[i].in_capacity = 0;
        notes[i].todo_count = notes[i].todo_capacity = 0;
    }
}

void add_out_link(int src, int target, int line_no) {
    if (notes[src].out_count >= notes[src].out_capacity) {
        notes[src].out_capacity = notes[src].out_capacity == 0 ? 8 : notes[src].out_capacity * 2;
        notes[src].out_links = (OutLink*)safe_realloc(notes[src].out_links, notes[src].out_capacity * sizeof(OutLink));
    }
    notes[src].out_links[notes[src].out_count++] = (OutLink){target, line_no};
}

void add_in_link(int target, int src) {
    if (notes[target].in_count >= notes[target].in_capacity) {
        notes[target].in_capacity = notes[target].in_capacity == 0 ? 8 : notes[target].in_capacity * 2;
        notes[target].in_links = safe_realloc(notes[target].in_links, notes[target].in_capacity * sizeof(int));
    }
    notes[target].in_links[notes[target].in_count++] = src;
}

void add_todo(int id, int line_no, const char *text) {
    if (notes[id].todo_count >= notes[id].todo_capacity) {
        notes[id].todo_capacity = notes[id].todo_capacity == 0 ? 4 : notes[id].todo_capacity * 2;
        notes[id].todos = safe_realloc(notes[id].todos, notes[id].todo_capacity * sizeof(Todo));
    }
    while (isspace(*text)) text++;
    char *text_copy = strdup(text);
    trim_end(text_copy);
    notes[id].todos[notes[id].todo_count++] = (Todo){text_copy, line_no};
}

void load_memory(void) {
    free_memory();
    memset(notes, 0, sizeof(notes));
    DIR *dir = opendir(attic_dir);
    if (!dir) return;

    struct dirent *entry;
    while ((entry = readdir(dir)) != NULL) {
        if (strlen(entry->d_name) == 5 && isdigit(entry->d_name[0])) {
            int id = atoi(entry->d_name);
            notes[id].active = 1;

            char path[PATH_MAX];
            snprintf(path, sizeof(path), "%s/%05d/%05d.pdf", attic_dir, id, id);
            notes[id].has_pdf = (access(path, F_OK) == 0);

            snprintf(path, sizeof(path), "%s/%05d/%05d.key", attic_dir, id, id);
            FILE *fkey = fopen(path, "r");
            if (fkey) {
                char temp_keys[1024] = "";
                if (fgets(temp_keys, sizeof(temp_keys), fkey)) {
                    trim_end(temp_keys);
                    notes[id].keys = strdup(temp_keys);
                }
                fclose(fkey);
            }

            snprintf(path, sizeof(path), "%s/%05d/%05d.dat", attic_dir, id, id);
            FILE *fdat = fopen(path, "r");
            if (fdat) {
                char line[4096];
                while (fgets(line, sizeof(line), fdat)) {
                    char *start = line;
                    while (isspace(*start)) start++;
                    if (strncmp(start, "Last modified:", 14) == 0) {
                        sscanf(start + 14, " %63s", notes[id].mod_date);
                    } else if (strncmp(start, "References:", 11) == 0) {
                        trim_end(start); notes[id].meta_refs_raw = strdup(start);
                    } else if (strncmp(start, "Referenced in:", 14) == 0) {
                        trim_end(start); notes[id].meta_ref_in_raw = strdup(start);
                    }
                }
                fclose(fdat);
            }
        }
    }
    closedir(dir);

    for (int i = 0; i < MAX_NOTES; i++) {
        if (!notes[i].active) continue;

        char path[PATH_MAX];
        snprintf(path, sizeof(path), "%s/%05d/%05d.tex", attic_dir, i, i);
        FILE *ftex = fopen(path, "r");
        if (!ftex) continue;

        char *line = NULL; size_t len = 0; int line_no = 0;
        while (getline(&line, &len, ftex) != -1) {
            line_no++;
            if (strstr(line, "TODO")) add_todo(i, line_no, line);

            char *ptr = line;
            while ((ptr = strstr(ptr, "\\aref{")) != NULL) {
                char *scan = ptr + 6;
                while (*scan) {
                    if (strncmp(scan, "}{", 2) == 0 && isdigit(scan[2]) && scan[7] == '}') {
                        int target_id = 0;
                        for (int k = 0; k < 5; k++) target_id = target_id * 10 + (scan[2 + k] - '0');
                        add_out_link(i, target_id, line_no);
                        add_in_link(target_id, i);
                        break;
                    }
                    scan++;
                }
                ptr += 6;
            }
        }
        free(line); fclose(ftex);
    }
}
