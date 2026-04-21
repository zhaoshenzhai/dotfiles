#import "commonUtils.h"
#import "texManager.h"
#import <Foundation/Foundation.h>
#import <getopt.h>

int main(int argc, char **argv) {
    @autoreleasepool {
        TexConfig config;
        texInitConfig(&config);
        EnsureSystemPath();

        int opt;
        bool cleanMode = false;
        bool svgMode = false;
        NSString *outputDir = @".";

        while ((opt = getopt(argc, argv, "cCe:so:")) != -1) {
            switch (opt) {
                case 'c': config.continuous = true; break;
                case 'e':
                    strncpy(config.engine, optarg, sizeof(config.engine) - 1);
                    config.engine[sizeof(config.engine) - 1] = '\0';
                    break;
                case 'C': cleanMode = true; break;
                case 's': svgMode = true; break;
                case 'o': outputDir = [NSString stringWithUTF8String:optarg]; break;
                default:
                    fprintf(stderr, "Usage: %s [-c continuous] [-e engine] [-C clean] [-s svg] [-o outputDir] <fileOrDir>\n", argv[0]);
                    return 1;
            }
        }

        if (optind >= argc) {
            fprintf(stderr, "Error: Expected file or directory argument.\n");
            return 1;
        }

        NSString *targetPath = [NSString stringWithUTF8String:argv[optind]];
        NSString *dirPath = [targetPath stringByDeletingLastPathComponent];
        NSString *fileName = [targetPath lastPathComponent];

        if (dirPath.length == 0) {
            dirPath = @".";
        }

        if (cleanMode) {
            return texCleanAux(argv[optind]);
        } else if (svgMode) {
            return texCompileToSvg(dirPath.UTF8String, fileName.UTF8String, outputDir.UTF8String);
        } else {
            return texCompile(dirPath.UTF8String, fileName.UTF8String, &config);
        }
    }
}
