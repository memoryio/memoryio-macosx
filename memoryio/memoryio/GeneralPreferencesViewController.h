//
// This is a sample General preference pane
//

#import <MASPreferences/MASPreferences.h>

@interface GeneralPreferencesViewController : NSViewController <MASPreferencesViewController>

- (IBAction)startupAction:(id)sender;

@property IBOutlet NSButton *startupButton;
@property (weak) IBOutlet NSPopUpButton *locationPull;
@property (weak) IBOutlet NSPopUpButton *modePull;
@property (weak) IBOutlet NSTextField *photoDelayText;

@end
