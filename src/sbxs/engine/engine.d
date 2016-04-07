/**
 * The engine (as in "game engine", though this may not qualify as a real one).
 *
 * License: MIT License, see the `LICENSE` file.
 *
 * Authors: Leandro Motta Barros.
 *
 * TODO: Add `@nogc`, `nothrow` and friends. Or maybe just templatize
 *     everything.
 */

module sbxs.engine.engine;

import std.traits: hasMember;
import sbxs.engine.backend;
import sbxs.engine.os;
import sbxs.engine.display;
import sbxs.engine.events;


/**
 * A game engine (if I can call it so; sometimes people are nitty with
 * definitions like this).
 *
 * Unlike many implementations of game engines we have nowadays, this
 * is not a singleton. I don't know why one would want to have multiple
 * instances of an `Engine`, but I am not here to prohibit this.
 *
 * Now, depending on the back end used, it may not be legal to create
 * multiple instances of the engine. In this case, feel free to
 * encapsulate and instance of `Engine` into a singleton. Likewise, if
 * you want the convenience of global access to the engine, go ahead and
 * create a singleton-like encapsulation for your project.
 *
 * Concerning thread safety: it's probably a good idea to make all calls to
 * `Engine` methods from the same thread. Some things may work when called
 * from other threads, but better safe than sorry.
 *
 * Parameters:
 *     BE = The back end providing the lower-level stuff to the engine.
 */
public struct Engine(BE)
{
    import sbxs.containers.nc_array: NCArray;

    // `Engine`s cannot be copied.
    @disable this(this);

    /// The type used as back end.
    public alias backendType = BE;

    /// The type of this engine.
    private alias engineType = Engine!backendType;

    /// The back end.
    package backendType _backend;

    /// Ditto
    package @property inout(backendType*) backend() inout { return &_backend; }

    /**
     * Initializes the engine; this must be called before using it.
     *
     * See_also: `shutdown()`
     */
    public void initialize()
    {
        _backend.initialize(&this);
        os.initialize(&this);
        events.initialize(&this);
        display.initialize(&this);
    }

    /**
     * Shuts the engine down.
     *
     * This must be called before exiting your program. `scope (exit)`
     * is your friend. After calling this, you should not use the engine
     * anymore.
     *
     * See_also: `initialize()`
     */
    public void shutdown()
    {
        display.shutdown();
        events.shutdown();
        os.shutdown();
        _backend.shutdown();
    }

    /// The Operating System subsystem.
    public OSSubsystem!engineType os;

    static if (hasMember!(backendType, "events"))
    {
        /// The Events subsystem.
        public EventsSubsystem!engineType events;

        /// Handy alias to the Event type defined by the back end.
        public alias Event = backendType.events.Event;

        /// Handy alias to the `KeyCode` enumeration defined by the back end.
        public alias KeyCode = backendType.events.KeyCode;

        /// Handy alias to the `MouseButton` enumeration defined by the back end.
        public alias MouseButton = backendType.events.MouseButton;
    }

    static if (hasMember!(backendType, "display"))
    {
        /// The Display subsystem.
        public DisplaySubsystem!engineType display;

        /// Handy alias to the Display type defined by the back end.
        public alias Display = backendType.display.Display;
    }
}



// -----------------------------------------------------------------------------
// Unit tests
// -----------------------------------------------------------------------------

// Check if the engine initializes and shuts down all back end subsystems.
unittest
{
    import sbxs.engine;
    import sbxs.engine.backends.mocked;

    Engine!MockedBackend engine;

    // Before initializing the engine itself, nothing is initialized.
    assert(engine.backend.isInited == false);
    assert(engine.backend.display.isInited == false);
    assert(engine.backend.events.isInited == false);
    assert(engine.backend.os.isInited == false);

    // Now initialize -- hopefully, everything
    engine.initialize();
    assert(engine.backend.isInited == true);
    assert(engine.backend.display.isInited == true);
    assert(engine.backend.events.isInited == true);
    assert(engine.backend.os.isInited == true);
}
