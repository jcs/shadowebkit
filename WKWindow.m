#import "WKWindow.h"

#include <Cocoa/Cocoa.h>

@implementation WKWindow

- (id)init
{
	self = [super init];

	screen = [NSScreen mainScreen];
	screen_frame = [screen visibleFrame];

	NSRect coords = NSMakeRect(0, 0, 200, 200);
	window  = [[[NSWindow alloc] initWithContentRect:coords
				styleMask:NSBorderlessWindowMask
				backing:NSBackingStoreBuffered
				defer:NO
				screen:screen] autorelease];
	[window setBackgroundColor:[NSColor blueColor]];

	NSRect bframe = NSMakeRect(0, 0, 200, 200);
	browser = [[WebView alloc] initWithFrame:bframe
				frameName:nil
				groupName:nil];

	[window.contentView addSubview:browser];

	url = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 170, 200, 30)];
	[window.contentView addSubview:url];

	WebFrame *wframe = [browser mainFrame];
	[wframe loadRequest:[NSURLRequest requestWithURL:[NSURL
		URLWithString:@"https://www.duckduckgo.com/"]]];

	[window makeKeyAndOrderFront:window];

	return self;
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

	[url setFrame:NSMakeRect(0, height - 25, width, 25)];

	/* browser's coordinates are relative to the window */
	[browser setFrame:NSMakeRect(0, 0, width, height - 30)];

	[self focus];
}

- (void)focus
{
	[window makeKeyAndOrderFront:window];
	[window setOrderedIndex:0];
}

@end
