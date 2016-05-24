/**
 * Raster subsystem, mocked for testing.
 *
 * License: MIT License, see the `LICENSE` file.
 *
 * Authors: Leandro Motta Barros.
 */

module sbxs.engine.backends.mocked.raster;

/+

// xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
package struct Bitmap
{
    /**
     * The state of a `MockedBitmap`.
     *
     * This is placed in a `struct` to make it easier to allocate in the
     * heap, so that it is shared among all copies of a Display (recall
     * that Displays shall have reference semantics).
     */
    private struct MockedBitmapState
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
}



/**
 * Raster subsystem, mocked for testing.
 *
 * Parameters:
 *     E = The type of the engine using this subsystem.
 */
package struct MockedRasterSubsystem(E)
{
    import sbxs.engine.raster: RasterCommon;

    mixin RasterCommon!E;

    /// Initializes the subsystem.
    package(sbxs.engine) void initializeBackend()
    {
        _isInited = true;
    }

    /// Shuts the subsystem down.
    package(sbxs.engine) void shutdownBackend()
    {
        _isInited = false;
    }

    // xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

    public alias Bitmap = MockedBitmap;

    // xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

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
        MockedTimeSubsystem!TestEngine time;
    }
}


// Tests initialization and finalization.
unittest
{
    MockedTimeSubsystem!TestEngine timeSS;
    assert(timeSS.isInited == false);

    timeSS.initializeBackend();
    assert(timeSS.isInited == true);

    timeSS.shutdownBackend();
    assert(timeSS.isInited == false);
}


// Tests if time passes as expected.
unittest
{
    import sbxs.util.test;

    enum epsilon = 1e-7;

    MockedTimeSubsystem!TestEngine timeSS;
    timeSS.initializeBackend();

    timeSS.mockedTickIncrements = [ 0.1, 0.2, 0.1, 0.2 ];
    timeSS.mockedDrawIncrements = [ 0.4, 0.5 ];

    // Time should be zero initially
    assert(timeSS.getTime() == 0.0);

    // Pass time manually
    timeSS.sleep(1.0);
    assertClose(timeSS.getTime(), 1.0, epsilon);

    // Pass time via calls to `onEndDraw()` and `onEndTick()`
    timeSS.onEndTick();
    assertClose(timeSS.getTime(), 1.1, epsilon);

    timeSS.onEndTick();
    assertClose(timeSS.getTime(), 1.3, epsilon);

    timeSS.onEndDraw();
    assertClose(timeSS.getTime(), 1.7, epsilon);

    timeSS.onEndTick();
    assertClose(timeSS.getTime(), 1.8, epsilon);

    timeSS.onEndTick();
    assertClose(timeSS.getTime(), 2.0, epsilon);

    timeSS.onEndDraw();
    assertClose(timeSS.getTime(), 2.5, epsilon);

    // We should be out of "times" now
    import core.exception;
    import std.exception;
    assertThrown!AssertError(timeSS.onEndTick());
    assertThrown!AssertError(timeSS.onEndDraw());
}

+/
