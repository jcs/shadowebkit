## shadowebkit
by joshua stein - http://jcs.org/


### About
This is an experiment in making a simple Cocoa WebKit-based browser that behaves like a normal X11 window and can be managed by a tiling X11 window manager under OS X.

While WebKit's GTK+ port will probably build on OS X to enable the use of existing minimalistic browsers like vimprobable or xxxterm, WebKitGTK's dependencies are quite numerous and font issues may cause rendering issues.  shadowebkit uses the high-performance Cocoa-based WebKit framework already included and maintained on OS X.


### Demo
This screenshot shows the ratpoison window manager under X11.app, with shadowebkit running in the upper right frame:

![http://i.imgur.com/cGihpl.png](http://i.imgur.com/cGihp.png)


### Building
Type `xcodebuild` and then run `build/Release/shadowebkit`.  A URL can be passed as an argument to navigate to it.


### Implementation
For a Cocoa-based application to be able to be managed by an X11 window manager, an X11 window must be present in the X11 space and the window in the Cocoa space cannot be a "normal" application.  A normal Cocoa application would present itself as separate from X11.app, taking away keyboard focus from the X11 window manager and requiring X11.app to be manually re-focused with cmd+tab every time, as well as being drawn with normal window controls and an imposing shadow.

shadowebkit starts by creating a simple X11 window that the tiling window manager manages and adjusts the size of.  A Cocoa window is then drawn on top of it without any decorations and contains the WebKit frame and a URL bar.

The X11 window listens for events notifying it that its size or position has changed or that it has gained focus, and then moves the Cocoa window to those same coordinates on the screen.  This way the X11 window is never really visible, but remains as a "shadow" under the Cocoa window.

While the Cocoa window can receive mouse inputs and clicking links and using dropdown boxes works, it is never actually focused by OS X's window server and does not receive keyboard input.  Keyboard events are received by the currently focused cocoa app (X11.app) which then sends them to the X11 window of shadowebkit, which then converts   XKeyEvent key events into NSEvents to send back to the Cocoa window.

shadowebkit is multithreaded, managing the WebKit Cocoa window in its main thread and the X11 runloop in another.  This lets each respond to events in its own environment like window positioning or mouse movements.  When the WebKit window loads a new page and changes its title, the X11 window's title is updated to make it visible to the window manager.


### Problems
Due to the keyboard proxying that is necessary for the focus issue, the normal command+c/v keys do not work since they are captured directly by X11.app.  shadowebkit's X11 window does not see them, so it cannot proxy them over to the cocoa window.

Since the keycode conversion is done manually, not all keys are currently proxied over properly such as special characters typed with the option key.

Also because of the focus issue (or maybe some other issue), mouse cursor changes are not done by WebKit so hovering over links does not change the cursor to a pointer, for example.  The browser will mostly be controlled through keyboard shortcuts anyway, so this is not of major concern.


### TODO
The browser is currently just a basic shell; a WebKit frame and a URL bar that are tied together.  Typing a URL and pressing return will load it, and when the WebKit frame's URL changes, the URL bar is updated.

The Cocoa interface should be expanded to include small stop/reload/back buttons, a status bar, and a progress indicator.

Keyboard shortcuts should be added to focus the URL bar, search, etc.

Implement tabs or something to deal with multiple windows.

Check how JavaScript popups and browser resizes affect shadowebkit.
