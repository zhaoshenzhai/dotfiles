#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreImage/CoreImage.h>

typedef int CGSConnectionID;
extern CGSConnectionID CGSMainConnectionID(void);
extern CGError CGSSetWindowBackgroundBlurRadius(CGSConnectionID cid, NSInteger wid, int radius);

static const CGFloat BLUR_RADIUS = 50;

// --- GLOBAL OPACITY SETTINGS ---
static const CGFloat MIN_ALPHA = 1; // Base opacity for dark backgrounds
static const CGFloat MAX_ALPHA = 0.8; // Peak opacity for bright backgrounds

// static const CGFloat CURVE_PT0_X = 0.00; static const CGFloat CURVE_PT0_Y = 0.00;
// static const CGFloat CURVE_PT1_X = 0.25; static const CGFloat CURVE_PT1_Y = 0.25;
// static const CGFloat CURVE_PT2_X = 0.50; static const CGFloat CURVE_PT2_Y = 0.15;
// static const CGFloat CURVE_PT3_X = 0.75; static const CGFloat CURVE_PT3_Y = 0.00;
// static const CGFloat CURVE_PT4_X = 1.00; static const CGFloat CURVE_PT4_Y = 0.00;
static const CGFloat CURVE_PT0_X = 0.00; static const CGFloat CURVE_PT0_Y = 0.00;
static const CGFloat CURVE_PT1_X = 0.25; static const CGFloat CURVE_PT1_Y = 0.05;
static const CGFloat CURVE_PT2_X = 0.50; static const CGFloat CURVE_PT2_Y = 0.10;
static const CGFloat CURVE_PT3_X = 0.75; static const CGFloat CURVE_PT3_Y = 0.15;
static const CGFloat CURVE_PT4_X = 1.00; static const CGFloat CURVE_PT4_Y = 0.04;
// static const CGFloat CURVE_PT0_X = 0.00; static const CGFloat CURVE_PT0_Y = 0.00;
// static const CGFloat CURVE_PT1_X = 0.25; static const CGFloat CURVE_PT1_Y = 0.25;
// static const CGFloat CURVE_PT2_X = 0.50; static const CGFloat CURVE_PT2_Y = 0.50;
// static const CGFloat CURVE_PT3_X = 0.75; static const CGFloat CURVE_PT3_Y = 0.75;
// static const CGFloat CURVE_PT4_X = 1.00; static const CGFloat CURVE_PT4_Y = 1.00;

