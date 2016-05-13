/**
 * Definitions related with the time subsystem.
 *
 * License: MIT License, see the `LICENSE` file.
 *
 * Authors: Leandro Motta Barros.
 */

module sbxs.engine.time;

/**
 * Common implementation of the time engine subsystem.
 *
 * Mix this in your own implementation, implement the required members (and the
 * desired optional ones) and you should obtain a working subsystem.
 *
 * This provides services related with (you guessed it!) time.
 *
 * Parameters:
 *     E = The type of the engine being used.
 *
 * Notes_for_back_end_implementers:
 *
 * The following members are required:
 *
 * $(UL
 *     $(LI `double getTime()`: Returns the current wall time, in seconds,
 *         since the engine initialization.)
 *
 *     $(LI `void sleep(double timeInSecs)`: Sleeps the calling thread for
 *         `timeInSecs` seconds.)
 * )
 *
 * And these are optional:
 *
 * $(UL
 *     $(LI `void initializeBackend()`: Performs any back end-specific
 *         initialization for this subsystem.)
 *
 *     $(LI `void shutdownBackend()`: Just like `initializeBackend()`, but for
 *         finalization.)
 *
 *     $(LI `void onEndTick()`: If implemented, this is called by the Events
 *         subsystem just at the end of the `tick()` method.)
 *
 *     $(LI `void onEndDraw()`: If implemented, this is called by the Events
 *         subsystem just at the end of the `draw()` method.)
 * )
 */
public mixin template TimeCommon(E)
{
    import sbxs.engine.dbi;

    /// The engine being used.
    private E* _engine;

    /**
     * Initializes the subsystem.
     *
     * Parameters:
     *     engine = The engine being used.
     */
    package(sbxs.engine) void initialize(E* engine)
    in
    {
        assert(engine !is null);
    }
    body
    {
        _engine = engine;
        mixin(smCallIfMemberExists("initializeBackend"));
    }

    /// Shuts the subsystem down.
    package(sbxs.engine) void shutdown()
    {
        mixin(smCallIfMemberExists("shutdownBackend"));
    }
}



// -----------------------------------------------------------------------------
// Unit tests
// -----------------------------------------------------------------------------

// Just check if we can really `mixin` this into a dummy structure. (This is
// really tested by the mocked backend tests.)
unittest
{
    import sbxs.engine;

    struct DummyEngine { }

    struct DummyTime
    {
        mixin TimeCommon!DummyEngine;
    }

    DummyEngine engine;
    DummyTime timeSS;

    timeSS.initialize(&engine);

    assert(timeSS._engine == &engine);

    timeSS.shutdown();
}
