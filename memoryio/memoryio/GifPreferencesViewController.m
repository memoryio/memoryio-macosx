
#import "GifPreferencesViewController.h"

@implementation GifPreferencesViewController

NSTextField *frameCountText;
NSTextField *frameDelayText;
NSTextField *loopCountText;

- (NSView*)makeView
{
    NSView *view = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 388, 231)];

    NSNumberFormatter *dec = [[NSNumberFormatter alloc] init];
    [dec setNumberStyle:NSNumberFormatterDecimalStyle];
    [dec setMaximumFractionDigits:1];
    [dec setMinimumFractionDigits:1];

    NSTextField *label = [[NSTextField alloc] initWithFrame:NSMakeRect(43,44,302,41)];
    [label setStringValue:@"If count * time is less than 2.00 (seconds) it will seem speedy"];
    [label setBezeled:NO];
    [label setDrawsBackground:NO];
    [label setEditable:NO];
    [label setSelectable:NO];
    [view addSubview:label];

    NSTextField *frameCountTextLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(43,165,175,17)];
    [frameCountTextLabel setStringValue:@"Number of pictures in Gif"];
    [frameCountTextLabel setBezeled:NO];
    [frameCountTextLabel setDrawsBackground:NO];
    [frameCountTextLabel setEditable:NO];
    [frameCountTextLabel setSelectable:NO];
    [view addSubview:frameCountTextLabel];

    NSNumberFormatter *integer = [[NSNumberFormatter alloc] init];
    [integer setNumberStyle:NSNumberFormatterNoStyle];

    frameCountText = [[NSTextField alloc] initWithFrame:NSMakeRect(234,165,96,22)];
    [frameCountText setAction:@selector(frameCountDidChange:)];
    [frameCountText setTarget:self];
    [frameCountText becomeFirstResponder];
    [frameCountText setFormatter:integer];
    [view addSubview:frameCountText];

    NSTextField *frameDelayTextLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(43,137,175,17)];
    [frameDelayTextLabel setStringValue:@"Seconds per frame"];
    [frameDelayTextLabel setBezeled:NO];
    [frameDelayTextLabel setDrawsBackground:NO];
    [frameDelayTextLabel setEditable:NO];
    [frameDelayTextLabel setSelectable:NO];
    [view addSubview:frameDelayTextLabel];

    frameDelayText = [[NSTextField alloc] initWithFrame:NSMakeRect(234,135,96,22)];
    [frameDelayText setAction:@selector(frameDelayDidChange:)];
    [frameDelayText setTarget:self];
    [frameDelayText setFormatter:dec];
    [view addSubview:frameDelayText];

    NSTextField *loopCountTextLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(43,108,175,17)];
    [loopCountTextLabel setStringValue:@"Gif Loop Count"];
    [loopCountTextLabel setBezeled:NO];
    [loopCountTextLabel setDrawsBackground:NO];
    [loopCountTextLabel setEditable:NO];
    [loopCountTextLabel setSelectable:NO];
    [view addSubview:loopCountTextLabel];

    loopCountText = [[NSTextField alloc] initWithFrame:NSMakeRect(234,105,96,22)];
    [loopCountText setAction:@selector(loopCountDidChange:)];
    [loopCountText setTarget:self];
    [loopCountText setFormatter:dec];
    [view addSubview:loopCountText];
    return view;
}

-(void)loadView
{
    self.view = [self makeView];

    [self populateFrameCount];
    [self populateLoopCount];
    [self populateFrameDelay];
}

#pragma Preferences

- (IBAction)frameCountDidChange:(NSTextField*)sender {
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:(int)[sender integerValue]] forKey:@"memoryio-gif-frame-count"];
}

- (IBAction)frameDelayDidChange:(NSTextField*)sender {
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithFloat:[sender floatValue]] forKey:@"memoryio-gif-frame-delay"];
}

- (IBAction)loopCountDidChange:(NSTextField*)sender {
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:(int)[sender integerValue]] forKey:@"memoryio-gif-loop-count"];
}

- (void) populateFrameCount{
    
    NSNumber *frameCount = [[NSUserDefaults standardUserDefaults] objectForKey:@"memoryio-gif-frame-count"];
    [frameCountText setIntValue:frameCount.intValue];
}

- (void) populateLoopCount{
    
    NSNumber *loopCount = [[NSUserDefaults standardUserDefaults] objectForKey:@"memoryio-gif-loop-count"];
    [loopCountText setIntValue:loopCount.intValue];
}

- (void) populateFrameDelay{
    
    NSNumber *frameDelay = [[NSUserDefaults standardUserDefaults] objectForKey:@"memoryio-gif-frame-delay"];
    [frameDelayText setFloatValue:frameDelay.floatValue];
}


#pragma mark - MASPreferencesViewController

- (NSString *)viewIdentifier
{
    return @"GifPreferences";
}

- (NSImage *)toolbarItemImage
{
    return [NSImage imageNamed:NSImageNamePreferencesGeneral];
}

- (NSString *)toolbarItemLabel
{
    return NSLocalizedString(@"Gif", @"Toolbar item name for the General preference pane");
}


@end
