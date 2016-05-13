/**
 * Mocked back end: Display subsystem.
 *
 * License: MIT License, see the `LICENSE` file.
 *
 * Authors: Leandro Motta Barros.
 */

module sbxs.engine.backends.mocked.display;

import sbxs.engine;


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
     * The state of a `MockedDisplay`.
     *
     * This is placed in a `struct` to make it easier to allocate in the
     * heap, so that it is shared among all copies of a Display (recall
     * that Displays shall have reference semantics).
     */
    private struct MockedDisplayState
    {
        /// A handle that uniquely identifies the Display.
        handleType handle;

        /// Is the Display initialized and ready-to-use?
        bool isInited = false;

        /// The Display width, in pixels.
        int width = 0;

        /// The Display height, in pixels.
        int height = 0;

        /// The Display title.
        string title;

        /// Number of times buffers were swapped.
        int swapBuffersCount = 0;
    }

    /// The state of this Display.
    private MockedDisplayState* _state = null;

    /**
     * Constructs the `MockedDisplay`.
     *
     * Parameters:
     *     params = The parameters specifying how the Display shall be like.
     */
    package(sbxs.engine) this(DisplayParams params)
    {
        if (_state is null)
            _state = new MockedDisplayState();

        _state.handle = _nextDisplayHandle++;
        _state.isInited = true;

        // Set the Display parameters
        _state.title = params.title;
        _state.width = params.width;
        _state.height = params.height;

        // Make it the current one
        _currentDisplay = _state.handle;
    }

    /// Destroys the Display.
    package(sbxs.engine) void destroy() //nothrow @nogc
    {
        _state.isInited = false;
    }

    /// The Display width, in pixels.
    public @property int width() nothrow @nogc
    {
        return _state.width;
    }

    /// Ditto
    public @property void width(int newWidth) nothrow @nogc
    {
        _state.width = newWidth;
    }

    /// The Display height, in pixels.
    public @property int height() nothrow @nogc
    {
        return _state.height;
    }

    /// Ditto
    public @property void height(int newHeight) nothrow @nogc
    {
        _state.height = newHeight;
    }

    /**
     * Simulates a Display resize.
     *
     * This willl work only to be used with the Mocked back end components.
     */
    public void simulateResize(E)(E* engine, int width, int height, handleType displayHandle)
    {
        // Update the internal state
        _state.width = width;
        _state.height = height;

        // TODO: This could taste more like Design by Introspection. These names
        //       and interfaces weren't really designed with DbI this in mind.
        static if (engineHasMember!(E, "events", "makeDisplayResizeEvent")
            && engineHasMember!(E, "events", "mockedEventQueue"))
        {
            // Generate a resize event and enqueue it
            auto event = engine.events.makeDisplayResizeEvent(displayHandle);
            engine.events.mockedEventQueue ~= event;
        }
    }

    /// The Display title.
    public @property string title() nothrow @nogc const
    {
        return _state.title;
    }

    /// Ditto
    public @property void title(string newTitle) nothrow @nogc
    {
        _state.title = newTitle;
    }

    /// Make this Display the current target for rendering.
    public void makeCurrent() nothrow @nogc
    {
        _currentDisplay = _state.handle;
    }

    /**
     * Pretends to swap buffers.
     *
     * In fact, just increments a counter telling how many times buffers were
     * swapped.
     */
    public void swapBuffers() nothrow @nogc
    {
        ++_state.swapBuffersCount;
    }

    /// A handle that uniquely identifies this Display.
    public @property handleType handle() nothrow @nogc
    {
        return _state.handle;
    }

    /// Is this Display initialized and ready-to-use?
    public @property bool isInited() const nothrow @nogc { return _state.isInited; }

    /// Number of times buffers were swapped.
    public @property int swapBuffersCount() const nothrow @nogc { return _state.swapBuffersCount; }

    /// A type for a handle that uniquely identifies a Display.
    public alias handleType = size_t;

    /// A handle different than any valid Display handle.
    public enum invalidDisplay = 0;

    /**
     * The Display currently active. `invalidDisplay` if no Display was created
     * yet.
     */
    public static handleType currentDisplay() { return _currentDisplay; }

    /// Ditto
    private static handleType _currentDisplay = invalidDisplay;

    /// The handle for the next Display created.
    private static int _nextDisplayHandle = 1;
}


