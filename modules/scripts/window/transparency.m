#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreImage/CoreImage.h>

typedef int CGSConnectionID;
extern CGSConnectionID CGSMainConnectionID(void);
extern CGError CGSSetWindowBackgroundBlurRadius(CGSConnectionID cid, NSInteger wid, int radius);

// ==========================================
// === GLOBAL TUNING PARAMETERS ===
// ==========================================

static const CGFloat BLUR_RADIUS = 30;

// 1. The Cutoff: What is considered "Bright"?
static const float G_CUTOFF_LUMA = 0.07;

// 2. The Black Target: How dark should the white PDF become?
static const float G_BLACK_LUMA = 0.008;

// 3. Saturation Boost:
static const float G_SAT_BOOST = 3.00;

// 4. NEW: Obsidian Tint (Blueish-Black overlay for bright backgrounds)
// Since white PDFs have no color to boost, we inject a custom blue hue.
static const float G_TINT_R = 0.15; // Red channel ratio
static const float G_TINT_G = 0.28; // Green channel ratio
static const float G_TINT_B = 0.35; // Blue channel ratio (highest for a deep blue)
static const float G_TINT_WEIGHT = 0.5; // How strongly to apply this tint (0.0 to 1.0)

// 5. Effect Intensity (The fixed filter opacity):
static const float G_EFFECT_INTENSITY = 1.0;

// 6. Overall Window Transparency:
static const float G_WINDOW_TRANSPARENCY = 0.9;

// ==========================================


static NSData *generateBlackLUT(void) {
    NSInteger dimension = 16;
    NSUInteger totalElements = dimension * dimension * dimension * 4;
    float *cubeData = (float *)malloc(totalElements * sizeof(float));

    int offset = 0;
    for (int z = 0; z < dimension; z++) {       // Blue
        float b = (float)z / (dimension - 1);
        for (int y = 0; y < dimension; y++) {   // Green
            float g = (float)y / (dimension - 1);
            for (int x = 0; x < dimension; x++) { // Red
                float r = (float)x / (dimension - 1);

                float luma = r * 0.2126 + g * 0.7152 + b * 0.0722;
                float targetLuma = luma;
                float currentSatBoost = 1.0;
                int isCrushed = 0;

                // The Hard Cutoff Logic
                if (luma > G_CUTOFF_LUMA) {
                    targetLuma = G_BLACK_LUMA;
                    currentSatBoost = G_SAT_BOOST;
                    isCrushed = 1; // Flag that we triggered the cutoff
                }

                // Scale RGB
                float factor = luma > 0.001 ? targetLuma / luma : 1.0;
                float outR = r * factor;
                float outG = g * factor;
                float outB = b * factor;

                // NEW: Inject the custom hue if we crushed a bright background
                if (isCrushed) {
                    // We blend the natural crushed color with our target tint, scaled to match the darkness
                    outR = (outR * (1.0 - G_TINT_WEIGHT)) + (G_TINT_R * targetLuma * G_TINT_WEIGHT);
                    outG = (outG * (1.0 - G_TINT_WEIGHT)) + (G_TINT_G * targetLuma * G_TINT_WEIGHT);
                    outB = (outB * (1.0 - G_TINT_WEIGHT)) + (G_TINT_B * targetLuma * G_TINT_WEIGHT);
                }

                // Apply Saturation Boost (this will also boost the new blue tint!)
                float newLuma = outR * 0.2126 + outG * 0.7152 + outB * 0.0722;
                outR = newLuma + (outR - newLuma) * currentSatBoost;
                outG = newLuma + (outG - newLuma) * currentSatBoost;
                outB = newLuma + (outB - newLuma) * currentSatBoost;

                // Apply the Effect Intensity mathematically
                outR = r + (outR - r) * G_EFFECT_INTENSITY;
                outG = g + (outG - g) * G_EFFECT_INTENSITY;
                outB = b + (outB - b) * G_EFFECT_INTENSITY;

                cubeData[offset++] = MIN(MAX(outR, 0.0), 1.0);
                cubeData[offset++] = MIN(MAX(outG, 0.0), 1.0);
                cubeData[offset++] = MIN(MAX(outB, 0.0), 1.0);
                cubeData[offset++] = 1.0f;
            }
        }
    }

    return [NSData dataWithBytesNoCopy:cubeData length:totalElements * sizeof(float) freeWhenDone:YES];
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
    mainBlurEffect.state = NSVisualEffectStateActive;
    mainBlurEffect.appearance = [NSAppearance appearanceNamed:NSAppearanceNameVibrantDark];
    mainBlurEffect.identifier = @"mainBlurEffect";
    mainBlurEffect.alphaValue = G_WINDOW_TRANSPARENCY;

    NSView *filterView = [[NSView alloc] initWithFrame:mainBlurEffect.bounds];
    filterView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    filterView.wantsLayer = YES;
    filterView.layer.backgroundColor = [[NSColor clearColor] CGColor];
    filterView.identifier = @"filterView";
    filterView.alphaValue = 1.0;

    CIFilter *cubeFilter = [CIFilter filterWithName:@"CIColorCube"];
    [cubeFilter setValue:@(16) forKey:@"inputCubeDimension"];
    [cubeFilter setValue:generateBlackLUT() forKey:@"inputCubeData"];

    filterView.layer.backgroundFilters = @[cubeFilter];

    [themeFrame addSubview:mainBlurEffect positioned:NSWindowBelow relativeTo:nil];
    [mainBlurEffect addSubview:filterView];
}

__attribute__((constructor))
void recolor() {
    [NSTimer scheduledTimerWithTimeInterval:0.1 repeats:YES block:^(NSTimer *_) {
        for (NSWindow *w in [NSApp windows])
            if (w.isVisible) injectIfNeeded(w);
    }];
}
