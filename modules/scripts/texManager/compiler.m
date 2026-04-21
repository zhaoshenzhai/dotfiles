#import "texManager.h"
#import "commonUtils.h"
#import <Foundation/Foundation.h>

static NSArray<NSString *> *GetCleanExtensions(void) {
    return @[
        @".aux", @".fls", @".log", @".blg", @".fdb_latexmk",
        @".bbl", @".bbl-SAVE-ERROR", @".bcf", @".bcf-SAVE-ERROR",
        @".xdv", @".xml", @".run.xml", @".synctex(busy)",
        @".dvi", @".out.ps"
    ];
}

void texInitConfig(TexConfig *config) {
    memset(config, 0, sizeof(TexConfig));
    config->continuous = false;
    config->nonstop = true;
    strcpy(config->engine, "pdf");
}

int texCompile(const char *dirPath, const char *fileName, const TexConfig *config) {
    @autoreleasepool {
        NSString *dir = [NSString stringWithUTF8String:dirPath];
        NSString *file = [NSString stringWithUTF8String:fileName];
        NSString *baseName = [file stringByDeletingPathExtension];
        NSString *engine = [NSString stringWithUTF8String:config->engine];

        NSString *pattern = [NSString stringWithFormat:@"[l]atexmk.*-%@.*%@", engine, file];
        if (IsProcessRunning(pattern.UTF8String)) return 0;

        unsigned int dirHash = HashString(dirPath);
        NSString *home = NSHomeDirectory();
        NSString *cacheDir = [NSString stringWithFormat:@"%@/.cache/texManager/pdf/%u_%@", home, dirHash, baseName];

        EnsureDirectoryExists(cacheDir.UTF8String);

        NSString *cmd = [NSString stringWithFormat:@"cd '%@' && latexmk -%@ -synctex=1 %@ %@ -outdir='%@' '%@'",
                         dir, engine,
                         config->continuous ? @"-pvc" : @"",
                         config->nonstop ? @"-interaction=nonstopmode" : @"",
                         cacheDir, file];

        int exitCode = RunCommandWait(@"/bin/sh", @[@"-c", cmd]);

        if (exitCode == 0) {
            NSString *pdfName = [baseName stringByAppendingPathExtension:@"pdf"];
            NSString *syncName = [baseName stringByAppendingPathExtension:@"synctex.gz"];

            MoveFile([cacheDir stringByAppendingPathComponent:pdfName].UTF8String,
                     [dir stringByAppendingPathComponent:pdfName].UTF8String);
            MoveFile([cacheDir stringByAppendingPathComponent:syncName].UTF8String,
                     [dir stringByAppendingPathComponent:syncName].UTF8String);
        }

        return exitCode;
    }
}

int texCompileToSvg(const char *dirPath, const char *fileName, const char *outputDir) {
    @autoreleasepool {
        NSString *dir = [NSString stringWithUTF8String:dirPath];
        NSString *file = [NSString stringWithUTF8String:fileName];
        NSString *baseName = [file stringByDeletingPathExtension];
        NSString *outDir = [NSString stringWithUTF8String:outputDir];

        unsigned int dirHash = HashString(dirPath);
        NSString *home = NSHomeDirectory();
        NSString *cacheDir = [NSString stringWithFormat:@"%@/.cache/texManager/svg/%u_%@", home, dirHash, baseName];

        EnsureDirectoryExists(outDir.UTF8String);
        EnsureDirectoryExists(cacheDir.UTF8String);

        NSString *latexCmd = [NSString stringWithFormat:@"cd '%@' && latexmk -g -dvi -interaction=nonstopmode -outdir='%@' -jobname='%@_web' -latex='latex %%O \"\\def\\isweb{}\\def\\notename{%@}\\input{%%S}\"' '%@'", dir, cacheDir, baseName, baseName, file];

        if (RunCommandWait(@"/bin/sh", @[@"-c", latexCmd]) != 0) return 1;

        NSString *dviCmd = [NSString stringWithFormat:@"cd '%@' && dvisvgm --font-format=woff2 --exact --page=1- '%@_web.dvi' -o '%@-%%p.svg'", cacheDir, baseName, baseName];

        if (RunCommandWait(@"/bin/sh", @[@"-c", dviCmd]) != 0) return 1;

        NSString *mvCmd = [NSString stringWithFormat:@"mv -f '%@'/%@-*.svg '%@'/", cacheDir, baseName, outDir];
        if (RunCommandWait(@"/bin/sh", @[@"-c", mvCmd]) != 0) return 1;

        return 0;
    }
}

int texCleanAux(const char *dirPath) {
    @autoreleasepool {
        NSString *dir = [NSString stringWithUTF8String:dirPath];
        NSFileManager *fm = [NSFileManager defaultManager];
        NSDirectoryEnumerator *enumerator = [fm enumeratorAtPath:dir];
        NSString *file;

        NSArray<NSString *> *extensions = GetCleanExtensions();
        NSPredicate *digitPattern = [NSPredicate predicateWithFormat:@"SELF LIKE '* [0-9].*'"];

        while ((file = [enumerator nextObject])) {
            BOOL shouldDelete = NO;

            if ([digitPattern evaluateWithObject:file]) {
                shouldDelete = YES;
            } else {
                for (NSString *ext in extensions) {
                    if ([file hasSuffix:ext]) {
                        shouldDelete = YES;
                        break;
                    }
                }
            }

            if (shouldDelete) [fm removeItemAtPath:[dir stringByAppendingPathComponent:file] error:nil];
        }
        return 0;
    }
}
