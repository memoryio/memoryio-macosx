
#import "PhotoPreferencesViewController.h"

@implementation PhotoPreferencesViewController

@synthesize warmupDelayText;

- (id)init
{
    return [super initWithNibName:@"PhotoPreferencesView" bundle:nil];
}

-(void)loadView
{
    [super loadView];
    [self populateWarmupDelay];
}


- (void) populateWarmupDelay{
    
    NSNumber *warmupDelay = [[NSUserDefaults standardUserDefaults] objectForKey:@"memoryio-warmup-delay"];
    [warmupDelayText setFloatValue:warmupDelay.floatValue];
}

//formatting is handled in nib because I cant figure out how to attach it programmatically
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
