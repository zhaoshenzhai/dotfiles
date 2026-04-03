#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <dirent.h>
#include <unistd.h>
#include <termios.h>
#include <sys/stat.h>
#include <sys/wait.h>
#include <time.h>
#include <getopt.h>
#include <limits.h>
#include <libproc.h>
#include <errno.h>

#define MAX_NOTES 100000
#define MAX_JOBS 5

#define RED "\x1b[31m"
#define GREEN "\x1b[32m"
#define YELLOW "\x1b[33m"
#define BLUE "\x1b[34m"
#define PURPLE "\x1b[35m"
#define CYAN "\x1b[36m"
#define NC "\x1b[0m"

char attic_dir[PATH_MAX];
char template_file[PATH_MAX];
char launcher_path[PATH_MAX];
int is_interactive = 0;

typedef struct { int target_id; int line_no; } OutLink;
typedef struct { char *text; int line_no; } Todo;

typedef struct {
    int active;
    int has_pdf;
    char keys[256];
    char mod_date[64];

    OutLink *out_links;
    int out_count;
    int out_capacity;

    int *in_links;
    int in_count;
    int in_capacity;

    Todo *todos;
    int todo_count;
    int todo_capacity;

    char meta_refs_raw[2048];
    char meta_ref_in_raw[2048];
} Note;

Note notes[MAX_NOTES];

// Utility functions
void* safe_malloc(size_t size) {
    void* p = malloc(size);
    if (!p && size > 0) {
        fprintf(stderr, "%sError: Out of memory (malloc failed)%s\n", RED, NC);
        exit(1);
    }
    return p;
}
void* safe_realloc(void* p, size_t size) {
    void* new_p = realloc(p, size);
    if (!new_p && size > 0) {
        fprintf(stderr, "%sError: Out of memory (realloc failed)%s\n", RED, NC);
        exit(1);
    }
    return new_p;
}
int getch(void) {
    struct termios oldattr, newattr;
    int ch;

    tcgetattr(STDIN_FILENO, &oldattr);
    newattr = oldattr;
    newattr.c_lflag &= ~(ICANON | ECHO);
    tcsetattr(STDIN_FILENO, TCSANOW, &newattr);
    ch = getchar();
    tcsetattr(STDIN_FILENO, TCSANOW, &oldattr);

    return ch;
}
void trim_end(char *str) {
    int len = strlen(str);
    while (len > 0 && (isspace(str[len - 1]) || str[len - 1] == '\\')) {
        str[len - 1] = '\0';
        len--;
    }
}
int cmp_int(const void *a, const void *b) {
    return (*(int *)a - *(int *)b);
}
int dedupe(int *arr, int count) {
    if (count == 0) return 0;
    qsort(arr, count, sizeof(int), cmp_int);
    int j = 0;
    for (int i = 1; i < count; i++) {
        if (arr[i] != arr[j]) {
            j++;
            arr[j] = arr[i];
        }
    }
    return j + 1;
}
void format_links(int *ids, int count, char *out_buf) {
    out_buf[0] = '\0';
    int unique_count = dedupe(ids, count);
    for (int i = 0; i < unique_count; i++) {
        if (i > 0) strcat(out_buf, ", ");
        char temp[32];
        snprintf(temp, sizeof(temp), "\\aref{%05d}{%05d}", ids[i], ids[i]);
        strcat(out_buf, temp);
    }
}
int is_compiling(int id) {
    char target[32];
    snprintf(target, sizeof(target), "%05d.tex", id);

    int n_procs = proc_listpids(PROC_ALL_PIDS, 0, NULL, 0);
    if (n_procs <= 0) return 0;

    pid_t pids[n_procs];
    n_procs = proc_listpids(PROC_ALL_PIDS, 0, pids, sizeof(pids));

    for (int i = 0; i < n_procs; i++) {
        if (pids[i] <= 0) continue;
        char path_buf[PROC_PIDPATHINFO_MAXSIZE];

        if (proc_pidpath(pids[i], path_buf, sizeof(path_buf)) > 0) {
            if (strstr(path_buf, "latexmk") || strstr(path_buf, "pdflatex")) {
                return 1;
            }
        }
    }
    return 0;
}
void compile_note_async(int id) {
    if (is_compiling(id)) return;

    char cmd[2048];
    snprintf(cmd, sizeof(cmd),
        "cd '%s/%05d' && nohup latexmk -pdf -pvc- -interaction=nonstopmode %05d.tex > /dev/null 2>&1 &",
        attic_dir, id, id);

    system(cmd);
}
void extract_ids_from_string(const char *str, int *arr, int *count) {
    const char *ptr = str;
    while (*ptr) {
        if (isdigit(*ptr)) {
            int valid = 1;
            for (int i = 0; i < 5; i++) if (!isdigit(ptr[i])) valid = 0;
            if (valid) {
                arr[(*count)++] = atoi(ptr);
                ptr += 4;
            }
        }
        ptr++;
    }
}
void free_graph() {
    for (int i = 0; i < MAX_NOTES; i++) {
        if (notes[i].out_links) { free(notes[i].out_links); notes[i].out_links = NULL; }
        if (notes[i].in_links) { free(notes[i].in_links); notes[i].in_links = NULL; }
        for (int j = 0; j < notes[i].todo_count; j++) {
            if (notes[i].todos[j].text) free(notes[i].todos[j].text);
        }
        if (notes[i].todos) { free(notes[i].todos); notes[i].todos = NULL; }
        notes[i].out_count = notes[i].out_capacity = 0;
        notes[i].in_count = notes[i].in_capacity = 0;
        notes[i].todo_count = notes[i].todo_capacity = 0;
    }
}

