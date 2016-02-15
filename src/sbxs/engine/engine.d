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


/**
 * A game engine (if we can call it so).
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
    // `Engine`s cannot be copied.
    @disable this(this);

    /**
     * Initializes the engine. This must be called before using the `Engine`.
     *
     * See_also: `shutdown()`
     */
    public void initialize()
    {
        _backend.initialize();
    }

    /**
     * Shuts the engine down. This must be called before exiting your
     * program. `scope (exit)` is your friend. After calling this, you
     * should not use the engine anymore.
     *
     * See_also: `initialize()`
     */
    public void shutdown()
    {
        _backend.shutdown();
    }

    /// The back end.
    public BE _backend;

    public alias _backend this;
}
