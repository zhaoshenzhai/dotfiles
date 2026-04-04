#include "attic.h"

char attic_dir[PATH_MAX];
char template_file[PATH_MAX];
char launcher_path[PATH_MAX];
int is_interactive = 0;

Note *notes = NULL;
int noteCapacity = 0;

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

void ensureNoteCapacity(int max_id) {
    if (max_id >= noteCapacity) {
        int old_cap = noteCapacity;
        noteCapacity = max_id + 1;
        if (noteCapacity < old_cap * 2) noteCapacity = old_cap * 2;
        if (noteCapacity < 128) noteCapacity = 128;

        notes = (Note*)safe_realloc(notes, noteCapacity * sizeof(Note));
        memset(notes + old_cap, 0, (noteCapacity - old_cap) * sizeof(Note));
    }
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
    int n_procs = proc_listpids(PROC_ALL_PIDS, 0, NULL, 0);
    if (n_procs <= 0) return 0;

    pid_t *pids = (pid_t*)safe_malloc(n_procs * sizeof(pid_t));
    n_procs = proc_listpids(PROC_ALL_PIDS, 0, pids, n_procs * sizeof(pid_t));

    for (int i = 0; i < n_procs; i++) {
        if (pids[i] <= 0) continue;
        char path_buf[PROC_PIDPATHINFO_MAXSIZE];
        if (proc_pidpath(pids[i], path_buf, sizeof(path_buf)) > 0) {
            if (strstr(path_buf, "latexmk") || strstr(path_buf, "pdflatex")) {
                free(pids);
                return 1;
            }
        }
    }
    free(pids);
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

unsigned int HashString(const char *str) {
    unsigned int hash = 5381;
    int c;
    while ((c = *str++)) hash = ((hash << 5) + hash) + c;
    return hash;
}