// Load graph of links
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
        notes[target].in_links = realloc(notes[target].in_links, notes[target].in_capacity * sizeof(int));
    }
    notes[target].in_links[notes[target].in_count++] = src;
}
void add_todo(int id, int line_no, const char *text) {
    if (notes[id].todo_count >= notes[id].todo_capacity) {
        notes[id].todo_capacity = notes[id].todo_capacity == 0 ? 4 : notes[id].todo_capacity * 2;
        notes[id].todos = realloc(notes[id].todos, notes[id].todo_capacity * sizeof(Todo));
    }
    while (isspace(*text)) text++;
    char *text_copy = strdup(text);
    trim_end(text_copy);
    notes[id].todos[notes[id].todo_count++] = (Todo){text_copy, line_no};
}
void load_graph() {
    free_graph();
    memset(notes, 0, sizeof(notes));
    DIR *dir = opendir(attic_dir);
    if (!dir) return;

    struct dirent *entry;
    while ((entry = readdir(dir)) != NULL) {
        if (strlen(entry->d_name) == 5 && isdigit(entry->d_name[0])) {
            int id = atoi(entry->d_name);
            notes[id].active = 1;

            char path[1024];
            snprintf(path, sizeof(path), "%s/%05d/%05d.pdf", attic_dir, id, id);
            notes[id].has_pdf = (access(path, F_OK) == 0);

            snprintf(path, sizeof(path), "%s/%05d/%05d.key", attic_dir, id, id);
            FILE *fkey = fopen(path, "r");
            if (fkey) {
                if (fgets(notes[id].keys, sizeof(notes[id].keys), fkey)) trim_end(notes[id].keys);
                fclose(fkey);
            }

            snprintf(path, sizeof(path), "%s/%05d/%05d.dat", attic_dir, id, id);
            FILE *fdat = fopen(path, "r");
            if (fdat) {
                char line[2048];
                while (fgets(line, sizeof(line), fdat)) {
                    char *start = line;
                    while (isspace(*start)) start++;
                    if (strncmp(start, "Last modified:", 14) == 0) {
                        sscanf(start + 14, " %63s", notes[id].mod_date);
                    } else if (strncmp(start, "References:", 11) == 0) {
                        trim_end(start); strcpy(notes[id].meta_refs_raw, start);
                    } else if (strncmp(start, "Referenced in:", 14) == 0) {
                        trim_end(start); strcpy(notes[id].meta_ref_in_raw, start);
                    }
                }
                fclose(fdat);
            }
        }
    }
    closedir(dir);

    for (int i = 0; i < MAX_NOTES; i++) {
        if (!notes[i].active) continue;

        char path[1024];
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

// Commands
int generate_metadata(int id, int update_modified) {
    if (!notes[id].active) {
        printf("%sError: Note %05d does not exist.%s\n", RED, id, NC);
        return 1;
    }

    char mod_date[64] = "";
    if (update_modified || strlen(notes[id].mod_date) == 0) {
        struct stat st;
        char tex_path[1024];
        snprintf(tex_path, sizeof(tex_path), "%s/%05d/%05d.tex", attic_dir, id, id);
        if (stat(tex_path, &st) == 0) {
            struct tm *tm_info = localtime(&st.st_mtime);
            strftime(mod_date, sizeof(mod_date), "%Y/%m/%d", tm_info);
        }
    } else {
        strcpy(mod_date, notes[id].mod_date);
    }

    int temp_out[notes[id].out_count > 0 ? notes[id].out_count : 1];
    for (int j = 0; j < notes[id].out_count; j++) temp_out[j] = notes[id].out_links[j].target_id;

    char refs[2048], ref_in[2048];
    format_links(temp_out, notes[id].out_count, refs);
    format_links(notes[id].in_links, notes[id].in_count, ref_in);

    char generated[8192];
    snprintf(generated, sizeof(generated),
        "\\begin{flushleft}\n"
        "    \\color{gray}\\footnotesize\\ttfamily\n"
        "    Last modified: %s \\\\\n"
        "    Keywords: [%s] \\\\\n"
        "    References: [%s] \\\\\n"
        "    Referenced in: [%s]\n"
        "\\end{flushleft}\n",
        mod_date, notes[id].keys, refs, ref_in);

    char dat_path[PATH_MAX];
    snprintf(dat_path, sizeof(dat_path), "%s/%05d/%05d.dat", attic_dir, id, id);

    FILE *fmeta = fopen(dat_path, "w");
    if (!fmeta) {
        fprintf(stderr, "%sError: Could not open %s for writing: %s%s\n",
                RED, dat_path, strerror(errno), NC);
        return 1;
    }
    fputs(generated, fmeta);
    fclose(fmeta);
    return 0;
}
void create_note(const char *in_keywords) {
    char cmd[2048];
    snprintf(cmd, sizeof(cmd), "mkdir -p \"%s\"", attic_dir);
    system(cmd);

    int id;
    char path[1024];
    srand(time(NULL));
    while (1) {
        id = rand() % 100000;
        snprintf(path, sizeof(path), "%s/%05d", attic_dir, id);
        if (access(path, F_OK) != 0) break;
    }

    mkdir(path, 0755);
    snprintf(cmd, sizeof(cmd), "cp \"%s\" \"%s/%05d.tex\"", template_file, path, id);
    system(cmd);

    char keywords[256] = "";
    if (strcmp(in_keywords, "EMPTY_KEYWORDS") == 0) {
        printf("Note %05d created automatically.\n", id);
    } else if (strlen(in_keywords) > 0) {
        strncpy(keywords, in_keywords, sizeof(keywords)-1);
        printf("Note %05d created automatically.\n", id);
    } else {
        printf("%sEnter keywords for note %05d: %s", PURPLE, id, NC);
        if (fgets(keywords, sizeof(keywords), stdin)) {
            trim_end(keywords);
        }
    }

    char clean_keys[512] = "";
    int j = 0;
    for(int i = 0; keywords[i] != '\0'; i++) {
        if(keywords[i] == ',') { clean_keys[j++] = ','; clean_keys[j++] = ' '; }
        else { clean_keys[j++] = keywords[i]; }
    }
    char final_keys[512] = "";
    int k = 0;
    for(int i = 0; clean_keys[i] != '\0'; i++) {
        if(clean_keys[i] == ' ' && clean_keys[i+1] == ' ') continue;
        final_keys[k++] = clean_keys[i];
    }

    snprintf(path, sizeof(path), "%s/%05d/%05d.key", attic_dir, id, id);
    FILE *fkey = fopen(path, "w");
    if (fkey) { fputs(final_keys, fkey); fputs("\n", fkey); fclose(fkey); }

    load_graph();
    generate_metadata(id, 1);

    snprintf(cmd, sizeof(cmd), "%s --update &", launcher_path);
    system(cmd);
    compile_note_async(id);

    if (is_interactive) {
        snprintf(cmd, sizeof(cmd), "nohup %s \"%s/%05d/%05d.tex\" >/dev/null 2>&1 &", launcher_path, attic_dir, id, id);
        system(cmd);
        usleep(100000);
        exit(0);
    }
}
void update_metadata(int id) {
    if (!notes[id].active) return;

    int old_ids[1000];
    int old_count = 0;
    extract_ids_from_string(notes[id].meta_refs_raw, old_ids, &old_count);
    old_count = dedupe(old_ids, old_count);

    int new_ids[1000];
    int new_count = notes[id].out_count;
    for (int i = 0; i < new_count; i++) new_ids[i] = notes[id].out_links[i].target_id;
    new_count = dedupe(new_ids, new_count);

    int links_changed = 0;
    if (old_count != new_count) {
        links_changed = 1;
    } else {
        for (int i = 0; i < old_count; i++) {
            if (old_ids[i] != new_ids[i]) {
                links_changed = 1;
                break;
            }
        }
    }

    generate_metadata(id, 1);
    compile_note_async(id);

    if (links_changed) {
        printf("%sLinks changed. Propagating metadata to neighbors...%s\n", YELLOW, NC);

        int combined_refs[2000];
        int combined_count = 0;
        for (int i = 0; i < old_count; i++) combined_refs[combined_count++] = old_ids[i];
        for (int i = 0; i < new_count; i++) combined_refs[combined_count++] = new_ids[i];

        int unique_count = dedupe(combined_refs, combined_count);

        for (int i = 0; i < unique_count; i++) {
            int ref_id = combined_refs[i];
            if (ref_id != id && notes[ref_id].active) {
                generate_metadata(ref_id, 0);
                compile_note_async(ref_id);
            }
        }
    } else {
        printf("%sNo link changes detected. Skipping neighbor updates.%s\n", GREEN, NC);
    }
}
void audit_notes() {
    load_graph();
    printf("%sVerifying links, missing PDFs, and scanning for TODOs...%s\n", BLUE, NC);
    int broken = 0, todos = 0, desync = 0, missing_pdfs = 0;

    for (int i = 0; i < MAX_NOTES; i++) {
        if (!notes[i].active) continue;

        if (!notes[i].has_pdf) {
            printf("%s[MISSING PDF]%s Note %05d[%s] has no compiled PDF.\n",
                   RED, NC, i, notes[i].keys);
            missing_pdfs++;
        }

        for (int j = 0; j < notes[i].out_count; j++) {
            int target = notes[i].out_links[j].target_id;
            int lno = notes[i].out_links[j].line_no;

            char err[32] = "";
            if (!notes[target].active) strcat(err, "TEX");
            if (!notes[target].has_pdf) {
                if (err[0] != '\0') strcat(err, " & ");
                strcat(err, "PDF");
            }

            if (err[0] != '\0') {
                printf("%s[BROKEN LINK]%s ID %05d (Missing %s) referenced in %05d[%s]:%d\n",
                       RED, NC, target, err, i, notes[i].keys, lno);
                broken++;
            }
        }

        for (int j = 0; j < notes[i].todo_count; j++) {
            printf("%s[TODO]%s %05d[%s]:%d -> %s\n",
                   YELLOW, NC, i, notes[i].keys, notes[i].todos[j].line_no, notes[i].todos[j].text);
            todos++;
        }

        int temp_out[notes[i].out_count > 0 ? notes[i].out_count : 1];
        for (int j = 0; j < notes[i].out_count; j++) temp_out[j] = notes[i].out_links[j].target_id;

        char expected_refs[4096], formatted_refs[2048];
        format_links(temp_out, notes[i].out_count, formatted_refs);
        snprintf(expected_refs, sizeof(expected_refs), "References: [%s]", formatted_refs);

        char expected_ref_in[4096], formatted_ref_in[2048];
        format_links(notes[i].in_links, notes[i].in_count, formatted_ref_in);
        snprintf(expected_ref_in, sizeof(expected_ref_in), "Referenced in: [%s]", formatted_ref_in);

        if (strcmp(expected_refs, notes[i].meta_refs_raw) != 0 || strcmp(expected_ref_in, notes[i].meta_ref_in_raw) != 0) {
            printf("%s[DESYNC]%s Metadata for %05d[%s] out of sync.\n", PURPLE, NC, i, notes[i].keys);
            desync++;
        }
    }

    printf("----------------------------------------\n");
    if (broken == 0 && missing_pdfs == 0) {
        printf("%sLinks & PDFs: Valid!%s\n", GREEN, NC);
    } else {
        if (broken > 0) printf("%sLinks: Found %d broken link(s).%s\n", RED, broken, NC);
        if (missing_pdfs > 0) printf("%sPDFs: Found %d missing PDF(s).%s\n", RED, missing_pdfs, NC);
    }

    if (desync == 0) printf("%sMetadata: Valid!%s\n", GREEN, NC);
    else printf("%sMetadata: %d note(s) have desynchronized metadata. Run 'rebuild all' (r) to fix.%s\n", PURPLE, desync, NC);

    if (todos == 0) printf("%sTODOs: None found!%s\n", GREEN, NC);
    else printf("%sTODOs: You have %d pending TODO(s).%s\n", YELLOW, todos, NC);
}
void rebuild_notes() {
    int total_notes = 0;
    for (int i = 0; i < MAX_NOTES; i++) { if (notes[i].active) total_notes++; }

    if (total_notes == 0) {
        printf("%sNo notes found to rebuild.%s\n", GREEN, NC);
        return;
    }

    printf("%sChecking modification times and refreshing metadata...%s\n", BLUE, NC);

    int running_jobs = 0, total_processed = 0, total_rebuilt = 0;

    for (int i = 0; i < MAX_NOTES; i++) {
        if (!notes[i].active) continue;

        total_processed++;

        char tex_path[1024], pdf_path[1024];
        struct stat st_tex, st_pdf;
        snprintf(tex_path, sizeof(tex_path), "%s/%05d/%05d.tex", attic_dir, i, i);
        snprintf(pdf_path, sizeof(pdf_path), "%s/%05d/%05d.pdf", attic_dir, i, i);

        int needs_rebuild = 0;
        if (stat(tex_path, &st_tex) == 0) {
            if (stat(pdf_path, &st_pdf) != 0 || st_tex.st_mtime > st_pdf.st_mtime) {
                needs_rebuild = 1;
            }
        }

        generate_metadata(i, 0);

        if (!needs_rebuild) {
            printf("\r\033[2K%sSkipping %05d (up to date) [%d/%d]%s", GREEN, i, total_processed, total_notes, NC);
            fflush(stdout);
            continue;
        }

        while (running_jobs >= MAX_JOBS) {
            int status;
            if (waitpid(-1, &status, 0) > 0) {
                running_jobs--;
            }
        }

        pid_t pid = fork();
        if (pid == 0) {
            char dir_path[1024]; snprintf(dir_path, sizeof(dir_path), "%s/%05d", attic_dir, i);
            if (chdir(dir_path) != 0) exit(1);
            char tex_file[32]; snprintf(tex_file, sizeof(tex_file), "%05d.tex", i);

            freopen("/dev/null", "w", stdout);
            freopen("/dev/null", "w", stderr);

            execlp("latexmk", "latexmk", "-pdf", "-pvc-", "-interaction=nonstopmode", tex_file, NULL);
            exit(1);
        } else if (pid > 0) {
            running_jobs++;
            total_rebuilt++;
            printf("\r\033[2K%sRebuilding %05d (%d/%d)...%s", YELLOW, i, total_processed, total_notes, NC);
            fflush(stdout);
        }
    }

    while (running_jobs > 0) {
        int status;
        if (waitpid(-1, &status, 0) > 0) {
            running_jobs--;
        }
    }

    printf("\r\033[2K%sRebuild complete. Processed %d notes, %d were recompiled.%s\n", GREEN, total_processed, total_rebuilt, NC);
    load_graph();
}
void clean_attic() {
    printf("%sCleaning auxiliary and PDF files from all notes...%s\n", BLUE, NC);
    int cleaned_count = 0;

    const char *extensions[] = {
        ".aux", ".bbl", ".bcf", ".bcf-SAVE-ERROR", ".bbl-SAVE-ERROR",
        ".blg", ".fdb_latexmk", ".fls", ".log", ".run.xml",
        ".synctex.gz", ".synctex(busy)", ".pdf"
    };
    int num_exts = sizeof(extensions) / sizeof(extensions[0]);

    for (int i = 0; i < MAX_NOTES; i++) {
        if (!notes[i].active) continue;

        char dir_path[1024];
        snprintf(dir_path, sizeof(dir_path), "%s/%05d", attic_dir, i);

        DIR *d = opendir(dir_path);
        if (!d) continue;

        int note_cleaned = 0;
        struct dirent *dir;

        while ((dir = readdir(d)) != NULL) {
            if (strcmp(dir->d_name, ".") == 0 || strcmp(dir->d_name, "..") == 0) continue;

            int len = strlen(dir->d_name);
            int should_delete = 0;

            for (int j = 0; j < num_exts; j++) {
                int ext_len = strlen(extensions[j]);
                if (len >= ext_len && strcmp(dir->d_name + len - ext_len, extensions[j]) == 0) {
                    should_delete = 1;
                    break;
                }
            }

            if (should_delete) {
                char filepath[2048];
                snprintf(filepath, sizeof(filepath), "%s/%s", dir_path, dir->d_name);
                if (unlink(filepath) == 0) {
                    note_cleaned = 1;
                }
            }
        }
        closedir(d);

        if (note_cleaned) {
            cleaned_count++;
        }
    }

    printf("%sCleaned files in %d note directories.%s\n", GREEN, cleaned_count, NC);
    load_graph();
}

// Menus
void prompt_exit() {
    printf("\n%sPress [Y] to return, exiting otherwise...%s ", CYAN, NC);
    fflush(stdout);
    int c = getch();

    if (c == 'Y' || c == 'y' || c == '\n') { system("clear"); return; }
    system("aerospace close --quit-if-last-window 2>/dev/null");
    exit(0);
}
void interactive_menu() {
    while (1) {
        printf("%sAttic operations:%s\n", CYAN, NC);
        printf("    %s(n): New note%s\n", CYAN, NC);
        printf("    %s(a): Audit notes%s\n", CYAN, NC);
        printf("    %s(r): Rebuild notes%s\n", CYAN, NC);
        printf("    %s(c): Clean attic%s\n", CYAN, NC);

        printf("%sSelect operation: [n, a, r, c] %s", CYAN, NC);
        fflush(stdout);
        int cmdNum = getch();

        if (cmdNum == 'n' || cmdNum == 'a' || cmdNum == 'r') {
            printf("%c\n\n", cmdNum);
            switch (cmdNum) {
                case 'n': create_note(""); break;
                case 'a': audit_notes(); break;
                case 'r': rebuild_notes(); break;
            }
            prompt_exit();
        } else if (cmdNum == 'c') {
            printf("%c\n\n", cmdNum);
            printf("%sAre you sure you want to delete all auxiliary files? [y/N] %s", RED, NC);
            fflush(stdout);

            int confirm = getch();
            printf("%c\n", confirm);

            if (confirm == 'y' || confirm == 'Y') { clean_attic(); } else { printf("%sClean aborted.%s\n", YELLOW, NC); }
            prompt_exit();
        } else if (cmdNum == 'q') {
            system("aerospace close --quit-if-last-window 2>/dev/null");
            exit(0);
        } else {
            system("clear");
        }
    }
}
int main(int argc, char **argv) {
    const char *home = getenv("HOME");
    const char *user = getenv("USER");
    if (!home) home = "";
    if (!user) user = "";

    const char *current_path = getenv("PATH");
    char new_path[8192];
    snprintf(new_path, sizeof(new_path),
        "/run/current-system/sw/bin:/etc/profiles/per-user/%s/bin:%s/.nix-profile/bin:/nix/var/nix/profiles/default/bin:/opt/homebrew/bin:/usr/local/bin:%s",
        user, home, current_path ? current_path : "");
    setenv("PATH", new_path, 1);

    snprintf(attic_dir, sizeof(attic_dir), "%s/iCloud/Projects/_attic", home);
    snprintf(template_file, sizeof(template_file), "%s/iCloud/Dotfiles/modules/scripts/LaTeXTemplate/files/attic.tex", home);
    snprintf(launcher_path, sizeof(launcher_path), "/etc/profiles/per-user/%s/bin/launcher", user);

    load_graph();

    if (argc > 1) {
        int opt;
        char *keywords = NULL;
        int target_id = -1;

        while ((opt = getopt(argc, argv, "ek:nu:m:arc")) != -1) {
            switch (opt) {
                case 'e': create_note("EMPTY_KEYWORDS"); return 0;
                case 'k': create_note(optarg); return 0;
                case 'n': create_note(""); return 0;
                case 'm': generate_metadata(atoi(optarg), 0); return 0;
                case 'u': update_metadata(atoi(optarg)); return 0;
                case 'a': audit_notes(); return 0;
                case 'r': rebuild_notes(); return 0;
                case 'c': clean_attic(); return 0;
                default:
                    fprintf(stderr, "Usage: %s [-n] [-e] [-k keywords] [-m ID] [-u ID] [-a] [-r] [-c]\n", argv[0]);
                    return 1;
            }
        }
    } else {
        is_interactive = 1;
        interactive_menu();
    }

    return 0;
}
