#import <Foundation/Foundation.h>
#import <X11/Xlib.h>

@interface X11Window : NSObject
{
	Display *display;
	int screen;
	Window window;
	id wkw;
}

- (void)updateWKWindowPosition;
- (void)mainLoopWithWKWindow: (id)wkwobj;
- (void)setWindowTitle:(NSString *)title;
- (void)sendKeyFromXEvent:(XEvent)e;

@end
