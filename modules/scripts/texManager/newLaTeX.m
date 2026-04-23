#import "commonUtils.h"
#import "texManager.h"
#include <getopt.h>

static void FixDate(NSString **month, NSString **date, NSString **mod) {
    if (!*month || !*date) return;

    int m = [*month intValue];
    if (m == 0 && [*month length] > 0) {
        NSString *lower = [*month lowercaseString];
        if ([lower hasPrefix:@"jan"]) *month = @"January";
        else if ([lower hasPrefix:@"feb"]) *month = @"February";
        else if ([lower hasPrefix:@"mar"]) *month = @"March";
        else if ([lower hasPrefix:@"apr"]) *month = @"April";
        else if ([lower hasPrefix:@"may"]) *month = @"May";
        else if ([lower hasPrefix:@"jun"]) *month = @"June";
        else if ([lower hasPrefix:@"jul"]) *month = @"July";
        else if ([lower hasPrefix:@"aug"]) *month = @"August";
        else if ([lower hasPrefix:@"sep"]) *month = @"September";
        else if ([lower hasPrefix:@"oct"]) *month = @"October";
        else if ([lower hasPrefix:@"nov"]) *month = @"November";
        else if ([lower hasPrefix:@"dec"]) *month = @"December";
    } else {
        NSArray *months = @[@"", @"January", @"February", @"March", @"April", @"May", @"June", @"July", @"August", @"September", @"October", @"November", @"December"];
        if (m >= 1 && m <= 12) *month = months[m];
    }

    int d = [*date intValue];
    if (d == 1 || d == 21 || d == 31) *mod = @"st";
    else if (d == 2 || d == 22) *mod = @"nd";
    else if (d == 3 || d == 23) *mod = @"rd";
    else *mod = @"th";
}