/**
 * Mocked display engine subsystem back end, for testing.
 *
 * Parameters:
 *     E = The type of the engine using this subsystem back end.
 */
package struct MockedDisplaySubsystem(E)
{
    mixin DisplayCommon!E;

    /// Initializes the subsystem.
    package(sbxs.engine) void initializeBackend() nothrow @nogc
    {
        _isInited = true;
    }

    /// Shuts the subsystem down.
    package(sbxs.engine) void shutdownBackend() nothrow @nogc
    {
        MockedDisplay._currentDisplay = MockedDisplay.invalidDisplay;
        MockedDisplay._nextDisplayHandle = 1;
        _isInited = false;
    }

    /// The type used as Display.
    public alias Display = MockedDisplay;

    /// Is this back end initialized?
    public @property bool isInited() const nothrow @nogc { return _isInited; }

    /// Ditto
    private bool _isInited = false;
}



// -----------------------------------------------------------------------------
// Unit tests
// -----------------------------------------------------------------------------

version(unittest)
{
    import sbxs.engine;
    import sbxs.engine.backends.mocked;

    struct TestEngine
    {
        mixin EngineCommon;
        MockedDisplaySubsystem!TestEngine display;
    }

    struct TestEngineWithEvents
    {
        mixin EngineCommon;
        MockedDisplaySubsystem!TestEngineWithEvents display;
        MockedEventsSubsystem!TestEngineWithEvents events;
    }
}


// Tests initialization and finalization.
unittest
{
    MockedDisplaySubsystem!TestEngine display;
    assert(display.isInited == false);

    display.initializeBackend();
    assert(display.isInited == true);

    display.shutdownBackend();
    assert(display.isInited == false);
}


// Tests if shutdown resets the current display to an invalid Display.
unittest
{
    DisplayParams params;
    params.title = "Ceci n'est pas un Display";

    // Create the engine, ensure that the current display is not set
    TestEngine engine;
    engine.initialize();
    assert(MockedDisplay.currentDisplay == MockedDisplay.invalidDisplay);

    // Create a Display; this should set the current display
    auto display = engine.display.create(params);
    assert(MockedDisplay.currentDisplay != MockedDisplay.invalidDisplay);

    // Shut down the first engine; the current display shall be reset
    engine.shutdown();
    assert(MockedDisplay.currentDisplay == MockedDisplay.invalidDisplay);
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


// Test if Displays are really reference types.
unittest
{
    DisplayParams params;
    params.title = "A Display";
    params.width = 600;
    params.height = 400;

    auto display = MockedDisplay(params);

    // Check the Display parameters
    assert(display.title == "A Display");
    assert(display.width == 600);
    assert(display.height == 400);

    // Create a new reference to the Display, change it through the new reference
    auto sameDisplay = display;
    sameDisplay.title = "Same Display";
    sameDisplay.width = 1920;
    sameDisplay.height = 1080;

    assert(display.title == "Same Display");
    assert(display.width == 1920);
    assert(display.height == 1080);

    // Destroy the Display through the other reference
    sameDisplay.destroy();
    assert(!display.isInited);
    assert(!sameDisplay.isInited);
}


// Test multiple Displays.
unittest
{
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
    TestEngineWithEvents engine;
    engine.initialize();

    DisplayParams params;
    params.width = 1000;
    params.height = 500;
    auto display = MockedDisplay(params);

    // Check initial dimensions
    assert(display.width == 1000);
    assert(display.height == 500);

    // Also, be sure that the engine event queue is empty
    assert(engine.events.mockedEventQueue.length == 0);

    // Resize; check if dimensions changed and event was enqueued
    display.simulateResize(&engine, 411, 122, display.handle);

    assert(display.width == 411);
    assert(display.height == 122);

    assert(engine.events.mockedEventQueue.length == 1);
    assert(engine.events.mockedEventQueue[0].type == EventType.displayResize);
    assert(engine.events.mockedEventQueue[0].displayHandle == display.handle);
}
