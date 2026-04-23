#import "commonUtils.h"
#import "texManager.h"
#include <getopt.h>

void help(char *name) {
    fprintf(stderr, "Usage: %s [-c continuous] [-e engine] [-C clean] [-s svg] [-o outputDir] <fileOrDir>\n", name);
    fprintf(stderr, "   or: %s [-n fileName] [-t fileType] [-a assignmentNumber] [-s solutions] [-d dueMonth dueDate]\n", name);
}

int main(int argc, char **argv) {
    @autoreleasepool {
        EnsureSystemPath();

        for (int i = 1; i < argc; i++) {
            if (strcmp(argv[i], "-n") == 0 || strcmp(argv[i], "-a") == 0) return texNew(argc, argv);
        }

        TexConfig config;
        texInitConfig(&config);

        int opt;
        bool cleanMode = false;
        bool svgMode = false;
        NSString *outputDir = @".";

        while ((opt = getopt(argc, argv, "cCso:e:")) != -1) {
            switch (opt) {
                case 'c': config.continuous = true; break;
                case 'C': cleanMode = true; break;
                case 's': svgMode = true; break;
                case 'o': outputDir = [NSString stringWithUTF8String:optarg]; break;
                case 'e': strncpy(config.engine, optarg, sizeof(config.engine) - 1); config.engine[sizeof(config.engine) - 1] = '\0'; break;
                default: help(argv[0]); return 1;
            }
        }

        if (optind >= argc) help(argv[0]); return 1;

        NSString *targetPath = [NSString stringWithUTF8String:argv[optind]];
        NSString *dirPath = [targetPath stringByDeletingLastPathComponent];
        NSString *fileName = [targetPath lastPathComponent];

        if (dirPath.length == 0) dirPath = @".";

        if (cleanMode) {
            return texCleanAux(argv[optind]);
        } else if (svgMode) {
            return texCompileToSvg(dirPath.UTF8String, fileName.UTF8String, outputDir.UTF8String);
        } else {
            return texCompile(dirPath.UTF8String, fileName.UTF8String, &config);
        }
    }
}
