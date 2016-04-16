/**
 * Mocked back end: Operating System subsystem.
 *
 * License: MIT License, see the `LICENSE` file.
 *
 * Authors: Leandro Motta Barros.
 */

module sbxs.engine.backends.mocked.os;

/+ xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

/**
 * Mocked Operating System engine subsystem back end.
 *
 * Parameters:
 *     E = The type of the engine using this subsystem back end.
 */
package struct MockedOSSubsystem(E)
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
        _isInited = true;
        _engine = engine;
    }

    /// Shuts the subsystem down.
    public void shutdown()
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

    /// Is this back end initialized?
    public @property bool isInited() const nothrow @nogc { return _isInited; }

    /// Ditto
    private bool _isInited = false;

    /// The current (mocked) time.
    private double _currentTime = 0.0;
}


// -----------------------------------------------------------------------------
// Unit tests
// -----------------------------------------------------------------------------

// Tests if the back end subsystem is properly initialized.
unittest
{
    import sbxs.engine;
    import sbxs.engine.backends.mocked;

    Engine!MockedBackend engine;
    MockedOSSubsystem!(Engine!MockedBackend) os;

    // Initially, not initialized
    assert(!os.isInited);

    // Initialize
    os.initialize(&engine);
    assert(os.isInited);

    // Multiple initialization shouldn't be a problem
    os.initialize(&engine);
    assert(os.isInited);
    os.initialize(&engine);
    assert(os.isInited);

    // After shutdown, back end should no longer be considered intialized
    os.shutdown();
    assert(!os.isInited);
}


// Tests if time passes as expected.
unittest
{
    import sbxs.engine;
    import sbxs.engine.backends.mocked;
    import sbxs.util.test;

    enum epsilon = 1e-7;

    Engine!MockedBackend engine;
    MockedOSSubsystem!(Engine!MockedBackend) os;

    os.mockedTickIncrements = [ 0.1, 0.2, 0.1, 0.2 ];
    os.mockedDrawIncrements = [ 0.4, 0.5 ];

    // Time should be zero initially
    assert(os.getTime() == 0.0);

    // Pass time manually
    os.sleep(1.0);
    assertClose(os.getTime(), 1.0, epsilon);

    // Pass time via calls to `onEndDraw()` and `onEndTick()`
    os.onEndTick();
    assertClose(os.getTime(), 1.1, epsilon);

    os.onEndTick();
    assertClose(os.getTime(), 1.3, epsilon);

    os.onEndDraw();
    assertClose(os.getTime(), 1.7, epsilon);

    os.onEndTick();
    assertClose(os.getTime(), 1.8, epsilon);

    os.onEndTick();
    assertClose(os.getTime(), 2.0, epsilon);

    os.onEndDraw();
    assertClose(os.getTime(), 2.5, epsilon);

    // We should be out of "times" now
    import core.exception;
    import std.exception;
    assertThrown!AssertError(os.onEndTick());
    assertThrown!AssertError(os.onEndTick());
}
+/
