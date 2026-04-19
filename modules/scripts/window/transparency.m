#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreImage/CoreImage.h>

// --- GLOBAL OPACITY SETTINGS ---
static const CGFloat MIN_ALPHA = 0.99; // Base opacity for pitch-black backgrounds
static const CGFloat MAX_ALPHA = 0.99; // Peak opacity for pure-white backgrounds

static const CGFloat CURVE_PT0_X = 0.00; static const CGFloat CURVE_PT0_Y = 0.00;
static const CGFloat CURVE_PT1_X = 0.25; static const CGFloat CURVE_PT1_Y = 0.20;
static const CGFloat CURVE_PT2_X = 0.50; static const CGFloat CURVE_PT2_Y = 0.15;
static const CGFloat CURVE_PT3_X = 0.75; static const CGFloat CURVE_PT3_Y = 0.00;
static const CGFloat CURVE_PT4_X = 1.00; static const CGFloat CURVE_PT4_Y = 0.00;

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

    // Set to 1.0 so the dynamic GPU filter underneath can dictate the actual transparency
    blurView.alphaValue = 1.0;

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

    CIFilter *dynamicOpacity = [CIFilter filterWithName:@"CIColorMatrix"];

    [dynamicOpacity setValue:[CIVector vectorWithX:1 Y:0 Z:0 W:0] forKey:@"inputRVector"];
    [dynamicOpacity setValue:[CIVector vectorWithX:0 Y:1 Z:0 W:0] forKey:@"inputGVector"];
    [dynamicOpacity setValue:[CIVector vectorWithX:0 Y:0 Z:1 W:0] forKey:@"inputBVector"];

    // Automatically calculate luminance multipliers based on the global MIN/MAX difference
    CGFloat alphaDiff = MAX_ALPHA - MIN_ALPHA;
    [dynamicOpacity setValue:[CIVector vectorWithX:0.2126 * alphaDiff Y:0.7152 * alphaDiff Z:0.0722 * alphaDiff W:0.0] forKey:@"inputAVector"];
    [dynamicOpacity setValue:[CIVector vectorWithX:0 Y:0 Z:0 W:MIN_ALPHA] forKey:@"inputBiasVector"];

    filterView.layer.backgroundFilters = @[toneCurve, dynamicOpacity];

    [blurView addSubview:filterView];
    [themeFrame addSubview:blurView positioned:NSWindowBelow relativeTo:nil];

    NSVisualEffectView *trueBlurLayer = [[NSVisualEffectView alloc] initWithFrame:themeFrame.bounds];
    trueBlurLayer.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    trueBlurLayer.blendingMode = NSVisualEffectBlendingModeBehindWindow;
    trueBlurLayer.material = NSVisualEffectMaterialHUDWindow;
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

        // Dynamically scale the overlap math to cap at the global MAX_ALPHA
        CGFloat a = 1.0;
        if (MAX_ALPHA > 0.0) {
            a = (1.0 - pow(1.0 - MAX_ALPHA, 1.0 / (CGFloat)n)) / MAX_ALPHA;
        }
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
