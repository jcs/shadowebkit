#import <X11/Xlib.h>
#import <X11/Xutil.h>

#import <err.h>
#import <stdlib.h>
#import <stdio.h>

/* sorry for this */
#import <Carbon/../Frameworks/HIToolbox.framework/Headers/Events.h>

#import "X11Window.h"
#import "WKWindow.h"

extern int debug;

@implementation X11Window

- (id)init
{
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

	[self setWindowTitle:@"shadowebkit"];

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
			[self sendKeyFromXEvent:e];
		else
			[self updateWKWindowPosition];
	}

	[pool release];
}

- (void)setWindowTitle:(NSString *)title
{
	XTextProperty winNameProp;
	const char *winName = [title UTF8String];

	if (XStringListToTextProperty(&winName, 1, &winNameProp) == 0)
		errx(1, "XStringListToTextProperty");

	XSetWMName(display, window, &winNameProp);
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

/* translate an x11 key event into an equivalent keycode or string and send
 * the NSEvent to the app, which will handle sending it to webkit or the url
 * bar */
- (void)sendKeyFromXEvent:(XEvent)e
{
	char str[256+1];
	char strNoMod[2] = { '\0' };
	char *ksname;
	KeySym ks;
	int keycode = 0;
	int repeating = 0;
	int modifier = 0;

	XLookupString(&e.xkey, str, 256, &ks, NULL);

	/* X11 keysyms in /usr/X11/include/X11/keysymdef.h, carbon key codes
	 * in /System/Library/Frameworks/Carbon.framework/Frameworks/HIToolbox.framework/Headers/Events.h */

	switch (ks) {
	case XK_Control_L: keycode = kVK_Control; break;
	case XK_Control_R: keycode = kVK_RightControl; break;
	case XK_Delete: keycode = kVK_ForwardDelete; break;
	case XK_Down: keycode = kVK_DownArrow; break;
	case XK_End: keycode = kVK_End; break;
	case XK_Escape: keycode = kVK_Escape; break;
	case XK_Home: keycode = kVK_Home; break;
	case XK_Left: keycode = kVK_LeftArrow; break;
	case XK_Meta_L: keycode = kVK_Command; break;
	case XK_Meta_R: keycode = kVK_Command; break;
	case XK_Mode_switch: keycode = kVK_Option; break;
	case XK_Next: keycode = kVK_PageDown; break;
	case XK_Prior: keycode = kVK_PageUp; break;
	case XK_Return: keycode = kVK_Return; break;
	case XK_Right: keycode = kVK_RightArrow; break;
	case XK_Shift_L: keycode = kVK_Shift; break;
	case XK_Tab: keycode = kVK_Tab; break;
	case XK_Up: keycode = kVK_UpArrow; break;

	default:
		/* translate keys that don't have XK_* equivalents */

		if (!(ksname = XKeysymToString(ks)))
			ksname = "no name";

		if (!strcasecmp(ksname, "backspace")) {
			keycode = kVK_Delete;
			break;
		}
		else if (!strcasecmp(ksname, "space")) {
			keycode = kVK_Space;
			break;
		}
		else if (strlen(ksname) == 1) {
			strlcpy(str, ksname, sizeof(str));
			strlcpy(strNoMod, ksname, sizeof(strNoMod));
		}
		else if (strlen(ksname) > 1 && debug)
			/* probably a named key */
			printf("should probably translate \"%s\"\n", ksname);

		/* otherwise, assume it's just an ascii letter or number we
		 * can pass through as 'characters' param and a 0 keyCode */
		if (debug)
			printf("key %s 0x%x (X11 \"%s\") -> key \"%s\"\n",
				(e.type == KeyPress ? "press" : "release"),
				e.xkey.keycode,
				ksname,
				str);
	}

	/* if we are looking at a keyrelease event and there's a pending
	 * keypress event with the same timestamp, we're holding a key down */
	if (e.type == KeyRelease && XEventsQueued(display,
	    QueuedAfterReading)) {
		XEvent nev;
		XPeekEvent(display, &nev);

		if (nev.type == KeyPress && nev.xkey.time == e.xkey.time &&
		nev.xkey.keycode == e.xkey.keycode)
			repeating = 1;
	}

	if (e.xkey.state) {
		if (e.xkey.state & ShiftMask)
			modifier |= NSShiftKeyMask;
		if (e.xkey.state & LockMask)
			modifier |= NSAlphaShiftKeyMask;
		if (e.xkey.state & ControlMask)
			modifier |= NSControlKeyMask;
		if (e.xkey.state & Mod2Mask)
			modifier |= NSCommandKeyMask;
		if (e.xkey.state & 0x2000)
			modifier |= NSAlternateKeyMask;

		/* TODO: what do mod1, mod3, mod4, and mod5 map to? */
	}

	NSEvent *fakeEvent = [NSEvent
		keyEventWithType:(e.type == KeyPress ? NSKeyDown : NSKeyUp)
		location:[NSEvent mouseLocation]
		modifierFlags:modifier
		timestamp:0
		windowNumber:[[NSApp mainWindow] windowNumber]
		context:nil
		characters:[NSString stringWithFormat:@"%s", str]
		charactersIgnoringModifiers:[NSString stringWithFormat:@"%s", strNoMod]
		isARepeat:(BOOL)repeating
		keyCode:keycode];

	if (debug)
		NSLog(@"%@", fakeEvent);

	[NSApp postEvent:fakeEvent atStart:NO];
}

@end
