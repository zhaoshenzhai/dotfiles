#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreImage/CoreImage.h>

// --- GLOBAL OPACITY SETTINGS ---
static const CGFloat MIN_ALPHA = 0.8; // Base opacity for dark backgrounds
static const CGFloat MAX_ALPHA = 0.90; // Peak opacity for bright backgrounds

static const CGFloat CURVE_PT0_X = 0.00; static const CGFloat CURVE_PT0_Y = 0.00;
static const CGFloat CURVE_PT1_X = 0.25; static const CGFloat CURVE_PT1_Y = 0.20;
static const CGFloat CURVE_PT2_X = 0.50; static const CGFloat CURVE_PT2_Y = 0.15;
static const CGFloat CURVE_PT3_X = 0.75; static const CGFloat CURVE_PT3_Y = 0.00;
static const CGFloat CURVE_PT4_X = 1.00; static const CGFloat CURVE_PT4_Y = 0.00;
// static const CGFloat CURVE_PT0_X = 0.00; static const CGFloat CURVE_PT0_Y = 0.00;
// static const CGFloat CURVE_PT1_X = 0.25; static const CGFloat CURVE_PT1_Y = 0.25;
// static const CGFloat CURVE_PT2_X = 0.50; static const CGFloat CURVE_PT2_Y = 0.50;
// static const CGFloat CURVE_PT3_X = 0.75; static const CGFloat CURVE_PT3_Y = 0.75;
// static const CGFloat CURVE_PT4_X = 1.00; static const CGFloat CURVE_PT4_Y = 1.00;

@interface HuePreservingCurveFilter : CIFilter
@property (nonatomic, strong) CIImage *inputImage;
@end

@implementation HuePreservingCurveFilter
- (CIImage *)outputImage {
    if (!self.inputImage) return nil;

    // 1. Apply the heavy curve to create our new Lightness Map
    CIFilter *toneCurve = [CIFilter filterWithName:@"CIToneCurve"];
    [toneCurve setValue:self.inputImage forKey:kCIInputImageKey];
    [toneCurve setValue:[CIVector vectorWithX:CURVE_PT0_X Y:CURVE_PT0_Y] forKey:@"inputPoint0"];
    [toneCurve setValue:[CIVector vectorWithX:CURVE_PT1_X Y:CURVE_PT1_Y] forKey:@"inputPoint1"];
    [toneCurve setValue:[CIVector vectorWithX:CURVE_PT2_X Y:CURVE_PT2_Y] forKey:@"inputPoint2"];
    [toneCurve setValue:[CIVector vectorWithX:CURVE_PT3_X Y:CURVE_PT3_Y] forKey:@"inputPoint3"];
    [toneCurve setValue:[CIVector vectorWithX:CURVE_PT4_X Y:CURVE_PT4_Y] forKey:@"inputPoint4"];

    // 2. Blend the new Lightness with the original Hue/Saturation
    CIFilter *blend = [CIFilter filterWithName:@"CILuminosityBlendMode"];
    [blend setValue:toneCurve.outputImage forKey:kCIInputImageKey]; // Foreground provides Lightness
    [blend setValue:self.inputImage forKey:kCIInputBackgroundImageKey]; // Background provides Color

    return blend.outputImage;
}
@end

static NSVisualEffectView *getEffectWindow(NSWindow *window) {
    if (!window.contentView || !window.contentView.superview) return nil;
    for (NSView *subview in window.contentView.superview.subviews)
        if ([subview.identifier isEqualToString:@"mainBlurEffect"])
            return (NSVisualEffectView *)subview;
    return nil;
}

