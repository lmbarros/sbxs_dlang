/**
 * Mocked back end: the back end itself.
 *
 * License: MIT License, see the `LICENSE` file.
 *
 * Authors: Leandro Motta Barros.
 */

module sbxs.engine.backends.mocked.backend;


import sbxs.engine;
import sbxs.engine.backends.mocked;

/// A mocked engine back end, used for testing.
public struct MockedBackend
{
    /// The type of an Engine using this back end.
    public alias engineType = Engine!MockedBackend;

    /// The engine using this back end.
    private engineType* _engine;

    /// Is this back end initialized?
    public @property bool isInited() const nothrow @nogc { return _isInited; }

    /// Ditto
    private bool _isInited = false;

    /**
     * Initializes the back end.
     *
     * Parameters:
     *     engine = The engine using this back end.
     */
    public void initialize(engineType* engine)
    in
    {
        assert(engine !is null);
    }
    body
    {
        _isInited = true;
        _engine = engine;

        // Initialize each subsystem
        os.initialize(_engine);
        events.initialize(_engine);
        display.initialize(_engine);
    }

    /// Shuts the back end down.
    public void shutdown()
    {
        _isInited = false;

        // Shutdown each subsystem
        display.shutdown();
        events.shutdown();
        os.shutdown();
    }

    /// The OS subsystem.
    public MockedOSSubsystem!engineType os;

    /// The Display subsystem.
    public MockedDisplaySubsystem!engineType display;

    /// The Events subsystem.
    public MockedEventsSubsystem!engineType events;

    /// The Display type, as provided by the back end.
    public alias Display = typeof(display).Display;
}



// -----------------------------------------------------------------------------
// Unit tests
// -----------------------------------------------------------------------------

// Tests if the back end is properly initialized.
unittest
{
    Engine!MockedBackend engine;
    MockedBackend be;

    // Initially, not initialized
    assert(!be.isInited);

    // Initialize
    be.initialize(&engine);
    assert(be.isInited);

    // Multiple initialization shouldn't be a problem
    be.initialize(&engine);
    assert(be.isInited);
    be.initialize(&engine);
    assert(be.isInited);

    // After shutdown, back end should no longer be considered intialized
    be.shutdown();
    assert(!be.isInited);
}
