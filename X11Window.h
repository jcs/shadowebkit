#import <Foundation/Foundation.h>
#include <X11/Xlib.h>

@interface X11Window : NSObject
{
	Display *display;
	int screen;
	Window window;
	id wkw;
}

- (void)updateWKWindowPosition;
- (void)mainLoopWithWKWindow: (id)wkwobj;

@end