int texNew(int argc, char **argv) {
    @autoreleasepool {
        NSString *fileName = nil;
        NSString *fileType = nil;
        NSString *title = nil;
        BOOL solutions = NO;

        NSString *assignmentCourse = nil;
        NSString *assignmentNumber = nil;
        NSString *assignmentDueMonth = nil;
        NSString *assignmentDueDate = nil;
        NSString *assignmentDueDateMod = @"";

        int opt;
        while ((opt = getopt(argc, argv, "n:t:a:sd:")) != -1) {
            switch (opt) {
                case 'n':
                    fileName = [NSString stringWithUTF8String:optarg];
                    title = [fileName stringByReplacingOccurrencesOfString:@"_" withString:@" "];
                    break;
                case 't':
                    fileType = [NSString stringWithUTF8String:optarg];
                    break;
                case 'a':
                    assignmentNumber = [NSString stringWithUTF8String:optarg];
                    assignmentCourse = [[NSFileManager defaultManager] currentDirectoryPath];
                    fileType = @"assignment";
                    fileName = [NSString stringWithFormat:@"Assignment_%@", assignmentNumber];
                    title = [fileName stringByReplacingOccurrencesOfString:@"_" withString:@" "];
                    break;
                case 's':
                    solutions = YES;
                    break;
                case 'd':
                    if (optind < argc) {
                        assignmentDueMonth = [NSString stringWithUTF8String:optarg];
                        assignmentDueDate = [NSString stringWithUTF8String:argv[optind++]];
                        FixDate(&assignmentDueMonth, &assignmentDueDate, &assignmentDueDateMod);
                    }
                    break;
            }
        }

        if (!fileName) {
            fprintf(stderr, "%sError: Expected one of: [-n] and [-a].%s\n", RED, NC);
            return 1;
        }

        if (!fileType) fileType = assignmentNumber ? @"assignment" : @"paper";

        NSFileManager *fm = [NSFileManager defaultManager];

        if ([fileType isEqualToString:@"assignment"]) {
            NSString *infoPath = [assignmentCourse stringByAppendingPathComponent:@".info"];
            if (![fm fileExistsAtPath:infoPath]) {
                fprintf(stderr, "%sError: Expected .info file.%s\n", RED, NC);
                return 1;
            }
            if (!assignmentNumber || !assignmentDueMonth || !assignmentDueDate) {
                fprintf(stderr, "%sError: Expected [-a] [-d] for assignmentNumber and (dueMonth dueDate).%s\n", RED, NC);
                return 1;
            }
            if ([assignmentNumber intValue] < 1 || [assignmentDueDate intValue] < 1 || [assignmentDueDate intValue] > 31) {
                fprintf(stderr, "Error: Invalid inputs.\n");
                return 2;
            }
        }

        NSString *targetDir = [fileType isEqualToString:@"assignment"] ?
            [NSString stringWithFormat:@"Assignments/%@", fileName] : fileName;

        EnsureDirectoryExists(targetDir.UTF8String);
        [fm changeCurrentDirectoryPath:targetDir];

        NSArray *symlinks = @[@"macros.sty", @"refs.bib", @"preamble.sty", [NSString stringWithFormat:@"preambles/%@.sty", fileType]];
        for (NSString *link in symlinks) {
            NSString *src = [kLaTeXTemplateDir stringByAppendingPathComponent:link];
            NSString *dst = [link lastPathComponent];
            [fm createSymbolicLinkAtPath:dst withDestinationPath:src error:nil];
        }

        NSString *texSrc = [kLaTeXTemplateDir stringByAppendingPathComponent:[NSString stringWithFormat:@"files/%@.tex", fileType]];
        NSString *texDst = [NSString stringWithFormat:@"%@.tex", fileName];
        NSMutableString *texContent = [NSMutableString stringWithContentsOfFile:texSrc encoding:NSUTF8StringEncoding error:nil];

        [texContent replaceOccurrencesOfString:@"TITLE" withString:title options:0 range:NSMakeRange(0, texContent.length)];

        if ([fileType isEqualToString:@"beamer"]) {
            NSString *src = [kLaTeXTemplateDir stringByAppendingPathComponent:@"mcgill.png"];
            [fm createSymbolicLinkAtPath:@"mcgill.png" withDestinationPath:src error:nil];
        } else if ([fileType isEqualToString:@"assignment"]) {
            NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"[A-Z]{4}[0-9]{3}" options:0 error:nil];
            NSTextCheckingResult *match = [regex firstMatchInString:assignmentCourse options:0 range:NSMakeRange(0, assignmentCourse.length)];
            NSString *courseName = match ? [assignmentCourse substringWithRange:match.range] : [assignmentCourse lastPathComponent];

            NSString *termYear = [[NSString stringWithContentsOfFile:[assignmentCourse stringByAppendingPathComponent:@".info"] encoding:NSUTF8StringEncoding error:nil] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

            [texContent replaceOccurrencesOfString:@"COURSE_NAME" withString:courseName options:0 range:NSMakeRange(0, texContent.length)];
            [texContent replaceOccurrencesOfString:@"TERM_YEAR" withString:termYear ? termYear : @"" options:0 range:NSMakeRange(0, texContent.length)];
            [texContent replaceOccurrencesOfString:@"DUE_MONTH" withString:assignmentDueMonth options:0 range:NSMakeRange(0, texContent.length)];
            [texContent replaceOccurrencesOfString:@"DUE_DATE_MOD" withString:assignmentDueDateMod options:0 range:NSMakeRange(0, texContent.length)];
            [texContent replaceOccurrencesOfString:@"DUE_DATE" withString:assignmentDueDate options:0 range:NSMakeRange(0, texContent.length)];
        }

        if (solutions) {
            NSString *solSrc = [kLaTeXTemplateDir stringByAppendingPathComponent:@"preambles/solutions.sty"];
            [fm createSymbolicLinkAtPath:@"solutions.sty" withDestinationPath:solSrc error:nil];
            [fm copyItemAtPath:[kLaTeXTemplateDir stringByAppendingPathComponent:@".latexmkrc"] toPath:@".latexmkrc" error:nil];

            [texContent replaceOccurrencesOfString:@"\\input{macros.sty}"
                                        withString:@"\\input{macros.sty}\n\\input{solutions.sty}"
                                           options:0 range:NSMakeRange(0, texContent.length)];
        }

        [texContent writeToFile:texDst atomically:YES encoding:NSUTF8StringEncoding error:nil];
        return 0;
    }
}
