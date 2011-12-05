## shadowebkit
by joshua stein <jcs@jcs.org>


### about
this is an experiment in making a simple cocoa webkit-based browser that behaves like a normal X11 window and can be managed by a tiling X11 window manager under OS X.

while it is possible to build webkit's gtk port on OS X and use existing minimalistic browsers like vimprobable or xxxterm, webkit-gtk's dependencies are quite numerous and font issues may cause rendering problems.  shadowebkit uses the high-performance cocoa-based webkit framework already included on OS X.


### building
type 'xcodebuild' and then run 'build/Release/shadowebkit'.


### implementation
for a cocoa-based application to be able to be managed by an X11 window manager, an X11 window must be present in the X11 space and the window in the cocoa space cannot be a normal application.  a normal cocoa application would present itself as a separate application from X11.app, taking away keyboard focus from the window manager.  this means that to resize or move it, X11.app must be manually re-focused with cmd+tab every time.

shadowebkit starts by creating a simple X11 window that the tiling window manager manages and adjusts the size of.  a cocoa window is also drawn without any decorations, which contains the webkit frame and a url bar.

the X11 window listens for X11 events notifying it that its size or position has changed or that it has gained focus, and then moves the cocoa window to those same coordinates.  this way the X11 window is never really visible, but remains as a "shadow" to the cocoa window.

while the cocoa window can receive mouse inputs, it is never actually focused by OS X's window server, so it does not receive keyboard input properly.  keyboard events are received under X11.app by the X11 window of shadowebkit, which then converts key events into NSEvents to send back to the cocoa window.

shadowebkit is multithreaded, managing the webkit cocoa window in its main thread and the X11 runloop in another.  this lets each respond to events in its own environment like window positioning or mouse movements.  when the webkit window loads a new page and changes its title, the X11 window's title is updated to be visible to the window manager.


### problems
due to the keyboard proxying that is necessary due to the cocoa window never being focused, the normal command+c/v keys do not work since they are captured by the currently-focused cocoa app, which is X11.app.  shadowebkit's X11 window does not see them, so it cannot proxy them over to the cocoa window.

since the keycode conversion is done manually, not all keys are currently proxied over properly such as special characters typed with the option key.

also because of the focus issues, mouse cursor changes are not done properly, so hovering over links does not change the cursor to a pointer, for example.  the browser will mostly be controlled through keyboard shortcuts anyway, so this is not a major concern.


### todo
the browser is currently just a basic shell; a webkit frame and a url bar that are tied together.  typing a url and pressing return will load it, and when the url changes, the url bar is updated.

the cocoa interface should be expanded to include small stop/reload/back buttons, a status bar, and a progress indicator.

keyboard shortcuts should be added to focus the url bar, search, etc.

### screenshot
this is ratpoison under X11.app, with shadowebkit running in the upper right frame.

[http://i.imgur.com/cGihpl.png](http://i.imgur.com/cGihp.png)
