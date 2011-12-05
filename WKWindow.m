#import "WKWindow.h"
#import "X11Window.h"

#include <Cocoa/Cocoa.h>

@implementation WKWindow

- (id)init
{
	self = [super init];

	screen = [NSScreen mainScreen];
	screen_frame = [screen visibleFrame];

	NSRect coords = NSMakeRect(0, 0, 300, 300);
	window  = [[[WKWindow alloc] initWithContentRect:coords
				styleMask:NSBorderlessWindowMask
				backing:NSBackingStoreBuffered
				defer:NO
				screen:screen] autorelease];
	[window setBackgroundColor:[NSColor blackColor]];
	[window setAcceptsMouseMovedEvents:YES];

	NSRect bframe = NSMakeRect(0, 0, 300, 300);
	browser = [[WebView alloc] initWithFrame:bframe
				frameName:nil
				groupName:nil];

	/* setup callbacks to update the url and title */
	[[NSNotificationCenter defaultCenter] addObserver:self
					selector:@selector(updateProgress)
					name:WebViewProgressStartedNotification
					object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
					selector:@selector(updateProgress)
					name:WebViewProgressFinishedNotification
					object:nil];

	[window.contentView addSubview:browser];

	urlField = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 0, 0)];
	[urlField setTarget:self];
	[urlField setAction:@selector(loadURLFromTextField)];
	[window.contentView addSubview:urlField];

	wframe = [browser mainFrame];

	[window makeKeyAndOrderFront:window];

	return self;
}

/* return key pressed on urlField */
- (void)loadURLFromTextField
{
	[browser takeStringURLFrom:urlField];
}

- (void)loadURL: (NSString *)url
{
	[wframe loadRequest:
		[NSURLRequest requestWithURL:[NSURL URLWithString:url]]];
}

/* called while the page is loading, and then again when it finishes */
- (void)updateProgress
{
	[urlField setStringValue:[browser mainFrameURL]];
	[shadow setWindowTitle:[browser mainFrameTitle]];
}

- (void)setPosition: (NSArray *)aCoords
{
	int x = [[aCoords objectAtIndex:0] intValue];
	int y = [[aCoords objectAtIndex:1] intValue];
	int width = [[aCoords objectAtIndex:2] intValue];
	int height = [[aCoords objectAtIndex:3] intValue];

	/* convert normal coordinates into cocoa's upside-down
	 * 0,0-is-bottom-left */
	NSRect coords = NSMakeRect(
		x,
		(int)screen_frame.size.height - (int)screen_frame.origin.y -
			height - y,
		width,
		height
	);

	[window setFrame:coords display:true];

	[urlField setFrame:NSMakeRect(0, height - 23, width, 23)];

	/* browser's coordinates are relative to the window */
	[browser setFrame:NSMakeRect(0, 0, width, height - 24)];

	[window makeKeyAndOrderFront:window];
}

- (void)setShadow: (X11Window *)input
{
	[shadow autorelease];
	shadow = [input retain];
}

/* these are needed because setting styleMask to NSBorderlessWindowMask turns
 * them off */
- (BOOL)canBecomeKeyWindow
{
	return YES;
}

- (BOOL)canBecomeMainWindow
{
	return YES;
}

@end
