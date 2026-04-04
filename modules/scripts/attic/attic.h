#pragma once

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

#define SAFE_STR(s) ((s) ? (s) : "")
#define MAX_NOTES 10000
#define MAX_JOBS 5

#define RED "\x1b[31m"
#define GREEN "\x1b[32m"
#define YELLOW "\x1b[33m"
#define BLUE "\x1b[34m"
#define PURPLE "\x1b[35m"
#define CYAN "\x1b[36m"
#define NC "\x1b[0m"

typedef struct { int target_id; int line_no; } OutLink;
typedef struct { char *text; int line_no; } Todo;

typedef struct {
    int active;
    int has_pdf;
    char mod_date[64];

    char *keys;
    char *meta_refs_raw;
    char *meta_ref_in_raw;

    OutLink *out_links;
    int out_count;
    int out_capacity;

    int *in_links;
    int in_count;
    int in_capacity;

    Todo *todos;
    int todo_count;
    int todo_capacity;
} Note;

extern char attic_dir[PATH_MAX];
extern char template_file[PATH_MAX];
extern char launcher_path[PATH_MAX];
extern int is_interactive;
extern Note notes[MAX_NOTES];

void* safe_malloc(size_t size);
void* safe_realloc(void* p, size_t size);
int getch(void);
void trim_end(char *str);
int cmp_int(const void *a, const void *b);
int dedupe(int *arr, int count);
void format_links(int *ids, int count, char *out_buf);
int is_compiling(int id);
void compile_note_async(int id);
void extract_ids_from_string(const char *str, int *arr, int *count);
unsigned int HashString(const char *str);

void free_memory(void);
void add_out_link(int src, int target, int line_no);
void add_in_link(int target, int src);
void add_todo(int id, int line_no, const char *text);
void load_memory(void);

int generate_metadata(int id, int update_modified);
void create_note(const char *in_keywords);
void update_metadata(int id);
void audit_notes(void);
void rebuild_notes(void);
void clean_attic(void);
void export_graph_json(int silent);
void launch_graph_view(void);
