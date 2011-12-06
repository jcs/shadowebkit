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

	currentURL = [[NSURL alloc] init];

	NSRect bframe = NSMakeRect(0, 0, 300, 300);
	browser = [[WebView alloc] initWithFrame:bframe
				frameName:nil
				groupName:nil];
	[browser setGroupName:@"shadowebkit"];
	[browser setUIDelegate:self];
	[browser setResourceLoadDelegate:self];
	[browser setFrameLoadDelegate:self];
	[window.contentView addSubview:browser];

	urlField = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 0, 0)];
	[urlField setTarget:self];
	[urlField setAction:@selector(loadURLFromTextField)];
	[window.contentView addSubview:urlField];

	statusBar = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 0, 0)];
	[statusBar setTarget:self];
	[statusBar setEditable:false];
	[statusBar setSelectable:false];
	[statusBar setBordered:false];
	[statusBar setTextColor:[NSColor lightGrayColor]];
	[statusBar setBackgroundColor:[NSColor blackColor]];
	[self setStatus:@""];
	[window.contentView addSubview:statusBar];

	wframe = [browser mainFrame];

	[window makeKeyAndOrderFront:window];

	return self;
}

/* return key pressed on urlField */
- (void)loadURLFromTextField
{
	[self loadURL:[urlField stringValue]];
}

- (void)loadURL:(NSString *)url
{
	NSURL *u = [NSURL URLWithString:url];

	if ([[u scheme] length] == 0)
		u = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@",
			url]];

	[wframe loadRequest:[NSURLRequest requestWithURL:u]];
}

- (void)setPosition:(NSArray *)aCoords
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
	[browser setFrame:NSMakeRect(0, 17, width, height - 17 - 24)];

	[statusBar setFrame:NSMakeRect(0, 0, width, 17)];

	[window makeKeyAndOrderFront:window];
}

- (void)setShadow: (X11Window *)input
{
	[shadow autorelease];
	shadow = [input retain];
}

- (void)setStatus:(NSString *)text
{
	[statusBar setStringValue:text];
}

- (void)setStatusToResourceCounts
{
	if (resourceCompletedCount + resourceFailedCount >= resourceCount)
		[self setStatus:@""];
	else
		[self setStatus:[NSString
			stringWithFormat:@"Loading \"%@\", completed %d of %d item%s",
			[currentURL absoluteString], resourceCompletedCount,
			resourceCount, (resourceCount == 1 ? "" : "s")]];
}

- (void)setTitle:(NSString *)text
{
	[shadow setWindowTitle:text];
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


/* WebFrameLoadDelegate glue */

- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame
{
	if (frame != [sender mainFrame])
		return;

	[self setStatus:@""];
}

- (void)webView:(WebView *)sender didReceiveTitle:(NSString *)title forFrame:(WebFrame *)frame
{
	if (frame != [sender mainFrame])
		return;

	[self setTitle:title];
}

- (void)webView:(WebView *)sender didStartProvisionalLoadForFrame:(WebFrame *)frame
{
	if (frame != [sender mainFrame])
		return;

	currentURL = [[NSURL URLWithString:[[[[frame provisionalDataSource]
		request] URL] absoluteString]] retain];

	resourceCount = 0;    
	resourceCompletedCount = 0;
	resourceFailedCount = 0;

	[urlField setStringValue:[currentURL absoluteString]];
	[self setStatus:[NSString stringWithFormat:@"Loading \"%@\"...",
		[currentURL absoluteString]]];
}


/* WebResourceLoadDelegate glue */

- (id)webView:(WebView *)sender identifierForInitialRequest:(NSURLRequest *)request fromDataSource:(WebDataSource *)dataSource
{
	return [NSNumber numberWithInt:resourceCount++];
}

- (NSURLRequest *)webView:(WebView *)sender resource:(id)identifier willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponsefromDataSource:(WebDataSource *)dataSource
{
	/* TODO: implement an ad blocker here? */
	[self setStatusToResourceCounts];
	return request;
}

- (void)webView:(WebView *)sender resource:(id)identifier didFailLoadingWithError:(NSError *)error fromDataSource:(WebDataSource *)dataSource
{
	resourceFailedCount++;
	[self setStatusToResourceCounts];
}

- (void)webView:(WebView *)sender resource:(id)identifier didFinishLoadingFromDataSource:(WebDataSource *)dataSource
{
	resourceCompletedCount++;
	[self setStatusToResourceCounts];
}

/* WebUIDelegate glue */


@end
