/**
 * Definitions related with Displays, which are places where things can be
 * displayed.
 *
 * Display themselves are defined by the back ends. Here we have only the
 * generic, hopefully portable interfaces.
 *
 * License: MIT License, see the `LICENSE` file.
 *
 * Authors: Leandro Motta Barros.
 */

module sbxs.engine.display;

import std.traits;



/**
 * Modes into which a Display can be created, with regards to "window" versus
 * "full screen".
 */
public enum WindowingMode
{
    /// The Display is created as a floating window.
    windowed,

    /**
     * The Display is created in (real) full screen mode. This usually implies
     * in changing the desktop resolution and things like this.
     */
    fullScreen,

    /**
     * The Display is created in fake full screen style. This means that it is
     * actually just a window without decorations, in the same size as the
     * desktop.
     */
    fakeFullScreen,
}


/**
 * A set of configurations that define how a Display is to be created like.
 *
 * Each back end may has some freedom on how to exactly implement each of these
 * settings, and even which ones to support. Also, there are some interactions
 * between these settings, which I'll not document here (one example: `width`
 * and `height` are ignored for a Display created as
 * `WindowingMode.fakeFullScreen`.).
 */

public struct DisplayParams
{
    /// Create as window, in full screen, or something else?
    WindowingMode windowingMode = WindowingMode.windowed;

    /// Display width, in pixels.
    int width = 1024;

    /// Display height, in pixels.
    int height = 768;

    /// Display minimum width, in pixels.
    int minWidth = 640;

    /// Display minimum height, in pixels.
    int minHeight = 480;

    /// Display maximum width, in pixels.
    int maxWidth = int.max;

    /// Display maximum height, in pixels.
    int maxHeight = int.max;

    /// The display title (usually used as window caption).
    string title = "SBXS Display";

    /// Use window decorations (borders, close button, etc)?
    bool decorations = true;

    /// Is the Display resizable?
    bool resizable = true;

    /**
     * The desired version for the underlying graphics API. I created this so
     * that I could specify a certain OpenGL version when creating my Displays.
     * I assume that other graphics APIs (like Direct3D) can use these same
     * attributes in a similar fashion.
     */
    int graphicsAPIMajorVersion = 3;

    /// Ditto
    int graphicsAPIMinorVersion = 3;

    /// Ditto
    int graphicsAPIPatchVersion = 0;
}


/**
 * Checks if something is a Display.
 *
 * A Display is a place where things can be displayed. It can be either
 * a window or "a full screen". I try to not assume anything regarding
 * what rendering APIs are supported and used under the hood. However,
 * given my background knowledge and my interest in cross-platform
 * development, I will probably use OpenGL in all my concrete back end
 * implementations.
 */
public enum isDisplay(T) =
    // Must be implemented as a struct.
    is (T == struct)

    // Must provide a handle that uniquely identifies them. This shall
    // be a lightweight cheaply copyable type.
    && hasMember!(T, "handle")
    && hasMember!(T, "handle_t")
    && is (T.handle_t)
    && is (typeof(T.handle) == T.handle_t)

    // Must provide ways to access their width and height, in pixels.
    && hasMember!(T, "width")
    && is (typeof(T.width) : int)
    && hasMember!(T, "height")
    && is (typeof(T.height) : int)

    // Displays must provide a `makeCurrent()` method, used to set them
    // as the target for subsequent rendering.
    && __traits(compiles, T.init.makeCurrent())

    // Displays must provide a `swapBuffers()` method, used to, well,
    // swap buffers. This implies that double buffering is expected, but
    // an implemention could just implement this as a no-op (and just
    // pretend to be double buffered).
    && __traits(compiles, T.init.swapBuffers())
;


/**
 * Implementation of the Display engine subsystem. This is a `mixin template`
 * just to allow me to easily (should I say "lazily"?) split the engine
 * implementation in multiple files.
 */
mixin template DisplaySubsystem(BE)
{
    /// Handy alias to the Display type defined by the back end.
    private alias Display = _backend.display.Display;

    /// Creates and returns a Display.
    public Display* createDisplay(DisplayParams dp)
    {
        _backend.display.createDisplay(dp, _displays);
        return &_displays.back();
    }

    /// Swap the buffers of all Displays.
    private void swapAllBuffers()
    {
        foreach (ref display; _displays)
            display.swapBuffers();
    }

    /// The Displays managed by this back end.
    private NCArray!Display _displays;
}
