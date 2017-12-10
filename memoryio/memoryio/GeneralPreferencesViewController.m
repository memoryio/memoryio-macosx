
#import "GeneralPreferencesViewController.h"
#import "ServiceManagement/SMLoginItem.h"

@implementation GeneralPreferencesViewController


NSButton *startupButton;
NSPopUpButton *locationPull;
NSPopUpButton *modePull;
NSTextField *photoDelayText;

// not actually using these atm, but defining them to make mapping clear
typedef enum : NSUInteger
{
    Default = 0, Other, User
} LocationValue;

typedef enum : NSUInteger
{
    Photo = 0, Gif
} ModeValue;



- (NSView*)makeView
{
    NSView *view = [[NSView alloc] initWithFrame:NSMakeRect(0,0,388,231)];

    NSNumberFormatter *dec = [[NSNumberFormatter alloc] init];
    [dec setNumberStyle:NSNumberFormatterDecimalStyle];
    [dec setMaximumFractionDigits:1];
    [dec setMinimumFractionDigits:1];

    NSTextField *locationPullLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(18,166,96,17)];
    [locationPullLabel setStringValue:@"Save Location"];
    [locationPullLabel setBezeled:NO];
    [locationPullLabel setDrawsBackground:NO];
    [locationPullLabel setEditable:NO];
    [locationPullLabel setSelectable:NO];
    [view addSubview:locationPullLabel];

    locationPull = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(165,161,174,26)];
    [locationPull setBezelStyle:NSRoundedBezelStyle];
    [locationPull setAction:@selector(setLocation:)];
    [locationPull setTarget:self];
    [view addSubview:locationPull];

    NSTextField *modePullLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(18,125,130,17)];
    [modePullLabel setStringValue:@"Action at lockscreen"];
    [modePullLabel setBezeled:NO];
    [modePullLabel setDrawsBackground:NO];
    [modePullLabel setEditable:NO];
    [modePullLabel setSelectable:NO];
    [view addSubview:modePullLabel];

    modePull = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(165,120,73,26)];
    [modePull setBezelStyle:NSRoundedBezelStyle];
    [modePull setAction:@selector(setMode:)];
    [modePull setTarget:self];
    [view addSubview:modePull];

    NSTextField *photoDelayTextLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(18,81,120,17)];
    [photoDelayTextLabel setStringValue:@"Delay after Startup"];
    [photoDelayTextLabel setBezeled:NO];
    [photoDelayTextLabel setDrawsBackground:NO];
    [photoDelayTextLabel setEditable:NO];
    [photoDelayTextLabel setSelectable:NO];
    [view addSubview:photoDelayTextLabel];

    photoDelayText = [[NSTextField alloc] initWithFrame:NSMakeRect(165,78,54,22)];
    [photoDelayText setAction:@selector(photoDidChange:)];
    [photoDelayText setTarget:self];
    [photoDelayText becomeFirstResponder];
    [photoDelayText setFormatter:dec];
    [view addSubview:photoDelayText];

    startupButton = [[NSButton alloc] initWithFrame:NSMakeRect(165,44,112,18)];
    startupButton.title = @"Run at Startup";
    [startupButton setButtonType:NSSwitchButton];
    [startupButton setAction:@selector(startupAction:)];
    [startupButton setTarget:self];
    [view addSubview:startupButton];

    return view;
}

-(void)loadView
{
    self.view = [self makeView];
    
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


- (IBAction)photoDidChange:(NSTextField*)sender {
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithFloat:[sender floatValue]] forKey:@"memoryio-photo-delay"];
}

- (void) populateLocation{
    
    NSString *defaultPath = [NSString stringWithFormat:@"%@%@", NSHomeDirectory(), @"/Pictures/memoryIO/"];

    [locationPull removeAllItems];
    [locationPull addItemWithTitle:defaultPath];
    [locationPull addItemWithTitle:@"Other"];
    [locationPull selectItemAtIndex:0];
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
