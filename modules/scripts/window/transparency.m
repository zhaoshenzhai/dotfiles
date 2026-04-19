#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreImage/CoreImage.h>

typedef int CGSConnectionID;
extern CGSConnectionID CGSMainConnectionID(void);
extern CGError CGSSetWindowBackgroundBlurRadius(CGSConnectionID cid, NSInteger wid, int radius);

static const CGFloat BASE_ALPHA  = 0.95;
static const CGFloat BLUR_RADIUS = 20;

static const CGFloat CURVE_PT0_X = 0.00; static const CGFloat CURVE_PT0_Y = 0.00;
static const CGFloat CURVE_PT1_X = 0.25; static const CGFloat CURVE_PT1_Y = 0.20;
static const CGFloat CURVE_PT2_X = 0.50; static const CGFloat CURVE_PT2_Y = 0.15;
static const CGFloat CURVE_PT3_X = 0.75; static const CGFloat CURVE_PT3_Y = 0.05;
static const CGFloat CURVE_PT4_X = 1.00; static const CGFloat CURVE_PT4_Y = 0.00;

static NSView *findTagged(NSWindow *w, NSString *tag) {
    if (!w.contentView || !w.contentView.superview) return nil;
    for (NSView *v in w.contentView.superview.subviews)
        if ([v.identifier isEqualToString:tag]) return v;
    return nil;
}

static void injectIfNeeded(NSWindow *window) {
    if (findTagged(window, @"LiquidGlassView")) return;
    if (!window.contentView || !window.contentView.superview) return;

    window.opaque          = NO;
    window.backgroundColor = NSColor.clearColor;

    CGSSetWindowBackgroundBlurRadius(CGSMainConnectionID(), [window windowNumber], BLUR_RADIUS);

    NSView *themeFrame = window.contentView.superview;

    NSView *filterView = [[NSView alloc] initWithFrame:filterView.bounds];
    filterView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    filterView.wantsLayer = YES;
    filterView.layer.backgroundColor = [[NSColor clearColor] CGColor];

    CIFilter *toneCurve = [CIFilter filterWithName:@"CIToneCurve"];
    [toneCurve setValue:[CIVector vectorWithX:CURVE_PT0_X Y:CURVE_PT0_Y] forKey:@"inputPoint0"];
    [toneCurve setValue:[CIVector vectorWithX:CURVE_PT1_X Y:CURVE_PT1_Y] forKey:@"inputPoint1"];
    [toneCurve setValue:[CIVector vectorWithX:CURVE_PT2_X Y:CURVE_PT2_Y] forKey:@"inputPoint2"];
    [toneCurve setValue:[CIVector vectorWithX:CURVE_PT3_X Y:CURVE_PT3_Y] forKey:@"inputPoint3"];
    [toneCurve setValue:[CIVector vectorWithX:CURVE_PT4_X Y:CURVE_PT4_Y] forKey:@"inputPoint4"];

    NSGlassEffectView *glassView = [[NSGlassEffectView alloc] initWithFrame:themeFrame.bounds];
    glassView.autoresizingMask   = NSViewWidthSizable | NSViewHeightSizable;
    glassView.style              = NSGlassEffectViewStyleClear;
    glassView.alphaValue         = BASE_ALPHA;
    glassView.identifier         = @"LiquidGlassView";
    [themeFrame addSubview:glassView positioned:NSWindowAbove relativeTo:toneCurve];
}

static void updateAlphas(void) {
    NSMutableArray<NSWindow *> *tracked = [NSMutableArray array];
    for (NSWindow *w in NSApp.windows)
        if (w.isVisible && findTagged(w, @"LiquidGlassView"))
            [tracked addObject:w];

    for (NSWindow *w in tracked) {
        NSInteger n = 1;
        for (NSWindow *other in tracked)
            if (other != w && NSIntersectsRect(w.frame, other.frame)) n++;

        CGFloat glassAlpha = 1.0 - pow(1.0 - BASE_ALPHA, 1.0 / (CGFloat)n);
        findTagged(w, @"LiquidGlassView").alphaValue = glassAlpha;
    }
}

__attribute__((constructor))
void recolor(void) {
    [NSTimer scheduledTimerWithTimeInterval:0.1 repeats:YES block:^(NSTimer *_) {
        for (NSWindow *w in NSApp.windows) {
            if (!w.isVisible) continue;
            injectIfNeeded(w);
        }
        updateAlphas();
    }];
}
