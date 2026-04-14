#include "attic.h"
#include "texManager.h"

void promptExit() {
    printf("\n%sPress [Y] to return, exiting otherwise...%s ", CYAN, NC);
    fflush(stdout);
    int c = getch();

    if (c == 'Y' || c == 'y' || c == '\n') { system("clear"); return; }
    system("aerospace close --quit-if-last-window 2>/dev/null");
    exit(0);
}

void interactiveMenu() {
    while (1) {
        printf("%sAttic operations:%s\n", CYAN, NC);
        printf("    %s(n): New note%s\n", CYAN, NC);
        printf("    %s(a): Audit notes%s\n", CYAN, NC);
        printf("    %s(r): Rebuild notes%s\n", CYAN, NC);
        printf("    %s(c): Clean attic%s\n", CYAN, NC);
        printf("    %s(g): Open graph view%s\n", CYAN, NC);

        printf("%sSelect operation: [n, a, r, c, g] %s", CYAN, NC);
        fflush(stdout);
        int cmdNum = getch();

        if (cmdNum == 'n' || cmdNum == 'a' || cmdNum == 'r' || cmdNum == 'c' || cmdNum == 'g') {
            printf("%c\n\n", cmdNum);
            switch (cmdNum) {
                case 'n': createNote(""); break;
                case 'a': auditNotes(); break;
                case 'r': rebuildNotes(); break;
                case 'c': cleanAttic(); break;
                case 'g':
                    launchGraph();
                    system("clear");
                    printf("\033[?1004h\033[?25l");
                    fflush(stdout);

                    while (1) {
                        int c = getch();
                        if (c == '\033') { if (getch() == '[') { if (getch() == 'I') break; } } else if (c == '\n' || c == ' ') { break; }
                    }

                    printf("\033[?1004l\033[?25h");
                    fflush(stdout);
                    system("clear");
                    break;
            }
            if (cmdNum != 'g') { promptExit(); }
        } else if (cmdNum == 'q') {
            system("aerospace close --quit-if-last-window 2>/dev/null");
            exit(0);
        } else {
            system("clear");
        }
    }
}

int main(int argc, char **argv) {
    ensureTexPath();

    snprintf(atticDir, sizeof(atticDir), "%s/iCloud/Projects/_attic/notes", getenv("HOME"));
    snprintf(templateFile, sizeof(templateFile), "%s/iCloud/Dotfiles/modules/scripts/LaTeXTemplate/files/attic.tex", getenv("HOME"));
    snprintf(launcherPath, sizeof(launcherPath), "/etc/profiles/per-user/%s/bin/launcher", getenv("USER"));

    char cleanCmd[1024];
    snprintf(cleanCmd, sizeof(cleanCmd), "find \"%s\" -type f -name \"* [0-9].*\" -delete", atticDir);
    system(cleanCmd);

    loadMemory();

    if (argc > 1) {
        int opt;
        while ((opt = getopt(argc, argv, "ek:nu:m:arcg")) != -1) {
            switch (opt) {
                case 'e': createNote("EMPTY_KEYWORDS"); return 0;
                case 'k': createNote(optarg); return 0;
                case 'n': createNote(""); return 0;
                case 'm': generateMetadata(atoi(optarg)); return 0;
                case 'u': updateMetadata(atoi(optarg)); return 0;
                case 'a': auditNotes(); return 0;
                case 'r': rebuildNotes(); return 0;
                case 'c': cleanAttic(); return 0;
                case 'g': launchGraph(); return 0;
                default:
                    fprintf(stderr, "Usage: %s [-n] [-e] [-k keywords] [-m ID] [-u ID] [-a] [-r] [-c] [-g]\n", argv[0]);
                    return 1;
            }
        }
    } else {
        isInteractive = 1;
        interactiveMenu();
    }

    return 0;
}
