/**
 * The engine, or maybe just the pieces to assemble your own, or something
 * like that.
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


/**
 * Common implementation of an Engine.
 *
 * Mix this in in your own implementation, implement the required methods (and
 * the desired optional ones) and you should obtain a working subsystem.
 *
 * Unlike many implementations of game engines we have nowadays, this
 * is not meant to be a singleton. I don't know why one would want to have
 * multiple instances of an `Engine`, but I am not here to prohibit this.
 *
 * Now, depending on the back end used, it may not be legal to create
 * multiple instances of the engine. In this case, feel free to
 * encapsulate your engine instance in a singleton. Likewise, if you want
 * the convenience of global access to the engine, go ahead and create a
 * singleton-like encapsulation for your project.
 *
 * Concerning thread safety: it's probably a good idea to make all calls to
 * engine methods from the same thread. Some things may work when called
 * from other threads, but better safe than sorry.
 */
mixin template EngineCommon()
{
    // Engine cannot be copied.
    @disable this(this);

    /**
     * Initializes the engine; this must be called before using it.
     *
     * See_also: `shutdown()`
     */
    public void initialize()
    {
        mixin(smCallIfMemberExists("initializeMore"));

        static if (engineHasMember!(typeof(this), "os", "initialize"))
            os.initialize(&this);

        static if (engineHasMember!(typeof(this), "events", "initialize"))
            events.initialize(&this);

        static if (engineHasMember!(typeof(this), "display", "initialize"))
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
        static if (engineHasMember!(typeof(this), "display", "shutdown"))
            display.shutdown();

        static if (engineHasMember!(typeof(this), "events", "shutdown"))
            events.shutdown();

        static if (engineHasMember!(typeof(this), "os", "shutdown"))
            os.shutdown();
    }

    static if (engineHasMember!(typeof(this), "display", "Display"))
    {
        /// Handy alias to the Display type defined by the back end.
        public alias Display = display.Display;
    }

    static if (engineHasMember!(typeof(this), "events", "Event"))
    {
        /// Handy alias to the Event type defined by the back end.
        public alias Event = events.Event;
    }

    static if (engineHasMember!(typeof(this), "events", "KeyCode"))
    {
        /// Handy alias to the `KeyCode` enumeration defined by the back end.
        public alias KeyCode = events.KeyCode;
    }

    static if (engineHasMember!(typeof(this), "events", "MouseButton"))
    {
        /// Handy alias to the `MouseButton` enumeration defined by the back end.
        public alias MouseButton = events.MouseButton;
    }
}



/+

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

+/
