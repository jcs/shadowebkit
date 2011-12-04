#include <stdio.h>
#include <strings.h>
#include <unistd.h>

#include <Cocoa/Cocoa.h>

#include "X11Window.h"
#include "WKWindow.h"

__dead void usage(void);
int debug = 0;

int main(int argc, char* argv[])
{
	int ch;

	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[NSApplication sharedApplication];

	while ((ch = getopt(argc, argv, "d")) != -1)
		switch (ch) {
		case 'd':
			debug = 1;
			break;
		default:
			usage();
		}
	argc -= optind;
	argv += optind;

	/* handle webkit window in the main thread (webkit won't allow use in
	 * another thread anyway) */
	WKWindow *WKW = [WKWindow alloc];
	[WKW init];

	/* bring up the X11 window in its own thread */
	X11Window *X = [X11Window alloc];
	[X init];
	[X performSelectorInBackground:@selector(mainLoopWithWKWindow:)
			withObject:WKW];

	/* if we have a remaining arg, load it as the url */
	if (argc)
		[WKW loadURL:[NSString stringWithFormat:@"%s", argv[0]]];

	[NSApp run];

	[pool release];
	return (0);
}

__dead void
usage(void)
{
	extern char *__progname;

	fprintf(stderr, "usage: %s [-d] url\n", __progname);
	exit(1);
}
