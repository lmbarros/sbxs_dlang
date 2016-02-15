/**
 * Simple test for the Allegro 5 back end.
 *
 * License: MIT License, see the `LICENSE` file.
 *
 * Authors: Leandro Motta Barros.
 *
 * TODO: Make this have something to do with its "maze" name. Also, remove code
 *       duplication with the SDL 2 back end example.
 */

/// The entry point, you know.
void main()
{
    import std.stdio;
    import sbxs.engine.engine;
    import sbxs.engine.display;
    import sbxs.engine.backends.allegro5;

    Engine!Allegro5Backend engine;
    engine.initialize();
    scope(exit)
        engine.shutdown();

    writeln("Hello from the Allegro5 Maze example!");

    writefln("Now it is %s...", engine.core.getTime());
    engine.core.sleep(0.2);
    writefln("...and now it is %s.", engine.core.getTime());

    DisplayParams dp;
    dp.title = "Allegro 5 Maze";
    auto d = engine.display.createDisplay(dp);
    engine.core.sleep(3.0);
}
