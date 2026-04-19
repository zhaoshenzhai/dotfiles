#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreImage/CoreImage.h>

static const CGFloat BASE_ALPHA = 0.95;
static const CGFloat BLUR_RADIUS = 100;

static const CGFloat INPUT_LUMAS[]      = {0.00, 0.25, 0.50, 0.75, 1.00};
static const CGFloat TARGET_OPACITIES[] = {0.92, 0.93, 0.94, 0.95, 0.96};

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

    NSView *themeFrame = window.contentView.superview;

    NSView *blackView = [[NSView alloc] initWithFrame:themeFrame.bounds];
    blackView.autoresizingMask      = NSViewWidthSizable | NSViewHeightSizable;
    blackView.wantsLayer            = YES;
    blackView.layer.backgroundColor = [[NSColor clearColor] CGColor];
    blackView.identifier            = @"ObsidianBlackView";
    [themeFrame addSubview:blackView positioned:NSWindowBelow relativeTo:nil];

    NSGlassEffectView *glassView = [[NSGlassEffectView alloc] initWithFrame:themeFrame.bounds];
    glassView.autoresizingMask   = NSViewWidthSizable | NSViewHeightSizable;
    glassView.style              = NSGlassEffectViewStyleClear;
    glassView.alphaValue         = BASE_ALPHA;
    glassView.identifier         = @"LiquidGlassView";
    [themeFrame addSubview:glassView positioned:NSWindowBelow relativeTo:nil];
}

static void applyDynamicToneCurve(NSView *blackView, NSInteger overlapCount) {
    // CIAffineClamp extends edge pixels infinitely before the blur samples them,
    // preventing the dark vignette that CIGaussianBlur produces at layer edges.
    CIFilter *clamp = [CIFilter filterWithName:@"CIAffineClamp"];
    [clamp setValue:[NSAffineTransform transform] forKey:kCIInputTransformKey];

    CIFilter *blur = [CIFilter filterWithName:@"CIGaussianBlur"];
    [blur setValue:@(BLUR_RADIUS) forKey:kCIInputRadiusKey];

    CIFilter *toneCurve = [CIFilter filterWithName:@"CIToneCurve"];
    for (int i = 0; i < 5; i++) {
        CGFloat L           = INPUT_LUMAS[i];
        CGFloat targetAlpha = TARGET_OPACITIES[i];
        CGFloat multiplier  = pow(1.0 - targetAlpha, 1.0 / (CGFloat)overlapCount);
        CGFloat outputY     = L * multiplier;
        NSString *key = [NSString stringWithFormat:@"inputPoint%d", i];
        [toneCurve setValue:[CIVector vectorWithX:L Y:outputY] forKey:key];
    }

    // Order: clamp → blur → tone curve.
    // The clamp must come first so the blur never samples outside real pixels.
    blackView.layer.backgroundFilters = @[clamp, blur, toneCurve];
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

        NSView *blackView = findTagged(w, @"ObsidianBlackView");
        if (blackView) applyDynamicToneCurve(blackView, n);
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
