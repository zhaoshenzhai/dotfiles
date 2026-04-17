#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreImage/CoreImage.h>

__attribute__((constructor))
void clamp_brightness_poc() {
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

        CIFilter *preTint = [CIFilter filterWithName:@"CIColorMatrix"];
        [preTint setValue:[CIVector vectorWithX:0.95 Y:0.0 Z:0.0 W:0.0] forKey:@"inputRVector"];
        [preTint setValue:[CIVector vectorWithX:0.0 Y:0.90 Z:0.0 W:0.0] forKey:@"inputGVector"];
        [preTint setValue:[CIVector vectorWithX:0.0 Y:0.0 Z:0.85 W:0.0] forKey:@"inputBVector"];
        [preTint setValue:[CIVector vectorWithX:0.0 Y:0.0 Z:0.0 W:1.0] forKey:@"inputAVector"];

        CIFilter *toneCurve = [CIFilter filterWithName:@"CIToneCurve"];
        [toneCurve setValue:[CIVector vectorWithX:0.00 Y:0.00] forKey:@"inputPoint0"];
        [toneCurve setValue:[CIVector vectorWithX:0.25 Y:0.25] forKey:@"inputPoint1"];
        [toneCurve setValue:[CIVector vectorWithX:0.50 Y:0.20] forKey:@"inputPoint2"];
        [toneCurve setValue:[CIVector vectorWithX:0.75 Y:0.00] forKey:@"inputPoint3"];
        [toneCurve setValue:[CIVector vectorWithX:1.00 Y:0.00] forKey:@"inputPoint4"];

        filterView.layer.backgroundFilters = @[preTint, toneCurve];
        [blurView addSubview:filterView];

        [themeFrame addSubview:blurView positioned:NSWindowBelow relativeTo:nil];
    }];
}
