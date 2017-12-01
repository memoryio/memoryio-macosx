
#import "GeneralPreferencesViewController.h"
#import "ServiceManagement/SMLoginItem.h"

@implementation GeneralPreferencesViewController

@synthesize startupButton;
@synthesize locationPull;
@synthesize modePull;
@synthesize photoDelayText;

// not actually using these atm, but defining them to make mapping clear
typedef enum : NSUInteger
{
    Default = 0, Other, User
} LocationValue;

typedef enum : NSUInteger
{
    Photo = 0, Gif
} ModeValue;


- (id)init
{
    return [super initWithNibName:@"GeneralPreferencesView" bundle:nil];
}

-(void)loadView
{
    [super loadView];
    
    bool launchAtLogin = [[NSUserDefaults standardUserDefaults] boolForKey:@"memoryio-launchatlogin"];
    if(launchAtLogin) {
        [startupButton setState:NSOnState];
    }else{
        [startupButton setState:NSOffState];
    }

    [self populateLocation];
    [self populateMode];
    [self populatePhotoDelay];
}


- (IBAction)startupAction:(id)sender
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    if ([sender state] == NSOnState){
        if (SMLoginItemSetEnabled ((__bridge CFStringRef)@"com.augmentous.LaunchAtLoginHelperApp", YES)) {
            [userDefaults setBool:YES forKey:@"memoryio-launchatlogin"];
        }
    }else{
        if (SMLoginItemSetEnabled ((__bridge CFStringRef)@"com.augmentous.LaunchAtLoginHelperApp", NO)) {
            [userDefaults setBool:NO forKey:@"memoryio-launchatlogin"];
        }
    }
}

- (IBAction)setLocation:(NSPopUpButton*)sender {
    
    NSString *defaultPath = [NSString stringWithFormat:@"%@%@", NSHomeDirectory(), @"/Pictures/memoryIO/"];

    if([sender indexOfSelectedItem] == 0){
        [[NSUserDefaults standardUserDefaults] setObject:defaultPath forKey:@"memoryio-location"];
    }
    else if([sender indexOfSelectedItem] == 1){
        NSOpenPanel *panel = [NSOpenPanel openPanel];
        [panel setCanChooseFiles:NO];
        [panel setCanChooseDirectories:YES];
        [panel setAllowsMultipleSelection:NO];
        
        NSInteger clicked = [panel runModal];
        
        if (clicked == NSFileHandlingPanelOKButton) {
            NSString *path = [NSString stringWithFormat:@"%@%@", [panel URL].path, @"/"];
            [[NSUserDefaults standardUserDefaults] setObject:path forKey:@"memoryio-location"];
        }
    }
    [self populateLocation];
}

- (IBAction)setMode:(NSPopUpButton*)sender {
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInteger:[sender indexOfSelectedItem]] forKey:@"memoryio-mode"];
}


//formatting is handled in nib because I cant figure out how to attach it programmatically
- (IBAction)photoDidChange:(NSTextField*)sender {
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithFloat:[sender floatValue]] forKey:@"memoryio-photo-delay"];
}

- (void) populateLocation{
    
    NSString *defaultPath = [NSString stringWithFormat:@"%@%@", NSHomeDirectory(), @"/Pictures/memoryIO/"];

    [locationPull removeAllItems];
    [locationPull addItemWithTitle:defaultPath];
    [locationPull addItemWithTitle:@"Other"];
    
    NSString *location = [[NSUserDefaults standardUserDefaults] stringForKey:@"memoryio-location"];
    
    if([location isEqualToString:defaultPath]) {
        [locationPull selectItemAtIndex:0];
    }else{
        [locationPull addItemWithTitle:location];
        [locationPull selectItemAtIndex:2];
    }
}

- (void) populateMode{
    [modePull removeAllItems];
    [modePull addItemWithTitle:@"Photo"];
    [modePull addItemWithTitle:@"Gif"];
    
    NSNumber *mode = [[NSUserDefaults standardUserDefaults] objectForKey:@"memoryio-mode"];
    
    [modePull selectItemAtIndex:[mode intValue]];
}

- (void) populatePhotoDelay{
    
    NSNumber *photoDelay = [[NSUserDefaults standardUserDefaults] objectForKey:@"memoryio-photo-delay"];
    [photoDelayText setFloatValue:photoDelay.floatValue];
}


#pragma mark - MASPreferencesViewController

- (NSString *)viewIdentifier
{
    return @"GeneralPreferences";
}

- (NSImage *)toolbarItemImage
{
    return [NSImage imageNamed:NSImageNamePreferencesGeneral];
}

- (NSString *)toolbarItemLabel
{
    return NSLocalizedString(@"General", @"Toolbar item name for the General preference pane");
}

@end
