#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreImage/CoreImage.h>

typedef int CGSConnectionID;
extern CGSConnectionID CGSMainConnectionID(void);
extern CGError CGSSetWindowBackgroundBlurRadius(CGSConnectionID cid, NSInteger wid, int radius);

static const CGFloat BLUR_RADIUS = 20;

// --- GLOBAL OPACITY SETTINGS ---
static const CGFloat MIN_ALPHA = 0.0; // Base opacity for dark backgrounds
static const CGFloat MAX_ALPHA = 0.9; // Peak opacity for bright backgrounds

// static const CGFloat CURVE_PT0_X = 0.00; static const CGFloat CURVE_PT0_Y = 0.00;
// static const CGFloat CURVE_PT1_X = 0.25; static const CGFloat CURVE_PT1_Y = 0.25;
// static const CGFloat CURVE_PT2_X = 0.50; static const CGFloat CURVE_PT2_Y = 0.15;
// static const CGFloat CURVE_PT3_X = 0.75; static const CGFloat CURVE_PT3_Y = 0.00;
// static const CGFloat CURVE_PT4_X = 1.00; static const CGFloat CURVE_PT4_Y = 0.00;
static const CGFloat CURVE_PT0_X = 0.00; static const CGFloat CURVE_PT0_Y = 0.00;
static const CGFloat CURVE_PT1_X = 0.25; static const CGFloat CURVE_PT1_Y = 0.00;
static const CGFloat CURVE_PT2_X = 0.50; static const CGFloat CURVE_PT2_Y = 0.00;
static const CGFloat CURVE_PT3_X = 0.75; static const CGFloat CURVE_PT3_Y = 0.00;
static const CGFloat CURVE_PT4_X = 1.00; static const CGFloat CURVE_PT4_Y = 0.00;
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

    // Generate the unified XPC-safe hardware LUT
    CIFilter *combinedFilter = createCombinedCubeFilter(MIN_ALPHA, MAX_ALPHA);

    // Apply the single filter
    filterView.layer.backgroundFilters = @[combinedFilter];

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

        NSVisualEffectView *mainBlurEffect = getEffectWindow(w);
        if (!mainBlurEffect) continue;

        NSView *filterView = nil;
        for (NSView *v in mainBlurEffect.subviews) {
            if ([v.identifier isEqualToString:@"filterView"]) {
                filterView = v;
                break;
            }
        }

        if (filterView) {
            // Generate a fresh LUT with the newly calculated overlap alpha parameters
            CIFilter *combinedFilter = createCombinedCubeFilter(adjustedMin, adjustedMax);

            // Overwrite the background array with the new LUT
            filterView.layer.backgroundFilters = @[combinedFilter];
        }
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
