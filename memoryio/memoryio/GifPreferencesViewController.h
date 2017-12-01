//
// This is a sample Gif preference pane
//

#import <MASPreferences/MASPreferences.h>

@interface GifPreferencesViewController : NSViewController <MASPreferencesViewController>

@property (weak) IBOutlet NSTextField *frameCountText;
@property (weak) IBOutlet NSTextField *frameDelayText;
@property (weak) IBOutlet NSTextField *loopCountText;

@end
