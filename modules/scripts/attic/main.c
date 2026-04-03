#include "attic.h"

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
        printf("    %s(g): Export graph to JSON%s\n", CYAN, NC);

        printf("%sSelect operation: [n, a, r, c, g] %s", CYAN, NC);
        fflush(stdout);
        int cmdNum = getch();

        if (cmdNum == 'n' || cmdNum == 'a' || cmdNum == 'r' || cmdNum == 'c' || cmdNum == 'g') {
            printf("%c\n\n", cmdNum);
            switch (cmdNum) {
                case 'n': create_note(""); break;
                case 'a': audit_notes(); break;
                case 'r': rebuild_notes(); break;
                case 'c': clean_attic(); break;
                case 'g': export_graph_json(0); break;
            }
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

    snprintf(attic_dir, sizeof(attic_dir), "%s/iCloud/Projects/_attic/notes", home);
    snprintf(template_file, sizeof(template_file), "%s/iCloud/Dotfiles/modules/scripts/LaTeXTemplate/files/attic.tex", home);
    snprintf(launcher_path, sizeof(launcher_path), "/etc/profiles/per-user/%s/bin/launcher", user);

    load_memory();

    if (argc > 1) {
        int opt;
        while ((opt = getopt(argc, argv, "ek:nu:m:arcg")) != -1) {
            switch (opt) {
                case 'e': create_note("EMPTY_KEYWORDS"); return 0;
                case 'k': create_note(optarg); return 0;
                case 'n': create_note(""); return 0;
                case 'm': generate_metadata(atoi(optarg), 0); return 0;
                case 'u': update_metadata(atoi(optarg)); return 0;
                case 'a': audit_notes(); return 0;
                case 'r': rebuild_notes(); return 0;
                case 'c': clean_attic(); return 0;
                case 'g': export_graph_json(0); return 0;
                default:
                    fprintf(stderr, "Usage: %s [-n] [-e] [-k keywords] [-m ID] [-u ID] [-a] [-r] [-c] [-g]\n", argv[0]);
                    return 1;
            }
        }
    } else {
        is_interactive = 1;
        interactive_menu();
    }

    return 0;
}
