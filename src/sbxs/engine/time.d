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
 * Mix this in your own implementation, implement the required methods (and the
 * desired optional ones) and you should obtain a working subsystem.
 *
 * This provides services related with (you guessed it!) time.
 *
 * Parameters:
 *     E = The type of the engine being used.
 */
public mixin template TimeCommon(E)
{
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
    }

    /// Shuts the subsystem down.
    void shutdown() { }
}

/+ xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

// -----------------------------------------------------------------------------
// Unit tests
// -----------------------------------------------------------------------------

// Tests `getTime()` and `sleep()`.
unittest
{
    import sbxs.engine;
    import sbxs.engine.backends.mocked;

    Engine!MockedBackend engine;

    engine.initialize();

    assert(engine.time.getTime() == 0.0);
    assert(engine.time.getTime() == 0.0);

    engine.time.sleep(1.0);

    assert(engine.time.getTime() == 1.0);

    engine.time.sleep(1.0);
    engine.time.sleep(10.0);
    engine.time.sleep(1.0);

    assert(engine.time.getTime() == 13.0);
    assert(engine.time.getTime() == 13.0);
}

+/
