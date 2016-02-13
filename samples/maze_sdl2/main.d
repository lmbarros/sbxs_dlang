/**
 * Simple test for the SDL 2 back end.
 *
 * License: MIT License, see the `LICENSE` file.
 *
 * Authors: Leandro Motta Barros.
 *
 * TODO: Make this have something to do with its "maze" name. Also, remove code
 *       duplication with the Allegro 5 back end example.
 */

/// The entry point, you know.
void main()
{
    import std.stdio;
    import sbxs.engine.engine;
    import sbxs.engine.backend.sdl2;

    Engine!SDL2Backend engine;
    engine.initialize();

    writeln("Hello from the SDL2 Maze example!");

    writefln("Now it is %s...", engine.core.getTime());
    engine.core.sleep(0.2);
    writefln("...and now it is %s.", engine.core.getTime());

    engine.shutdown();
}
