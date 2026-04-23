#import "attic.h"

void promptExit() {
    printf("\n%sPress [Y] to return, exiting otherwise...%s ", CYAN, NC);
    fflush(stdout);
    int c = GetCh();

    if (c == 'Y' || c == 'y' || c == '\n') { system("clear"); return; }
    AerospaceClose(nil);
    exit(0);
}

void interactiveMenu() {
    while (1) {
        printf("%sAttic operations:%s\n", CYAN, NC);
        printf("    %s(n): New note%s\n", CYAN, NC);
        printf("    %s(a): Audit notes%s\n", CYAN, NC);
        printf("    %s(r): Rebuild notes%s\n", CYAN, NC);
        printf("    %s(g): Open graph view%s\n", CYAN, NC);

        printf("%sSelect operation: [n, a, r, g] %s", CYAN, NC);
        fflush(stdout);
        int cmdNum = GetCh();

        if (cmdNum == 'n' || cmdNum == 'a' || cmdNum == 'r' || cmdNum == 'g') {
            printf("%c\n\n", cmdNum);
            switch (cmdNum) {
                case 'n': createNote(""); break;
                case 'a': auditNotes(); break;
                case 'r': rebuildNotes(); break;
                case 'g':
                    launchGraph();
                    system("clear");
                    printf("\033[?1004h\033[?25l");
                    fflush(stdout);

                    while (1) {
                        int c = GetCh();
                        if (c == '\033') { if (GetCh() == '[') { if (GetCh() == 'I') break; } } else if (c == '\n' || c == ' ') { break; }
                    }

                    printf("\033[?1004l\033[?25h");
                    fflush(stdout);
                    system("clear");
                    break;
            }
            if (cmdNum != 'g') { promptExit(); }
        } else if (cmdNum == 'q') {
            AerospaceClose(nil);
            exit(0);
        } else {
            system("clear");
        }
    }
}

int main(int argc, char **argv) {
    EnsureSystemPath();

    snprintf(atticDir, sizeof(atticDir), "%s/Projects/_attic/notes", kBaseDir.UTF8String);

    loadMemory();

    if (argc > 1) {
        int opt;
        while ((opt = getopt(argc, argv, "ek:nu:m:c:arg")) != -1) {
            switch (opt) {
                case 'e': createNote("EMPTY_KEYWORDS"); return 0;
                case 'k': createNote(optarg); return 0;
                case 'n': createNote(""); return 0;
                case 'm': generateMetadata(atoi(optarg)); return 0;
                case 'u': updateMetadata(atoi(optarg)); return 0;
                case 'c': return compileNoteSync(atoi(optarg));
                case 'a': auditNotes(); return 0;
                case 'r': rebuildNotes(); return 0;
                case 'g': launchGraph(); return 0;
                default:
                    fprintf(stderr, "Usage: %s [-n] [-e] [-k keywords] [-m ID] [-u ID] [-c ID] [-a] [-r] [-g]\n", argv[0]);
                    return 1;
            }
        }
    } else {
        isInteractive = 1;
        interactiveMenu();
    }

    return 0;
}
