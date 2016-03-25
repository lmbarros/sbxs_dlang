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

    engine.addEventHandler(
        delegate(const Engine_t.Event* event)
        {
            import core.stdc.stdlib: exit;
            if (event.type == EventType.keyUp)
            {
                writefln("KEY UP! (%s)", event.display);
                if (event.keyCode == Engine_t.KeyCode.escape)
                {
                    writefln("PRESSED ESC!");
                    exit(0);
                }
            }
            else if (event.type == EventType.tick)
            {
                writefln("Tick: %s, %s!", event.deltaTimeInSecs, event.tickTimeInSecs);
            }
            else if (event.type == EventType.draw)
            {
                import derelict.opengl3.gl3;
                import std.random;
                glClearColor(uniform01(), uniform01(), uniform01(), 1.0);
                glClear(GL_COLOR_BUFFER_BIT);
            }
            else if (event.type == EventType.mouseMove)
            {
                writefln("Mouse: %s x %s, %s!", event.mouseX, event.mouseY, event.display);
            }
            return false;
        },
        0 // prio
    );

    DisplayParams dp;
    dp.title = "SDL 2 Maze";
    auto d = engine.createDisplay(dp);

    while(engine.getTime() < 5.0)
    {
        engine.tick(0.2);
        engine.draw(0.2);
        engine.sleep(0.2);
        writefln("Now it is %s...", engine.getTime());
    }

    writefln("Leaving after 5 seconds.");
}
