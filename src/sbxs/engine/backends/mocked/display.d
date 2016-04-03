/**
 * Mocked back end: Display subsystem.
 *
 * License: MIT License, see the `LICENSE` file.
 *
 * Authors: Leandro Motta Barros.
 */

module sbxs.engine.backends.mocked.display;

import sbxs.engine.backend;
import sbxs.engine.display;

/**
 * Mocked implementation of a Display.
 *
 * Note: Displays have reference semantics, despite being implemented as
 *     `struct`s! You must create all your Displays through the Display
 *     subsystem, which owns all Displays and is responsible for their
 *     destruction.
 */
public struct MockedDisplay
{
    /**
     * Constructs the `MockedDisplay`.
     *
     * Parameters:
     *     params = The parameters specifying how the Display shall be like.
     */
    package(sbxs.engine) this(DisplayParams params)
    {
        _handle = _nextDisplayHandle++;
        _isInited = true;
    }

    /// Destroys the Display.
    package(sbxs.engine) void destroy() nothrow @nogc
    {
        _isInited = false;
    }

    /// The Display width, in pixels.
    public @property int width() nothrow @nogc
    {
        return 0; // xxxxxxxxxxxxxxxxxxxxxxxx
    }

    /// The Display height, in pixels.
    public @property int height() nothrow @nogc
    {
        return 0; // xxxxxxxxxxxxxxxxxxxx
    }

    /// The Display title.
    public @property string title() nothrow @nogc const
    {
        return _title;
    }

    /// Make this Display the current target for rendering.
    public void makeCurrent() nothrow @nogc
    {
        _currentDisplay = _handle;
    }

    /// Swap buffers, show stuff. // xxxxxxxxxxxxxxxxxxxxxx pretend to
    public void swapBuffers() nothrow @nogc
    {
        // xxxxxxxxxxxxxxxxxxxxxxxxxxxxx
    }

    /// A handle that uniquely identifies this Display.
    public @property handleType handle() nothrow @nogc
    {
        return _handle;
    }

    /// Is this Display initialized and ready-to-use?
    public @property bool isInited() const nothrow @nogc { return _isInited; }

    /// Ditto
    private bool _isInited = false;

    /// A type for a handle that uniquely identifies a Display.
    public alias handleType = size_t;

    /// The Display currently active. `0` if no Display was created yet.
    private static handleType _currentDisplay = 0;

    /// The handle representing the Display.
    private handleType _handle;

    /// The Display title.
    private string _title;

    /// The handle for the next Display created.
    private static _nextDisplayHandle = 1;
}


/**
 * Mocked Display engine subsystem back end.
 *
 * Parameters:
 *     E = The type of the engine using this subsystem back end.
 */
package struct MockedDisplaySubsystem(E)
{
    /// The Engine using this subsystem back end.
    private E* _engine;

    /**
     * Initializes the subsystem.
     *
     * Parameters:
     *     engine = The engine using this subsystem.
     */
    public void initialize(E* engine)
    in
    {
        assert(engine !is null);
    }
    body
    {
        _engine = engine;
    }

    /// Shuts the subsystem down.
    public void shutdown() nothrow @nogc { }

    /// The type used as Display.
    public alias Display = MockedDisplay;
}