static CIFilter *createCombinedCubeFilter(CGFloat minAlpha, CGFloat maxAlpha) {
    const int size = 32;
    size_t cubeDataSize = size * size * size * 4 * sizeof(float);
    float *cubeData = (float *)malloc(cubeDataSize);
    float *c = cubeData;

    float alphaDiff = maxAlpha - minAlpha;

    for (int z = 0; z < size; z++) {       // Blue
        for (int y = 0; y < size; y++) {   // Green
            for (int x = 0; x < size; x++) { // Red
                float r = x / (float)(size - 1);
                float g = y / (float)(size - 1);
                float b = z / (float)(size - 1);

                // 1. Calculate Dynamic Alpha based on original perceived luminance
                float perceivedLuma = 0.2126f * r + 0.7152f * g + 0.0722f * b;
                float alphaOut = minAlpha + (perceivedLuma * alphaDiff);

                // 2. Convert RGB to HSL
                float max = fmaxf(r, fmaxf(g, b));
                float min = fminf(r, fminf(g, b));
                float l = (max + min) / 2.0f;
                float h = 0.0f, s = 0.0f;

                if (max != min) {
                    float d = max - min;
                    s = l > 0.5f ? d / (2.0f - max - min) : d / (max + min);
                    if (max == r) h = (g - b) / d + (g < b ? 6.0f : 0.0f);
                    else if (max == g) h = (b - r) / d + 2.0f;
                    else if (max == b) h = (r - g) / d + 4.0f;
                    h /= 6.0f;
                }

                // 3. Apply the 5-point curve strictly to Lightness (l)
                float newL = l;
                if (l <= CURVE_PT1_X) {
                    newL = l * (CURVE_PT1_Y / CURVE_PT1_X);
                } else if (l <= CURVE_PT2_X) {
                    newL = CURVE_PT1_Y + ((CURVE_PT2_Y - CURVE_PT1_Y) / (CURVE_PT2_X - CURVE_PT1_X)) * (l - CURVE_PT1_X);
                } else if (l <= CURVE_PT3_X) {
                    newL = CURVE_PT2_Y + ((CURVE_PT3_Y - CURVE_PT2_Y) / (CURVE_PT3_X - CURVE_PT2_X)) * (l - CURVE_PT2_X);
                } else {
                    newL = CURVE_PT4_Y;
                }

                // 4. Convert HSL back to RGB
                float rOut = newL, gOut = newL, bOut = newL;
                if (s != 0.0f) {
                    float q = newL < 0.5f ? newL * (1.0f + s) : newL + s - newL * s;
                    float p = 2.0f * newL - q;
                    float tr = h + 1.0f/3.0f;
                    float tg = h;
                    float tb = h - 1.0f/3.0f;

                    // Red
                    if (tr < 0.0f) tr += 1.0f; if (tr > 1.0f) tr -= 1.0f;
                    if (tr < 1.0f/6.0f) rOut = p + (q - p) * 6.0f * tr;
                    else if (tr < 1.0f/2.0f) rOut = q;
                    else if (tr < 2.0f/3.0f) rOut = p + (q - p) * (2.0f/3.0f - tr) * 6.0f;
                    else rOut = p;

                    // Green
                    if (tg < 0.0f) tg += 1.0f; if (tg > 1.0f) tg -= 1.0f;
                    if (tg < 1.0f/6.0f) gOut = p + (q - p) * 6.0f * tg;
                    else if (tg < 1.0f/2.0f) gOut = q;
                    else if (tg < 2.0f/3.0f) gOut = p + (q - p) * (2.0f/3.0f - tg) * 6.0f;
                    else gOut = p;

                    // Blue
                    if (tb < 0.0f) tb += 1.0f; if (tb > 1.0f) tb -= 1.0f;
                    if (tb < 1.0f/6.0f) bOut = p + (q - p) * 6.0f * tb;
                    else if (tb < 1.0f/2.0f) bOut = q;
                    else if (tb < 2.0f/3.0f) bOut = p + (q - p) * (2.0f/3.0f - tb) * 6.0f;
                    else bOut = p;
                }

                // 5. CRITICAL: Pre-multiply RGB by Alpha for macOS WindowServer compositing
                *c++ = rOut * alphaOut;
                *c++ = gOut * alphaOut;
                *c++ = bOut * alphaOut;
                *c++ = alphaOut; // Alpha channel
            }
        }
    }

    NSData *data = [NSData dataWithBytes:cubeData length:cubeDataSize];
    free(cubeData);

    CIFilter *cubeFilter = [CIFilter filterWithName:@"CIColorCube"];
    [cubeFilter setValue:@(size) forKey:@"inputCubeDimension"];
    [cubeFilter setValue:data forKey:@"inputCubeData"];

    return cubeFilter;
}

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

    CGSSetWindowBackgroundBlurRadius(CGSMainConnectionID(), [window windowNumber], BLUR_RADIUS);

    NSView *themeFrame = window.contentView.superview;

    NSVisualEffectView *mainBlurEffect = [[NSVisualEffectView alloc] initWithFrame:themeFrame.bounds];
    mainBlurEffect.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    mainBlurEffect.blendingMode = NSVisualEffectBlendingModeBehindWindow;
    mainBlurEffect.material = NSVisualEffectMaterialHUDWindow;
    // mainBlurEffect.material = NSVisualEffectMaterialFullScreenUI;
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

    // CIFilter *opacityCurve = [CIFilter filterWithName:@"CIColorMatrix"];
    // CGFloat alphaDiff = MAX_ALPHA - MIN_ALPHA;
    // [opacityCurve setValue:[CIVector vectorWithX:1 Y:0 Z:0 W:0] forKey:@"inputRVector"];
    // [opacityCurve setValue:[CIVector vectorWithX:0 Y:1 Z:0 W:0] forKey:@"inputGVector"];
    // [opacityCurve setValue:[CIVector vectorWithX:0 Y:0 Z:1 W:0] forKey:@"inputBVector"];
    // [opacityCurve setValue:[CIVector vectorWithX:alphaDiff Y:alphaDiff Z:alphaDiff W:0.0] forKey:@"inputAVector"];
    // // [opacityCurve setValue:[CIVector vectorWithX:0.2126 * alphaDiff Y:0.7152 * alphaDiff Z:0.0722 * alphaDiff W:0.0] forKey:@"inputAVector"];
    // [opacityCurve setValue:[CIVector vectorWithX:0 Y:0 Z:0 W:MIN_ALPHA] forKey:@"inputBiasVector"];

    CIFilter *combinedFilter = createCombinedCubeFilter(MIN_ALPHA, MAX_ALPHA);
    filterView.layer.backgroundFilters = @[combinedFilter];

    // filterView.layer.backgroundFilters = @[opacityCurve, toneCurve];
    // filterView.layer.backgroundFilters = @[toneCurve];

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
