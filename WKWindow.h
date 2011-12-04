#import <Foundation/Foundation.h>
#include <WebKit/WebFrame.h>
#include <WebKit/WebView.h>

@interface WKWindow : NSObject
{
	NSWindow *window;
	NSScreen *screen;
	NSRect screen_frame;
	NSTextField *url;
	WebView *browser;
}

- (void)setPosition: (NSArray *)aCoords;
- (void)focus;

@end
