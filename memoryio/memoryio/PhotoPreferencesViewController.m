
#import "PhotoPreferencesViewController.h"

@implementation PhotoPreferencesViewController

NSTextField *warmupDelayText;

- (NSView*)makeView
{
    NSView *view = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 388, 231)];

    NSNumberFormatter *dec = [[NSNumberFormatter alloc] init];
    [dec setNumberStyle:NSNumberFormatterDecimalStyle];
    [dec setMaximumFractionDigits:1];
    [dec setMinimumFractionDigits:1];

    NSTextField *warmupDelayTextLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(81,108,146,17)];
    [warmupDelayTextLabel setStringValue:@"Camera Warmup Delay"];
    [warmupDelayTextLabel setBezeled:NO];
    [warmupDelayTextLabel setDrawsBackground:NO];
    [warmupDelayTextLabel setEditable:NO];
    [warmupDelayTextLabel setSelectable:NO];
    [view addSubview:warmupDelayTextLabel];

    warmupDelayText = [[NSTextField alloc] initWithFrame:NSMakeRect(252,105,54,22)];
    [warmupDelayText setAction:@selector(warmupDidChange:)];
    [warmupDelayText setTarget:self];
    [warmupDelayText becomeFirstResponder];
    [warmupDelayText setFormatter:dec];
    [view addSubview:warmupDelayText];
    return view;
}

-(void)loadView
{
    self.view = [self makeView];
    [self populateWarmupDelay];
}


- (void) populateWarmupDelay{
    
    NSNumber *warmupDelay = [[NSUserDefaults standardUserDefaults] objectForKey:@"memoryio-warmup-delay"];
    [warmupDelayText setFloatValue:warmupDelay.floatValue];
}

- (IBAction)warmupDidChange:(NSTextField*)sender {
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithFloat:[sender floatValue]] forKey:@"memoryio-warmup-delay"];
}




#pragma mark - MASPreferencesViewController

- (NSString *)viewIdentifier
{
    return @"PhotoPreferences";
}

- (NSImage *)toolbarItemImage
{
    return [NSImage imageNamed:NSImageNamePreferencesGeneral];
}

- (NSString *)toolbarItemLabel
{
    return NSLocalizedString(@"Photo", @"Toolbar item name for the General preference pane");
}


@end
