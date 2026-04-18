#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreImage/CoreImage.h>

static const CGFloat CURVE_PT0_X = 0.00; static const CGFloat CURVE_PT0_Y = 0.00;
static const CGFloat CURVE_PT1_X = 0.25; static const CGFloat CURVE_PT1_Y = 0.20;
static const CGFloat CURVE_PT2_X = 0.50; static const CGFloat CURVE_PT2_Y = 0.15;
static const CGFloat CURVE_PT3_X = 0.75; static const CGFloat CURVE_PT3_Y = 0.05;
static const CGFloat CURVE_PT4_X = 1.00; static const CGFloat CURVE_PT4_Y = 0.00;

static const CGFloat BASE_ALPHA = 0.90;

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

    CIFilter *toneCurve = [CIFilter filterWithName:@"CIToneCurve"];
    [toneCurve setValue:[CIVector vectorWithX:CURVE_PT0_X Y:CURVE_PT0_Y] forKey:@"inputPoint0"];
    [toneCurve setValue:[CIVector vectorWithX:CURVE_PT1_X Y:CURVE_PT1_Y] forKey:@"inputPoint1"];
    [toneCurve setValue:[CIVector vectorWithX:CURVE_PT2_X Y:CURVE_PT2_Y] forKey:@"inputPoint2"];
    [toneCurve setValue:[CIVector vectorWithX:CURVE_PT3_X Y:CURVE_PT3_Y] forKey:@"inputPoint3"];
    [toneCurve setValue:[CIVector vectorWithX:CURVE_PT4_X Y:CURVE_PT4_Y] forKey:@"inputPoint4"];

    filterView.layer.backgroundFilters = @[toneCurve];
    [blurView addSubview:filterView];
    [themeFrame addSubview:blurView positioned:NSWindowBelow relativeTo:nil];

    NSVisualEffectView *trueBlurLayer = [[NSVisualEffectView alloc] initWithFrame:themeFrame.bounds];
    trueBlurLayer.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    trueBlurLayer.blendingMode = NSVisualEffectBlendingModeBehindWindow;
    trueBlurLayer.material = NSVisualEffectMaterialPopover;
    trueBlurLayer.state = NSVisualEffectStateActive;
    trueBlurLayer.alphaValue = 1.0;

    [themeFrame addSubview:trueBlurLayer positioned:NSWindowBelow relativeTo:blurView];
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
