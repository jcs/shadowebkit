#include <X11/Xlib.h>
#include <X11/Xutil.h>

#include <err.h>
#include <stdlib.h>
#include <stdio.h>

#import "X11Window.h"
#import "WKWindow.h"

@implementation X11Window

- (id)init
{
	XTextProperty win_name_prop;
	char *win_name = "shadowebkit";

	self = [super init];

	display = XOpenDisplay(NULL);
	screen = DefaultScreen(display);

	window = XCreateSimpleWindow(
		display,
		RootWindow(display, screen),
		0, 0, 100, 100,
		0,
		BlackPixel(display, screen),
		BlackPixel(display, screen)
	);

	if (XStringListToTextProperty(&win_name, 1, &win_name_prop) == 0)
		errx(1, "XStringListToTextProperty");

	XSetWMName(display, window, &win_name_prop);

	XMapWindow(display, window);
	XSelectInput(display, window, ExposureMask);

	XFlush(display);
	XSync(display, False);

	return self;
}

- (void)mainLoopWithWKWindow: (id)wkwobj
{
	XEvent e;
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	wkw = wkwobj;

	for(;;) {
		XNextEvent(display, &e);
		XFlush(display);

		[self updateWKWindowPosition];
	}

	[pool release];
}

- (void)updateWKWindowPosition
{
	XWindowAttributes xwa;
	XGetWindowAttributes(display, window, &xwa);

	NSArray *pos = [[NSArray alloc] initWithObjects:
			[NSNumber numberWithInt:(xwa.x + xwa.border_width)],
			[NSNumber numberWithInt:(xwa.y + xwa.border_width)],
			[NSNumber numberWithInt:xwa.width],
			[NSNumber numberWithInt:xwa.height],
			nil];

	[wkw performSelectorOnMainThread:@selector(setPosition:)
		withObject:pos
		waitUntilDone:false];
}

@end
