#import <Foundation/Foundation.h>
#import <WebKit/WebFrame.h>
#import <WebKit/WebView.h>

#import "X11Window.h"

/* sorry for this */
#import <Carbon/../Frameworks/HIToolbox.framework/Headers/Events.h>

@interface WKWindow : NSWindow
{
	X11Window *shadow;
	NSWindow *window;
	NSScreen *screen;
	NSRect screen_frame;
	NSTextField *urlField;
	NSTextField *statusBar;
	WebView *browser;
	WebFrame *wframe;

	NSURL *currentURL;

	int resourceCount;
	int resourceCompletedCount;
	int resourceFailedCount;

	int sheetResponse;
}

- (void)setPosition:(NSArray *)aCoords;
- (void)setShadow:(X11Window *)input;
- (void)setStatus:(NSString *)text;
- (void)setStatusToResourceCounts;
- (void)setTitle:(NSString *)text;
- (void)loadURL:(NSString *)url;
- (void)loadURLFromTextField;

- (void)handleSheetResponse:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;

@end
