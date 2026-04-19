#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreImage/CoreImage.h>

// ==========================================
// === GLOBAL TUNING PARAMETERS ===
// ==========================================

// 1. The Cutoff: What is considered "Bright"?
static const float G_CUTOFF_LUMA = 0.07;

// 2. The Black Target: How dark should the white PDF become?
static const float G_BLACK_LUMA = 0.008;

// 3. Saturation Boost:
static const float G_SAT_BOOST = 3.00;

// 4. Effect Intensity (The fixed filter opacity):
// 0.0 means no effect (standard macOS blur). 1.0 means full Black crush.
// We bake this directly into the color math so Core Animation cannot ignore it.
static const float G_EFFECT_INTENSITY = 1.0;

// 5. Overall Window Transparency:
// Controls how "see-through" the entire terminal window is.
// 1.0 is standard blur. 0.8 makes the terminal more physically transparent to the desktop.
static const float G_WINDOW_TRANSPARENCY = 1.00;

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

                // The Hard Cutoff Logic
                if (luma > G_CUTOFF_LUMA) {
                    targetLuma = G_BLACK_LUMA;
                    currentSatBoost = G_SAT_BOOST;
                }

                // Scale RGB
                float factor = luma > 0.001 ? targetLuma / luma : 1.0;
                float outR = r * factor;
                float outG = g * factor;
                float outB = b * factor;

                // Apply Saturation Boost
                float newLuma = outR * 0.2126 + outG * 0.7152 + outB * 0.0722;
                outR = newLuma + (outR - newLuma) * currentSatBoost;
                outG = newLuma + (outG - newLuma) * currentSatBoost;
                outB = newLuma + (outB - newLuma) * currentSatBoost;

                // THE FIX: Apply the Effect Intensity mathematically
                // We linearly mix the original pixel (r,g,b) with our customized pixel (outR, outG, outB)
                outR = r + (outR - r) * G_EFFECT_INTENSITY;
                outG = g + (outG - g) * G_EFFECT_INTENSITY;
                outB = b + (outB - b) * G_EFFECT_INTENSITY;

                cubeData[offset++] = MIN(MAX(outR, 0.0), 1.0);
                cubeData[offset++] = MIN(MAX(outG, 0.0), 1.0);
                cubeData[offset++] = MIN(MAX(outB, 0.0), 1.0);
                cubeData[offset++] = 1.0f; // Alpha remains 1.0, transparency is handled by the View
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

    NSView *themeFrame = window.contentView.superview;

    // Base Blur Layer handles the physical window transparency
    NSVisualEffectView *mainBlurEffect = [[NSVisualEffectView alloc] initWithFrame:themeFrame.bounds];
    mainBlurEffect.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    mainBlurEffect.blendingMode = NSVisualEffectBlendingModeBehindWindow;
    mainBlurEffect.material = NSVisualEffectMaterialHUDWindow;
    mainBlurEffect.state = NSVisualEffectStateActive;
    mainBlurEffect.appearance = [NSAppearance appearanceNamed:NSAppearanceNameVibrantDark];
    mainBlurEffect.identifier = @"mainBlurEffect";
    mainBlurEffect.alphaValue = G_WINDOW_TRANSPARENCY; // Fixed window transparency control

    // Filter Layer handles the color grading
    NSView *filterView = [[NSView alloc] initWithFrame:mainBlurEffect.bounds];
    filterView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    filterView.wantsLayer = YES;
    filterView.layer.backgroundColor = [[NSColor clearColor] CGColor];
    filterView.identifier = @"filterView";
    filterView.alphaValue = 1.0; // Left at 1.0 because the C-loop handles effect intensity

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
