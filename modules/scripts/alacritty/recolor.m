#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreImage/CoreImage.h>

// static const CGFloat TINT_R = 1.00;
// static const CGFloat TINT_G = 1.00;
// static const CGFloat TINT_B = 1.00;

static const CGFloat CURVE_PT0_X = 0.00; static const CGFloat CURVE_PT0_Y = 0.00;
static const CGFloat CURVE_PT1_X = 0.25; static const CGFloat CURVE_PT1_Y = 0.25;
static const CGFloat CURVE_PT2_X = 0.50; static const CGFloat CURVE_PT2_Y = 0.10;
static const CGFloat CURVE_PT3_X = 0.75; static const CGFloat CURVE_PT3_Y = 0.15;
static const CGFloat CURVE_PT4_X = 1.00; static const CGFloat CURVE_PT4_Y = 0.00;

static const CGFloat BASE_ALPHA = 0.85;

static NSVisualEffectView *blurViewForWindow(NSWindow *w) {
    if (!w.contentView || !w.contentView.superview) return nil;
    for (NSView *v in w.contentView.superview.subviews)
        if ([v.identifier isEqualToString:@"SafeDarkBlur"])
            return (NSVisualEffectView *)v;
    return nil;
}

static void injectIfNeeded(NSWindow *window) {
    if (blurViewForWindow(window)) return;
    if (!window.contentView || !window.contentView.superview) return;

    window.opaque = NO;
    window.backgroundColor = [NSColor clearColor];

    NSView *themeFrame = window.contentView.superview;
    NSVisualEffectView *blurView = [[NSVisualEffectView alloc] initWithFrame:themeFrame.bounds];
    blurView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    blurView.blendingMode = NSVisualEffectBlendingModeBehindWindow;
    blurView.material = NSVisualEffectMaterialHUDWindow;
    blurView.state = NSVisualEffectStateActive;
    blurView.appearance = [NSAppearance appearanceNamed:NSAppearanceNameVibrantDark];
    blurView.identifier = @"SafeDarkBlur";
    blurView.alphaValue = BASE_ALPHA;

    NSView *filterView = [[NSView alloc] initWithFrame:blurView.bounds];
    filterView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    filterView.wantsLayer = YES;
    filterView.layer.backgroundColor = [[NSColor clearColor] CGColor];

    // CIFilter *preTint = [CIFilter filterWithName:@"CIColorMatrix"];
    // [preTint setValue:[CIVector vectorWithX:TINT_R Y:0 Z:0 W:0] forKey:@"inputRVector"];
    // [preTint setValue:[CIVector vectorWithX:0 Y:TINT_G Z:0 W:0] forKey:@"inputGVector"];
    // [preTint setValue:[CIVector vectorWithX:0 Y:0 Z:TINT_B W:0] forKey:@"inputBVector"];
    // [preTint setValue:[CIVector vectorWithX:0 Y:0 Z:0 W:1]      forKey:@"inputAVector"];

    CIFilter *toneCurve = [CIFilter filterWithName:@"CIToneCurve"];
    [toneCurve setValue:[CIVector vectorWithX:CURVE_PT0_X Y:CURVE_PT0_Y] forKey:@"inputPoint0"];
    [toneCurve setValue:[CIVector vectorWithX:CURVE_PT1_X Y:CURVE_PT1_Y] forKey:@"inputPoint1"];
    [toneCurve setValue:[CIVector vectorWithX:CURVE_PT2_X Y:CURVE_PT2_Y] forKey:@"inputPoint2"];
    [toneCurve setValue:[CIVector vectorWithX:CURVE_PT3_X Y:CURVE_PT3_Y] forKey:@"inputPoint3"];
    [toneCurve setValue:[CIVector vectorWithX:CURVE_PT4_X Y:CURVE_PT4_Y] forKey:@"inputPoint4"];

    // filterView.layer.backgroundFilters = @[preTint, toneCurve];
    filterView.layer.backgroundFilters = @[toneCurve];
    [blurView addSubview:filterView];
    [themeFrame addSubview:blurView positioned:NSWindowBelow relativeTo:nil];
}

static void updateAlphas(void) {
    NSMutableArray<NSWindow *> *tracked = [NSMutableArray array];
    for (NSWindow *w in [NSApp windows])
        if (w.isVisible && blurViewForWindow(w))
            [tracked addObject:w];

    for (NSWindow *w in tracked) {
        NSInteger n = 1;
        for (NSWindow *other in tracked)
            if (other != w && NSIntersectsRect(w.frame, other.frame))
                n++;

        CGFloat a = 1.0 - pow(1.0 - BASE_ALPHA, 1.0 / (CGFloat)n);
        blurViewForWindow(w).alphaValue = a;
    }
}

__attribute__((constructor))
void recolor() {
        [NSTimer scheduledTimerWithTimeInterval:0.1 repeats:YES block:^(NSTimer *_) {
            for (NSWindow *w in [NSApp windows])
                if (w.isVisible) injectIfNeeded(w);
            updateAlphas();
        }];
}
