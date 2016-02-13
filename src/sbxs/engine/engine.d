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
 *
 */
public struct Engine(BE)
{
    @disable this(this);

    public void initialize()
    {
        backend.initialize();
    }

    public void shutdown()
    {
        backend.shutdown();
    }

    BE backend;

    alias backend this;
}
