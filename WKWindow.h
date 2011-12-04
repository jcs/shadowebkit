#import <Foundation/Foundation.h>
#include <WebKit/WebFrame.h>
#include <WebKit/WebView.h>

@interface WKWindow : NSWindow
{
	NSWindow *window;
	NSScreen *screen;
	NSRect screen_frame;
	NSTextField *url;
	WebView *browser;
	WebFrame *wframe;
}

- (void)setPosition: (NSArray *)aCoords;
- (void)loadURL: (NSString *)url;

@end
