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

        // Set the Display parameters
        _title = params.title;
        _width = params.width;
        _height = params.height;

        // Make it the current one
        _currentDisplay = _handle;
    }

    /// Destroys the Display.
    package(sbxs.engine) void destroy() nothrow @nogc
    {
        _isInited = false;
    }

    /// The Display width, in pixels.
    public @property int width() nothrow @nogc
    {
        return _width;
    }

    /// Ditto
    private int _width = 0;

    /// The Display height, in pixels.
    public @property int height() nothrow @nogc
    {
        return _height;
    }

    /// Ditto
    private int _height = 0;

    /// Resizes the Display
    public void resize(E)(E* engine, int width, int height, handleType displayHandle)
    {
        import sbxs.engine.backends.mocked;

        // Update the internal state
        _width = width;
        _height = height;

        // Generate a resize event.
        static assert(is(typeof(engine._backend) == MockedBackend));
        auto event = engine._backend.events.makeDisplayResizeEvent(width, height, displayHandle);

        engine._backend.events.mockedEventQueue ~= event;
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

    /**
     * Pretends to swap buffers.
     *
     * In fact, just increments a counter telling that buffers were swapped.
     */
    public void swapBuffers() nothrow @nogc
    {
        ++_swapBuffersCount;
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

    /// Number of times buffers were swapped.
    public @property int swapBuffersCount() const nothrow @nogc { return _swapBuffersCount; }

    /// Ditto
    private int _swapBuffersCount = 0;

    /// A type for a handle that uniquely identifies a Display.
    public alias handleType = size_t;

    /// The Display currently active. `0` if no Display was created yet.
    public static handleType currentDisplay() { return _currentDisplay; }

    /// Ditto
    private static handleType _currentDisplay = 0;

    /// The handle representing the Display.
    private handleType _handle;

    /// The Display title.
    private string _title;

    /// The handle for the next Display created.
    private static int _nextDisplayHandle = 1;
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
        _isInited = true;
    }

    /// Shuts the subsystem down.
    public void shutdown() nothrow @nogc
    {
        MockedDisplay._currentDisplay = 0;
        MockedDisplay._nextDisplayHandle = 0;
        _isInited = false;
    }

    /// The type used as Display.
    public alias Display = MockedDisplay;

    /// Is the subsystem initialized and ready-to-use?
    public @property bool isInited() const nothrow @nogc { return _isInited; }

    /// Ditto
    private bool _isInited = false;
}



// -----------------------------------------------------------------------------
// Unit tests
// -----------------------------------------------------------------------------

// Test if the back end subsystem is properly initialized.
unittest
{
    import sbxs.engine.engine;
    import sbxs.engine.backends.mocked;

    Engine!MockedBackend engine;
    MockedDisplaySubsystem!(Engine!MockedBackend) display;

    // Initially, not initialized
    assert(!display.isInited);

    // Initialize
    display.initialize(&engine);
    assert(display.isInited);

    // Multiple initialization shouldn't be a problem
    display.initialize(&engine);
    assert(display.isInited);
    display.initialize(&engine);
    assert(display.isInited);

    // After shutdown, back end should no longer be considered intialized
    display.shutdown();
    assert(!display.isInited);
}


// Test Display creation.
unittest
{
    DisplayParams params;
    params.title = "My mocked display";
    params.width = 111;
    params.height = 222;

    auto display = MockedDisplay(params);

    // The Display shall be inited after construction
    assert(display.isInited);

    // Check the Display parameters
    assert(display.title == "My mocked display");
    assert(display.width == 111);
    assert(display.height == 222);

    // Destroy the Display; it should be no longer inited
    display.destroy();
    assert(!display.isInited);
}


// Test multiple Displays.
unittest
{
    // The current display shall be initially zero
    assert(MockedDisplay.currentDisplay == 0);

    // Create a Display, it shall become the current one
    DisplayParams params1;
    params1.title = "My first mocked display";
    auto display1 = MockedDisplay(params1);

    assert(MockedDisplay.currentDisplay == display1.handle);

    // Create a second Display, which shall become the current
    DisplayParams params2;
    params2.title = "My second mocked display";
    auto display2 = MockedDisplay(params2);

    assert(display1.handle != display2.handle);
    assert(MockedDisplay.currentDisplay == display2.handle);

    // Change the current Display manually
    display1.makeCurrent();
    assert(MockedDisplay.currentDisplay == display1.handle);
}


// Test swap buffers.
unittest
{
    DisplayParams params;
    auto display = MockedDisplay(params);

    // Initially, number of buffer swaps must me zero
    assert(display.swapBuffersCount == 0);

    // Swapping buffers shall increase the count
    display.swapBuffers();
    assert(display.swapBuffersCount == 1);

    display.swapBuffers();
    display.swapBuffers();
    display.swapBuffers();
    display.swapBuffers();
    assert(display.swapBuffersCount == 5);
}


// Test Display resize.
unittest
{
    import sbxs.engine.engine;
    import sbxs.engine.events;
    import sbxs.engine.backends.mocked;

    Engine!MockedBackend engine;
    engine.initialize();


    DisplayParams params;
    params.width = 1000;
    params.height = 500;
    auto display = MockedDisplay(params);

    // Check initial dimensions
    assert(display.width == 1000);
    assert(display.height == 500);

    // Also, be sure that the engine event queue is empty
    assert(engine._backend.events.mockedEventQueue.length == 0);

    // Resize; check if dimensions changed and event was enqueued
    display.resize(&engine, 411, 122, display.handle);

    assert(display.width == 411);
    assert(display.height == 122);

    assert(engine._backend.events.mockedEventQueue.length == 1);
    assert(engine._backend.events.mockedEventQueue[0].type == EventType.displayResize);
    assert(engine._backend.events.mockedEventQueue[0].displayHandle == display.handle);
}
