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
    import sbxs.engine.events;
    import sbxs.engine.display;
    import sbxs.engine.backends.sdl2;

    alias Engine_t = Engine!SDL2Backend;

    Engine_t engine;
    engine.initialize();
    scope(exit)
        engine.shutdown();

    writeln("Hello from the SDL2 Maze example!");

    engine.events.addEventHandler(
        delegate(const Engine_t.Event* event)
        {
            import core.stdc.stdlib: exit;
            if (event.type == EventType.keyUp)
            {
                writefln("KEY UP!");
                if (event.keyUpKeyCode == Engine_t.KeyCode.Escape)
                {
                    writefln("PRESSED ESC!");
                    exit(0);
                }
            }
            return false;
        },
        0 // prio
    );

    DisplayParams dp;
    dp.title = "SDL 2 Maze";
    auto d = engine.display.createDisplay(dp);

    while(engine.core.getTime() < 5.0)
    {
        engine.events.tick(0.2);
        engine.events.draw(0.2);
        engine.core.sleep(0.2);
        writefln("Now it is %s...", engine.core.getTime());
    }

    writefln("Leaving after 5 seconds.");
}
