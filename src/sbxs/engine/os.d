/**
 * Definitions related with the Operating System subsystem.
 *
 * License: MIT License, see the `LICENSE` file.
 *
 * Authors: Leandro Motta Barros.
 */

module sbxs.engine.os;

/**
 * Common implementation of the Operating System engine subsystem.
 *
 * Mix this in your own implementation, implement the required methods (and the
 * desired optional ones) and you should obtain a working subsystem.
 *
 * This provides Operating System services. Er, I mean, those OS services that
 * are not provided by any other subsystem.
 *
 *
 * Parameters:
 *     E = The type of the engine being used.
 */
public mixin template OSCommon(E)
{
    /// The engine being used.
    private E* _engine;

    /**
     * Initializes the subsystem.
     *
     * Parameters:
     *     engine = The engine being used.
     */
    void initialize(E* engine)
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

    assert(engine.os.getTime() == 0.0);
    assert(engine.os.getTime() == 0.0);

    engine.os.sleep(1.0);

    assert(engine.os.getTime() == 1.0);

    engine.os.sleep(1.0);
    engine.os.sleep(10.0);
    engine.os.sleep(1.0);

    assert(engine.os.getTime() == 13.0);
    assert(engine.os.getTime() == 13.0);
}

+/
