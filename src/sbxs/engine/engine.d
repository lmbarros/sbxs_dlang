/**
 * The engine, or maybe just the pieces to assemble your own, or something
 * like that.
 *
 * License: MIT License, see the `LICENSE` file.
 *
 * Authors: Leandro Motta Barros.
 */

module sbxs.engine.engine;


/**
 * Common implementation of an Engine -- this is the engine front end, so to
 * say.
 *
 * Mix this in in your own implementation, implement the desired optional
 * members (see below) and you should obtain a working engine.
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
 *
 * Notes_for_back_end_implementers:
 *
 * Nothing is required for an engine, though an "empty" engine is not much
 * fun (it will not do anything). The optional members are listed below.
 *
 * $(UL
 *     $(LI `void initializeBackend()`: Performs any back end-specific
 *         initialization. Note that each subsystem has its own initialization
 *         routine, and you should use those when the initialization at hand
 *         is specific for that subsystem.)
 *
 *     $(LI `void shutdownBackend()`: Just like `initializeBackend()`, but for
 *         finalization.)
 *
 *     $(LI `time`: A member variable implementing a Time subsystem, which is
 *         responsible for, er, timing stuff. While timing can be seen
 *         everywhere in the Engine code, all timing information is explicitly
 *         passed to it in the main loop, via calls to `engine.events.tick()`
 *         and `engine.events.draw()`. The services provided by the Time
 *         subsystem are merely conveniences, so to say. (Perhaps, then, it
 *         should not be considered a full-blown subsystem.))
 *
 *     $(LI `events`: A member variable implementing an Events subsystem,
 *         responsible for implementing an event queue and filling this queue
 *         with input events.)
 *
 *     $(LI `display`: A member variable implementing a Display subsystem,
 *         reponsible for creating and managing Displays, which are visible
 *         areas where things can be drawn.)
 * )
 */
mixin template EngineCommon()
{
    // Engines cannot be copied.
    @disable this(this);

    /**
     * Initializes the engine; this must be called before using it.
     *
     * See_also: `shutdown()`
     *
     * TODO: Initialization (and the same applies for shut down) of subsystems
     *     is now made in a fixed order that seems to work. However, the
     *     "correct" order (or orders) actually depends on the (possibly
     *     subtle) interactions between the subsystems efectively being used.
     *     I may need to thing about a better solution for this than
     *     intializing in a fixed order.
     */
    public void initialize()
    {
        // Initialize the backend parts of the engine
        mixin(smCallIfMemberExists("initializeBackend"));

        // Initialize the subsystem themselves (each one will initialize its
        // own back end as needed)
        static if (engineHasMember!(typeof(this), "time", "initialize"))
            time.initialize(&this);

        static if (engineHasMember!(typeof(this), "events", "initialize"))
            events.initialize(&this);

        static if (engineHasMember!(typeof(this), "display", "initialize"))
            display.initialize(&this);

        static if (engineHasMember!(typeof(this), "raster", "initialize"))
            raster.initialize(&this);
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
        // Shut the subsystem themselves down (each one will shut its
        // own back down end as needed)
        static if (engineHasMember!(typeof(this), "raster", "shutdown"))
            raster.shutdown();

        static if (engineHasMember!(typeof(this), "display", "shutdown"))
            display.shutdown();

        static if (engineHasMember!(typeof(this), "events", "shutdown"))
            events.shutdown();

        static if (engineHasMember!(typeof(this), "time", "shutdown"))
            time.shutdown();

        // Shut the backend parts of the engine down
        mixin(smCallIfMemberExists("shutdownBackend"));
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



// -----------------------------------------------------------------------------
// Unit tests
// -----------------------------------------------------------------------------

// Check if the engine initializes and shuts down all back end subsystems.
// xxxxxxxxxxxxxx add raster! xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
unittest
{
    import sbxs.engine;
    import sbxs.engine.backends.mocked;

    MockedEngine engine;

    // Before initializing the engine itself, nothing is initialized.
    assert(engine.isInited == false);
    assert(engine.display.isInited == false);
    assert(engine.events.isInited == false);
    assert(engine.time.isInited == false);

    // Now initialize -- hopefully, everything
    engine.initialize();

    assert(engine.isInited == true);
    assert(engine.display.isInited == true);
    assert(engine.events.isInited == true);
    assert(engine.time.isInited == true);

    // Shutdown engine and check if all subsystems were really shut down
    engine.shutdown();

    assert(engine.isInited == false);
    assert(engine.display.isInited == false);
    assert(engine.events.isInited == false);
    assert(engine.time.isInited == false);
}
