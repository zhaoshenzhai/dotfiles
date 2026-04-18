#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreImage/CoreImage.h>

static const CGFloat TINT_R_X = 0.90; static const CGFloat TINT_R_Y = 0.00; static const CGFloat TINT_R_Z = 0.00; static const CGFloat TINT_R_W = 0.00;
static const CGFloat TINT_G_X = 0.00; static const CGFloat TINT_G_Y = 0.90; static const CGFloat TINT_G_Z = 0.00; static const CGFloat TINT_G_W = 0.00;
static const CGFloat TINT_B_X = 0.00; static const CGFloat TINT_B_Y = 0.00; static const CGFloat TINT_B_Z = 0.85; static const CGFloat TINT_B_W = 0.00;
static const CGFloat TINT_A_X = 0.00; static const CGFloat TINT_A_Y = 0.00; static const CGFloat TINT_A_Z = 0.00; static const CGFloat TINT_A_W = 1.00;

static const CGFloat CURVE_PT0_X = 0.00; static const CGFloat CURVE_PT0_Y = 0.00;
static const CGFloat CURVE_PT1_X = 0.25; static const CGFloat CURVE_PT1_Y = 0.25;
static const CGFloat CURVE_PT2_X = 0.50; static const CGFloat CURVE_PT2_Y = 0.20;
static const CGFloat CURVE_PT3_X = 0.75; static const CGFloat CURVE_PT3_Y = 0.10;
static const CGFloat CURVE_PT4_X = 1.00; static const CGFloat CURVE_PT4_Y = 0.10;

__attribute__((constructor))
void recolor() {
    [[NSNotificationCenter defaultCenter] addObserverForName:NSWindowDidBecomeMainNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {

        NSWindow *window = note.object;
        NSView *themeFrame = window.contentView.superview;

        BOOL alreadyInjected = NO;
        for (NSView *subview in themeFrame.subviews) {
            if ([subview.identifier isEqualToString:@"SafeDarkBlur"]) {
                alreadyInjected = YES;
                break;
            }
        }
        if (alreadyInjected) return;

        window.opaque = NO;
        window.backgroundColor = [NSColor clearColor];

        NSVisualEffectView *blurView = [[NSVisualEffectView alloc] initWithFrame:themeFrame.bounds];
        blurView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
        blurView.blendingMode = NSVisualEffectBlendingModeBehindWindow;

        blurView.material = NSVisualEffectMaterialHUDWindow;
        blurView.state = NSVisualEffectStateActive;
        blurView.appearance = [NSAppearance appearanceNamed:NSAppearanceNameVibrantDark];
        blurView.identifier = @"SafeDarkBlur";

        NSView *filterView = [[NSView alloc] initWithFrame:blurView.bounds];
        filterView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
        filterView.wantsLayer = YES;
        filterView.layer.backgroundColor = [[NSColor clearColor] CGColor];

        // CIFilter *preTint = [CIFilter filterWithName:@"CIColorMatrix"];
        // [preTint setValue:[CIVector vectorWithX:TINT_R_X Y:TINT_R_Y Z:TINT_R_Z W:TINT_R_W] forKey:@"inputRVector"];
        // [preTint setValue:[CIVector vectorWithX:TINT_G_X Y:TINT_G_Y Z:TINT_G_Z W:TINT_G_W] forKey:@"inputGVector"];
        // [preTint setValue:[CIVector vectorWithX:TINT_B_X Y:TINT_B_Y Z:TINT_B_Z W:TINT_B_W] forKey:@"inputBVector"];
        // [preTint setValue:[CIVector vectorWithX:TINT_A_X Y:TINT_A_Y Z:TINT_A_Z W:TINT_A_W] forKey:@"inputAVector"];

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
    }];
}
