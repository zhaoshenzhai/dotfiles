#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>

static const CGFloat BASE_ALPHA = 0.95;

// ─── View lookup ─────────────────────────────────────────────────────────────

static NSView *findTagged(NSWindow *w, NSString *tag) {
    if (!w.contentView || !w.contentView.superview) return nil;
    for (NSView *v in w.contentView.superview.subviews)
        if ([v.identifier isEqualToString:tag]) return v;
    return nil;
}

// ─── Injection ───────────────────────────────────────────────────────────────

static void injectIfNeeded(NSWindow *window) {
    if (findTagged(window, @"LiquidGlassView")) return;
    if (!window.contentView || !window.contentView.superview) return;

    window.opaque          = NO;
    window.backgroundColor = NSColor.clearColor;

    NSView *themeFrame = window.contentView.superview;

    // Black obsidian layer — always off in dark mode preview.
    // Opacity stays at 0.0; re-enable SCKit luminance sampling when ready.
    NSView *blackView = [[NSView alloc] initWithFrame:themeFrame.bounds];
    blackView.autoresizingMask      = NSViewWidthSizable | NSViewHeightSizable;
    blackView.wantsLayer            = YES;
    blackView.layer.backgroundColor = [NSColor.blackColor CGColor];
    blackView.layer.opacity         = 0.6;
    blackView.identifier            = @"ObsidianBlackView";
    [themeFrame addSubview:blackView positioned:NSWindowBelow relativeTo:nil];

    // Liquid Glass on top.
    if (@available(macOS 26.0, *)) {
        NSGlassEffectView *glassView = [[NSGlassEffectView alloc] initWithFrame:themeFrame.bounds];
        glassView.autoresizingMask   = NSViewWidthSizable | NSViewHeightSizable;
        glassView.style              = NSGlassEffectViewStyleClear;
        glassView.alphaValue         = BASE_ALPHA;
        glassView.identifier         = @"LiquidGlassView";
        [themeFrame addSubview:glassView positioned:NSWindowBelow relativeTo:nil];
    } else {
        NSVisualEffectView *fallback = [[NSVisualEffectView alloc] initWithFrame:themeFrame.bounds];
        fallback.autoresizingMask    = NSViewWidthSizable | NSViewHeightSizable;
        fallback.blendingMode        = NSVisualEffectBlendingModeBehindWindow;
        fallback.material            = NSVisualEffectMaterialHUDWindow;
        fallback.state               = NSVisualEffectStateActive;
        fallback.appearance          = [NSAppearance appearanceNamed:NSAppearanceNameVibrantDark];
        fallback.alphaValue          = BASE_ALPHA;
        fallback.identifier          = @"LiquidGlassView";
        [themeFrame addSubview:fallback positioned:NSWindowBelow relativeTo:nil];
    }
}

// ─── Overlap alpha correction ─────────────────────────────────────────────────

static void updateAlphas(void) {
    NSMutableArray<NSWindow *> *tracked = [NSMutableArray array];
    for (NSWindow *w in NSApp.windows)
        if (w.isVisible && findTagged(w, @"LiquidGlassView"))
            [tracked addObject:w];

    for (NSWindow *w in tracked) {
        NSInteger n = 1;
        for (NSWindow *other in tracked)
            if (other != w && NSIntersectsRect(w.frame, other.frame)) n++;

        CGFloat a = 1.0 - pow(1.0 - BASE_ALPHA, 1.0 / (CGFloat)n);
        findTagged(w, @"LiquidGlassView").alphaValue = a;
    }
}

// ─── Entry point ─────────────────────────────────────────────────────────────

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
