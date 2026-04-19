#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreImage/CoreImage.h>

typedef int CGSConnectionID;
extern CGSConnectionID CGSMainConnectionID(void);
extern CGError CGSSetWindowBackgroundBlurRadius(CGSConnectionID cid, NSInteger wid, int radius);

static const CGFloat BASE_ALPHA  = 0.95;
static const CGFloat BLUR_RADIUS = 12;

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

    // 1. The Hardware Blur (Flawless)
    CGSSetWindowBackgroundBlurRadius(CGSMainConnectionID(), [window windowNumber], BLUR_RADIUS);

    NSView *themeFrame = window.contentView.superview;

    // 2. The Indestructible Black Layer
    // This dynamically crushes bright backgrounds and leaves dark backgrounds dark.
    NSView *blackView = [[NSView alloc] initWithFrame:themeFrame.bounds];
    blackView.autoresizingMask      = NSViewWidthSizable | NSViewHeightSizable;
    blackView.wantsLayer            = YES;
    blackView.layer.backgroundColor = [[NSColor blackColor] CGColor];
    blackView.layer.opacity         = 0.9; // Tweak this between 0.70 and 0.95 to match your ideal curve
    blackView.identifier            = @"DynamicBlackLayer";

    // Positioned securely behind your terminal content
    [themeFrame addSubview:blackView positioned:NSWindowBelow relativeTo:nil];

    // 3. The Glass Layer
    NSGlassEffectView *glassView = [[NSGlassEffectView alloc] initWithFrame:themeFrame.bounds];
    glassView.autoresizingMask   = NSViewWidthSizable | NSViewHeightSizable;
    glassView.style              = NSGlassEffectViewStyleClear;
    glassView.alphaValue         = BASE_ALPHA;
    glassView.identifier         = @"LiquidGlassView";

    // Stacked precisely on top of the black layer
    [themeFrame addSubview:glassView positioned:NSWindowAbove relativeTo:blackView];
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
