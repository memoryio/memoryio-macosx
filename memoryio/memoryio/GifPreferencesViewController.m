
#import "GifPreferencesViewController.h"

@implementation GifPreferencesViewController

@synthesize frameCountText;
@synthesize frameDelayText;
@synthesize loopCountText;

- (id)init
{
    return [super initWithNibName:@"GifPreferencesView" bundle:nil];
}

-(void)loadView
{
    [super loadView];
    [self populateFrameCount];
    [self populateLoopCount];
    [self populateFrameDelay];
}

#pragma Preferences

//formatting is handled in nib because I cant figure out how to attach it programmatically
- (IBAction)frameCountDidChange:(NSTextField*)sender {
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:(int)[sender integerValue]] forKey:@"memoryio-gif-frame-count"];
}

//formatting is handled in nib because I cant figure out how to attach it programmatically
- (IBAction)frameDelayDidChange:(NSTextField*)sender {
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithFloat:[sender floatValue]] forKey:@"memoryio-gif-frame-delay"];
}

//formatting is handled in nib because I cant figure out how to attach it programmatically
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
