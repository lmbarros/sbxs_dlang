/**
 * A mocked engine, for testing.
 *
 * License: MIT License, see the `LICENSE` file.
 *
 * Authors: Leandro Motta Barros.
 */

module sbxs.engine.backends.mocked.engine;

import sbxs.engine;


/// A completely mocked engine.
public struct MockedEngine
{
    import sbxs.engine.backends.mocked;

    mixin EngineCommon;

    /// Initializes the engine back end.
    package(sbxs.engine) void initializeBackend()
    {
        _isInited = true;
    }

    /// Shuts the engine back end down.
    package(sbxs.engine) void shutdownBackend()
    {
        _isInited = false;
    }

    /// The display subsystem.
    public MockedDisplaySubsystem!MockedEngine display;

    /// The events subsystem.
    public MockedEventsSubsystem!MockedEngine events;

    /// The time subsystem.
    public MockedTimeSubsystem!MockedEngine time;

    /// Is this back end initialized?
    public @property bool isInited() const nothrow @nogc { return _isInited; }

    /// Ditto
    private bool _isInited = false;
}



// Tests initialization and finalization.
unittest
{
    MockedEngine engine;
    assert(engine.isInited == false);

    engine.initializeBackend();
    assert(engine.isInited == true);

    engine.shutdownBackend();
    assert(engine.isInited == false);
}
