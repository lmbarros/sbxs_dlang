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
     * Are `displayExpose` events wanted?
     *
     * Certain back ends (Allegro 5, for example) will not generate
     * `displayExpose` events unless this is set to `true`. However, leaving
     * this as `false` does not guaranteed that these events will not be
     * generated. The bottom line is: if you need `displayExpose` events, set
     * this to `true`; otherwise, just ignore these events.
     */
    bool wantsExposeEvents = false;

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
 * Implementation of the Display engine subsystem.
 *
 * This provides places where we can draw things to.
 *
 * Parameters:
 *     E = The type of the engine being used.
 */
package struct DisplaySubsystem(E)
{
    /// The engine being used.
    private E* _engine;

    /// The type representing a Display, as defined in the back end.
    public alias Display = E.backendType.display.Display;

    /**
     * Initializes the subsystem.
     *
     * Parameters:
     *     engine = The engine being used.
     */
    package void initialize(E* engine)
    in
    {
        assert(engine !is null);
    }
    body
    {
        _engine = engine;
    }

    /// Shuts the subsystem down.
    package void shutdown()
    {
        foreach (ref display; _displaysByHandle)
            display.destroy();
    }

    /**
     * Creates a Display and returns it.
     *
     * Parameters:
     *     params = The parameters describing the desired Display
     *         characteristics.
     */
    public Display create(DisplayParams params)
    {
        auto newDisplay = Display(params);
        _displaysByHandle[newDisplay.handle] = newDisplay;
        return newDisplay;
    }

    /**
     * Returns the Display corresponding to a given display handle.
     *
     * Return will be `null` if an invalid ID is passed. (This may happen in
     * not-so-obvious cases, like when a previously existing Display is
     * destroyed.)
     */
    public inout(Display*) displayFromHandle(Display.handleType handle) inout
    {
        auto pDisplay = handle in _displaysByHandle;
        if (pDisplay is null)
            return null;
        else
            return pDisplay;
    }

    /// Swap the buffers of all Displays.
    package void swapAllBuffers()
    {
        foreach (ref display; _displaysByHandle)
            display.swapBuffers();
    }

    /// The Displays managed by this back end, indexed by their handles.
    private Display[Display.handleType] _displaysByHandle;

}
