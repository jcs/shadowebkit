#include <X11/Xlib.h>
#include <X11/Xutil.h>

#include <err.h>
#include <stdlib.h>
#include <stdio.h>

/* sorry for this */
#import <Carbon/../Frameworks/HIToolbox.framework/Headers/Events.h>

#import "X11Window.h"
#import "WKWindow.h"

extern int debug;

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
	XSelectInput(display, window, KeyPressMask | KeyReleaseMask |
		ExposureMask | FocusChangeMask | StructureNotifyMask);

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
		XSync(display, False);

		if (e.type == KeyPress || e.type == KeyRelease)
			[self sendKeyFromXEvent:e.xkey];
		else
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
		waitUntilDone:true];
}

- (void)sendKeyFromXEvent:(XKeyEvent)e
{
	char str[257];
	char *ksname;
	KeySym ks;
	int keycode = 0;

	XLookupString(&e, str, 256, &ks, NULL);

	if (!(ksname = XKeysymToString(ks)))
		ksname = "no name";

	switch (ks) {
	case 0x20: keycode = kVK_Space; break;

	case XK_Control_L: keycode = kVK_Control; break;
	case XK_Control_R: keycode = kVK_RightControl; break;
	case XK_Delete: keycode = kVK_ForwardDelete; break;
	case XK_Down: keycode = kVK_DownArrow; break;
	case XK_End: keycode = kVK_End; break;
	case XK_Escape: keycode = kVK_Escape; break;
	case XK_Home: keycode = kVK_Home; break;
	case XK_Left: keycode = kVK_LeftArrow; break;
	case XK_Next: keycode = kVK_PageDown; break;
	case XK_Prior: keycode = kVK_PageUp; break;
	case XK_Return: keycode = kVK_Return; break;
	case XK_Right: keycode = kVK_RightArrow; break;
	case XK_Shift_L: keycode = kVK_Shift; break;
	case XK_Tab: keycode = kVK_Tab; break;
	case XK_Up: keycode = kVK_UpArrow; break;

	default:
		if (!strcasecmp(ksname, "backspace")) { keycode = kVK_Delete; break; }

		/* otherwise, assume it's just an ascii letter or number we
		 * can pass through as 'characters' param and a 0 keyCode */
	}

	if (debug)
		printf("key %s %d (X11 \"%s\") -> keycode %d %s\n",
			(e.type == KeyPress ? "press" : "release"),
			e.keycode,
			ksname,
			keycode,
			(keycode == 0 ? str : ""));

	NSEvent *fakeEvent = [NSEvent
		keyEventWithType:(e.type == KeyPress ? NSKeyDown : NSKeyUp)
		location:[NSEvent mouseLocation]
		modifierFlags:0
		timestamp:0
		windowNumber:[[NSApp mainWindow] windowNumber]
		context:nil
		characters:[NSString stringWithFormat:@"%s", str]
		charactersIgnoringModifiers:[NSString stringWithFormat:@"%s", str]
		isARepeat:NO
		keyCode:keycode];

	[NSApp postEvent:fakeEvent atStart:NO];
}

@end
