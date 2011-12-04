#include <stdio.h>
#include <strings.h>

#include <Cocoa/Cocoa.h>

#include "X11Window.h"
#include "WKWindow.h"

int main(int argc, char* argv[])
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[NSApplication sharedApplication];

	/* handle webkit window in the main thread (webkit won't allow use in
	 * another thread anyway) */
	WKWindow *WKW = [WKWindow alloc];
	[WKW init];

	/* bring up the X11 window in its own thread */
	X11Window *X = [X11Window alloc];
	[X init];
	[X performSelectorInBackground:@selector(mainLoopWithWKWindow:)
			withObject:WKW];

	[NSApp run];

	[pool release];
	return (0);
}
