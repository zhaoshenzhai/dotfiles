#include "attic.h"

int generate_metadata(int id, int update_modified) {
    if (!notes[id].active) {
        printf("%sError: Note %05d does not exist.%s\n", RED, id, NC);
        return 1;
    }

    char mod_date[64] = "";
    if (update_modified || strlen(notes[id].mod_date) == 0) {
        struct stat st;
        char tex_path[PATH_MAX];
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
        fprintf(stderr, "%sError: Could not open %s for writing: %s%s\n", RED, dat_path, strerror(errno), NC);
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
    char path[PATH_MAX];
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

    load_memory();
    generate_metadata(id, 1);
    export_graph_json(1);

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

    load_memory();
    export_graph_json(1);
}

void audit_notes(void) {
    load_memory();
    printf("%sVerifying links, missing PDFs, and scanning for TODOs...%s\n", BLUE, NC);
    int broken = 0, todos = 0, desync = 0, missing_pdfs = 0;

    for (int i = 0; i < MAX_NOTES; i++) {
        if (!notes[i].active) continue;

        if (!notes[i].has_pdf) {
            printf("%s[MISSING PDF]%s Note %05d[%s] has no compiled PDF.\n", RED, NC, i, notes[i].keys);
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
                printf("%s[BROKEN LINK]%s ID %05d (Missing %s) referenced in %05d[%s]:%d\n", RED, NC, target, err, i, notes[i].keys, lno);
                broken++;
            }
        }

        for (int j = 0; j < notes[i].todo_count; j++) {
            printf("%s[TODO]%s %05d[%s]:%d -> %s\n", YELLOW, NC, i, notes[i].keys, notes[i].todos[j].line_no, notes[i].todos[j].text);
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

void rebuild_notes(void) {
    int total_notes = 0;
    for (int i = 0; i < MAX_NOTES; i++) { if (notes[i].active) total_notes++; }

    if (total_notes == 0) {
        printf("%sNo notes found to rebuild.%s\n", GREEN, NC);
        return;
    }

    printf("%sChecking modification times and refreshing metadata...%s\n", BLUE, NC);

    int running_jobs = 0, total_processed = 0, total_rebuilt = 0, total_failed = 0;
    int failed_ids[MAX_NOTES];

    int total_lines = 0;

    typedef struct { pid_t pid; int id; int row; } RebuildJob;
    RebuildJob jobs[MAX_JOBS];
    for (int i = 0; i < MAX_JOBS; i++) {
        jobs[i].pid = 0;
        jobs[i].id = 0;
        jobs[i].row = -1;
    }

    #define PROCESS_FINISHED_JOB(p, s) do { \
        for (int j = 0; j < MAX_JOBS; j++) { \
            if (jobs[j].pid == (p)) { \
                char dp[PATH_MAX], bp[PATH_MAX]; \
                snprintf(dp, sizeof(dp), "%s/%05d/%05d.dat", attic_dir, jobs[j].id, jobs[j].id); \
                snprintf(bp, sizeof(bp), "%s/%05d/%05d.dat.bak", attic_dir, jobs[j].id, jobs[j].id); \
                \
                int diff = (total_lines > 0 ? total_lines - 1 : 0) - jobs[j].row; \
                if (diff > 0) printf("\033[%dA", diff); \
                printf("\r\033[2K"); \
                \
                if (WIFEXITED((s)) && WEXITSTATUS((s)) == 0) { \
                    unlink(bp); \
                    total_rebuilt++; \
                } else { \
                    printf("%sNote %05d failed to compile!%s", RED, jobs[j].id, NC); \
                    if (access(bp, F_OK) == 0) rename(bp, dp); else unlink(dp); \
                    failed_ids[total_failed++] = jobs[j].id; \
                    jobs[j].row = -1; \
                } \
                \
                if (diff > 0) printf("\033[%dB", diff); \
                printf("\r"); \
                fflush(stdout); \
                \
                jobs[j].pid = 0; \
                running_jobs--; \
                break; \
            } \
        } \
    } while(0)

    for (int i = 0; i < MAX_NOTES; i++) {
        if (!notes[i].active) continue;

        total_processed++;

        char tex_path[PATH_MAX], log_path[PATH_MAX];
        struct stat st_tex, st_log;
        snprintf(tex_path, sizeof(tex_path), "%s/%05d/%05d.tex", attic_dir, i, i);
        snprintf(log_path, sizeof(log_path), "%s/%05d/%05d.log", attic_dir, i, i);

        int needs_rebuild = 0;
        if (stat(tex_path, &st_tex) == 0) {
            if (stat(log_path, &st_log) != 0 || st_tex.st_mtime > st_log.st_mtime) {
                needs_rebuild = 1;
            }
        }

        if (needs_rebuild) {
            char dp[PATH_MAX], bp[PATH_MAX];
            snprintf(dp, sizeof(dp), "%s/%05d/%05d.dat", attic_dir, i, i);
            snprintf(bp, sizeof(bp), "%s/%05d/%05d.dat.bak", attic_dir, i, i);
            rename(dp, bp);
        }

        generate_metadata(i, 0);

        int status;
        pid_t pid;
        while ((pid = waitpid(-1, &status, WNOHANG)) > 0) {
            PROCESS_FINISHED_JOB(pid, status);
        }

        if (!needs_rebuild) {
            continue;
        }

        while (running_jobs >= MAX_JOBS) {
            pid = waitpid(-1, &status, 0);
            if (pid > 0) {
                PROCESS_FINISHED_JOB(pid, status);
            }
        }

        pid = fork();
        if (pid == 0) {
            char dir_path[PATH_MAX]; snprintf(dir_path, sizeof(dir_path), "%s/%05d", attic_dir, i);
            if (chdir(dir_path) != 0) exit(1);
            char tex_file[32]; snprintf(tex_file, sizeof(tex_file), "%05d.tex", i);

            freopen("/dev/null", "w", stdout);
            freopen("/dev/null", "w", stderr);

            execlp("latexmk", "latexmk", "-pdf", "-pvc-", "-interaction=nonstopmode", tex_file, NULL);
            exit(1);
        } else if (pid > 0) {
            for (int j = 0; j < MAX_JOBS; j++) {
                if (jobs[j].pid == 0) {
                    jobs[j].pid = pid;
                    jobs[j].id = i;

                    if (jobs[j].row == -1) {
                        if (total_lines > 0) printf("\n");
                        jobs[j].row = total_lines;
                        total_lines++;
                    }

                    int diff = (total_lines > 0 ? total_lines - 1 : 0) - jobs[j].row;
                    if (diff > 0) printf("\033[%dA", diff);
                    printf("\r\033[2K%sRebuilding %05d (%d/%d)...%s", YELLOW, i, total_processed, total_notes, NC);
                    if (diff > 0) printf("\033[%dB", diff);
                    printf("\r");
                    fflush(stdout);

                    break;
                }
            }
            running_jobs++;
        }
    }

    while (running_jobs > 0) {
        int status;
        pid_t pid = waitpid(-1, &status, 0);
        if (pid > 0) {
            PROCESS_FINISHED_JOB(pid, status);
        }
    }

    #undef PROCESS_FINISHED_JOB

    if (total_lines > 0) printf("\n");
    printf("\r%sRebuild complete. Processed %d notes, %d were recompiled.%s\n",
        GREEN, total_processed, total_rebuilt, NC);

    if (total_failed > 0) {
        printf("%sWarning: %d note(s) failed to compile.%s\n", RED, total_failed, NC);
        printf("%sFailed IDs: ", RED);
        for (int i = 0; i < total_failed; i++) {
            printf("%05d%s", failed_ids[i], (i == total_failed - 1) ? "" : ", ");
        }
        printf("%s\n", NC);
    }

    load_memory();
    export_graph_json(1);
}

void clean_attic(void) {
    printf("%sCleaning auxiliary and files...%s\n", BLUE, NC);
    int cleaned_count = 0;

    const char *extensions[] = {
        ".aux", ".bbl", ".bcf", ".bcf-SAVE-ERROR", ".bbl-SAVE-ERROR",
        ".blg", ".fdb_latexmk", ".fls", ".log", ".run.xml",
        ".synctex.gz", ".synctex(busy)"
    };
    int num_exts = sizeof(extensions) / sizeof(extensions[0]);

    for (int i = 0; i < MAX_NOTES; i++) {
        if (!notes[i].active) continue;

        char dir_path[PATH_MAX];
        snprintf(dir_path, sizeof(dir_path), "%s/%05d", attic_dir, i);

        DIR *d = opendir(dir_path);
        if (!d) continue;

        int note_cleaned = 0;
        struct dirent *dir;

        while ((dir = readdir(d)) != NULL) {
            if (strcmp(dir->d_name, ".") == 0 || strcmp(dir->d_name, "..") == 0) continue;

            int len = strlen(dir->d_name);
            int should_delete = 0;

            char *space_ptr = strchr(dir->d_name, ' ');
            if (space_ptr != NULL) {
                if (isdigit(space_ptr[1]) && space_ptr[2] == '.') {
                    should_delete = 1;
                }
            }

            if (!should_delete) {
                for (int j = 0; j < num_exts; j++) {
                    int ext_len = strlen(extensions[j]);
                    if (len >= ext_len && strcmp(dir->d_name + len - ext_len, extensions[j]) == 0) {
                        should_delete = 1;
                        break;
                    }
                }
            }

            if (should_delete) {
                char filepath[PATH_MAX * 2];
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
    load_memory();
    export_graph_json(1);
}

void export_graph_json(int silent) {
    load_memory();
    char path[PATH_MAX];
    snprintf(path, sizeof(path), "%s/graph.json", attic_dir);

    FILE *f = fopen(path, "w");
    if (!f) {
        if (!silent) fprintf(stderr, "%sError opening %s for writing: %s%s\n", RED, path, strerror(errno), NC);
        return;
    }

    if (!silent) printf("%sExporting memory graph to JSON...%s\n", BLUE, NC);

    fprintf(f, "{\n  \"nodes\": [\n");
    int first_node = 1;
    for (int i = 0; i < MAX_NOTES; i++) {
        if (!notes[i].active) continue;
        if (!first_node) fprintf(f, ",\n");

        char safe_keys[1024] = "";
        int k = 0;
        for (int j = 0; notes[i].keys[j] != '\0' && k < 1000; j++) {
            if (notes[i].keys[j] == '"' || notes[i].keys[j] == '\\') {
                safe_keys[k++] = '\\';
            }
            safe_keys[k++] = notes[i].keys[j];
        }

        fprintf(f, "    { \"id\": \"%05d\", \"label\": \"%s\", \"has_pdf\": %s, \"mod_date\": \"%s\", \"todo_count\": %d }",
            i, safe_keys, notes[i].has_pdf ? "true" : "false", notes[i].mod_date, notes[i].todo_count);
        first_node = 0;
    }

    fprintf(f, "\n  ],\n  \"edges\": [\n");
    int first_edge = 1;
    for (int i = 0; i < MAX_NOTES; i++) {
        if (!notes[i].active) continue;
        for (int j = 0; j < notes[i].out_count; j++) {
            if (!first_edge) fprintf(f, ",\n");
            fprintf(f, "    { \"source\": \"%05d\", \"target\": \"%05d\", \"line_no\": %d }",
                i, notes[i].out_links[j].target_id, notes[i].out_links[j].line_no);
            first_edge = 0;
        }
    }

    fprintf(f, "\n  ]\n}\n");
    fclose(f);

    if (!silent) printf("%sGraph data successfully exported to %s%s\n", GREEN, path, NC);
}
