/**
 * Time subsystem, mocked for testing.
 *
 * License: MIT License, see the `LICENSE` file.
 *
 * Authors: Leandro Motta Barros.
 */

module sbxs.engine.backends.mocked.time;


/**
 * Time subsystem, mocked for testing.
 *
 * Parameters:
 *     E = The type of the engine using this subsystem.
 */
package struct MockedTimeSubsystem(E)
{
    import sbxs.engine.time: TimeCommon;

    mixin TimeCommon!E;

    /// Initializes the subsystem.
    public void initializeBackend()
    {
        _isInited = true;
    }

    /// Shuts the subsystem down.
    public void shutdownBackend()
    {
        _isInited = false;
    }

    /// Returns the current wall time, in seconds since some unspecified epoch.
    public double getTime()
    {
        return _currentTime;
    }

    /// Sleeps the current thread for a given number of seconds.
    public void sleep(double timeInSecs)
    {
        _currentTime += timeInSecs;
    }

    /**
     * Advances the current time by `mockedTickIncrements[0]` seconds.
     *
     * This is called by the `Engine` when a tick ends.
     *
     * This `assert()`s if no more mocked time increments are available.
     */
    package(sbxs.engine) void onEndTick() @nogc nothrow
    in
    {
        assert(mockedTickIncrements.length > 0,
            "No more mocked tick increments available!");
    }
    body
    {
        _currentTime += mockedTickIncrements[0];
        mockedTickIncrements = mockedTickIncrements[1..$];
    }

    /**
     * Advances the current time by `mockedDrawIncrements[0]` seconds.
     *
     * This is called by the `Engine` when a draw ends.
     *
     * This `assert()`s if no more mocked draw increments are available.
     */
    package(sbxs.engine) void onEndDraw() @nogc nothrow
    in
    {
        assert(mockedDrawIncrements.length > 0,
            "No more mocked draw increments available!");
    }
    body
    {
       _currentTime += mockedDrawIncrements[0];
       mockedDrawIncrements = mockedDrawIncrements[1..$];
    }

    /**
     * The times by which the current time will be incremented on each call to
     * `onEndTick()`.
     *
     * The array shrinks as time passes.
     *
     * This is public so that users can set it up as desired.
     */
    public double[] mockedTickIncrements = [ ];

    /**
     * The times by which the current time will be incremented on each call to
     * `onEndDraw()`.
     *
     * The array shrinks as time passes.
     *
     * This is public so that users can set it up as desired.
     */
    public double[] mockedDrawIncrements = [ ];

    /// The current (mocked) time.
    private double _currentTime = 0.0;

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
    MockedTimeSubsystem!TestEngine time;
    assert(time.isInited == false);

    time.initializeBackend();
    assert(time.isInited == true);

    time.shutdownBackend();
    assert(time.isInited == false);
}


// Tests if time passes as expected.
unittest
{
    import sbxs.util.test;

    enum epsilon = 1e-7;

    TestEngine engine;
    engine.initialize();

    engine.time.mockedTickIncrements = [ 0.1, 0.2, 0.1, 0.2 ];
    engine.time.mockedDrawIncrements = [ 0.4, 0.5 ];

    // Time should be zero initially
    assert(engine.time.getTime() == 0.0);

    // Pass time manually
    engine.time.sleep(1.0);
    assertClose(engine.time.getTime(), 1.0, epsilon);

    // Pass time via calls to `onEndDraw()` and `onEndTick()`
    engine.time.onEndTick();
    assertClose(engine.time.getTime(), 1.1, epsilon);

    engine.time.onEndTick();
    assertClose(engine.time.getTime(), 1.3, epsilon);

    engine.time.onEndDraw();
    assertClose(engine.time.getTime(), 1.7, epsilon);

    engine.time.onEndTick();
    assertClose(engine.time.getTime(), 1.8, epsilon);

    engine.time.onEndTick();
    assertClose(engine.time.getTime(), 2.0, epsilon);

    engine.time.onEndDraw();
    assertClose(engine.time.getTime(), 2.5, epsilon);

    // We should be out of "times" now
    import core.exception;
    import std.exception;
    assertThrown!AssertError(engine.time.onEndTick());
    assertThrown!AssertError(engine.time.onEndDraw());
}