static void injectIfNeeded(NSWindow *window) {
    if (!window.contentView || !window.contentView.superview) return;
    if (getEffectWindow(window)) return;

    window.opaque = NO;
    window.backgroundColor = [NSColor clearColor];

    NSView *themeFrame = window.contentView.superview;

    NSVisualEffectView *mainBlurEffect = [[NSVisualEffectView alloc] initWithFrame:themeFrame.bounds];
    mainBlurEffect.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    mainBlurEffect.blendingMode = NSVisualEffectBlendingModeBehindWindow;
    mainBlurEffect.material = NSVisualEffectMaterialHUDWindow;
    mainBlurEffect.state = NSVisualEffectStateActive;
    mainBlurEffect.appearance = [NSAppearance appearanceNamed:NSAppearanceNameVibrantDark];
    mainBlurEffect.identifier = @"mainBlurEffect";
    mainBlurEffect.alphaValue = 1.0;

    NSView *filterView = [[NSView alloc] initWithFrame:mainBlurEffect.bounds];
    filterView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    filterView.wantsLayer = YES;
    filterView.layer.backgroundColor = [[NSColor clearColor] CGColor];
    filterView.identifier = @"filterView";

    // CIFilter *toneCurve = [CIFilter filterWithName:@"CIToneCurve"];
    // [toneCurve setValue:[CIVector vectorWithX:CURVE_PT0_X Y:CURVE_PT0_Y] forKey:@"inputPoint0"];
    // [toneCurve setValue:[CIVector vectorWithX:CURVE_PT1_X Y:CURVE_PT1_Y] forKey:@"inputPoint1"];
    // [toneCurve setValue:[CIVector vectorWithX:CURVE_PT2_X Y:CURVE_PT2_Y] forKey:@"inputPoint2"];
    // [toneCurve setValue:[CIVector vectorWithX:CURVE_PT3_X Y:CURVE_PT3_Y] forKey:@"inputPoint3"];
    // [toneCurve setValue:[CIVector vectorWithX:CURVE_PT4_X Y:CURVE_PT4_Y] forKey:@"inputPoint4"];

    CIFilter *opacityCurve = [CIFilter filterWithName:@"CIColorMatrix"];
    CGFloat alphaDiff = MAX_ALPHA - MIN_ALPHA;
    [opacityCurve setValue:[CIVector vectorWithX:1 Y:0 Z:0 W:0] forKey:@"inputRVector"];
    [opacityCurve setValue:[CIVector vectorWithX:0 Y:1 Z:0 W:0] forKey:@"inputGVector"];
    [opacityCurve setValue:[CIVector vectorWithX:0 Y:0 Z:1 W:0] forKey:@"inputBVector"];
    // [opacityCurve setValue:[CIVector vectorWithX:alphaDiff Y:alphaDiff Z:alphaDiff W:0.0] forKey:@"inputAVector"];
    [opacityCurve setValue:[CIVector vectorWithX:0.2126 * alphaDiff Y:0.7152 * alphaDiff Z:0.0722 * alphaDiff W:0.0] forKey:@"inputAVector"];
    [opacityCurve setValue:[CIVector vectorWithX:0 Y:0 Z:0 W:MIN_ALPHA] forKey:@"inputBiasVector"];

    HuePreservingCurveFilter *huePreserver = [[HuePreservingCurveFilter alloc] init];

    // filterView.layer.backgroundFilters = @[opacityCurve, toneCurve];
    // filterView.layer.backgroundFilters = @[toneCurve];
    filterView.layer.backgroundFilters = @[opacityCurve, huePreserver];

    [themeFrame addSubview:mainBlurEffect positioned:NSWindowBelow relativeTo:nil];
    [mainBlurEffect addSubview:filterView];
}

static void updateAlphas(void) {
    NSMutableArray<NSWindow *> *tracked = [NSMutableArray array];
    for (NSWindow *w in [NSApp windows])
        if (w.isVisible && getEffectWindow(w))
            [tracked addObject:w];

    for (NSWindow *w in tracked) {
        NSInteger n = 1;
        for (NSWindow *other in tracked)
            if (other != w && NSIntersectsRect(w.frame, other.frame))
                n++;

        CGFloat adjustedMin = 1.0 - pow(1.0 - MIN_ALPHA, 1.0 / (CGFloat)n);
        CGFloat adjustedMax = 1.0 - pow(1.0 - MAX_ALPHA, 1.0 / (CGFloat)n);
        CGFloat adjustedDiff = adjustedMax - adjustedMin;

        NSVisualEffectView *mainBlurEffect = getEffectWindow(w);
        if (!mainBlurEffect) continue;

        NSView *filterView = nil;
        for (NSView *v in mainBlurEffect.subviews) {
            if ([v.identifier isEqualToString:@"filterView"]) {
                filterView = v;
                break;
            }
        }

        if (filterView && filterView.layer.backgroundFilters.count >= 2) {
            NSArray *filters = filterView.layer.backgroundFilters;

            // Because opacityCurve is now first, we pull from index 0
            CIFilter *opacityCurve = filters[0];

            [opacityCurve setValue:[CIVector vectorWithX:0.2126 * adjustedDiff Y:0.7152 * adjustedDiff Z:0.0722 * adjustedDiff W:0.0] forKey:@"inputAVector"];
            [opacityCurve setValue:[CIVector vectorWithX:0 Y:0 Z:0 W:adjustedMin] forKey:@"inputBiasVector"];

            filterView.layer.backgroundFilters = filters;
        }
    }
}

__attribute__((constructor))
void recolor() {
    [NSTimer scheduledTimerWithTimeInterval:0.1 repeats:YES block:^(NSTimer *_) {
        for (NSWindow *w in [NSApp windows])
            if (w.isVisible) injectIfNeeded(w);
        // updateAlphas();
    }];
}
