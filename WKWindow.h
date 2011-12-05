#import <Foundation/Foundation.h>
#import <WebKit/WebFrame.h>
#import <WebKit/WebView.h>

#import "WKWindow.h"
#import "X11Window.h"

@interface WKWindow : NSWindow
{
	X11Window *shadow;
	NSWindow *window;
	NSScreen *screen;
	NSRect screen_frame;
	NSTextField *urlField;
	WebView *browser;
	WebFrame *wframe;
}

- (void)setPosition: (NSArray *)aCoords;
- (void)setShadow: (X11Window *)input;
- (void)loadURL: (NSString *)url;
- (void)loadURLFromTextField;
- (void)updateProgress;

@end
