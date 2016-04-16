/**
 * Simple test, compileable with either the Allegro 5 or SDL 2 back ends.
 *
 * License: MIT License, see the `LICENSE` file.
 *
 * Authors: Leandro Motta Barros.
 *
 * TODO: Make this have something to do with its "maze" name.
 */

import sbxs.engine;

// All back end-dependant stuff goes here
version(UseSDL2)
{
    import sbxs.engine.backends.sdl2;

    alias Engine = SDL2Engine;
    enum windowTitle = "SDL 2 Maze";
    enum helloMessage = "Hello from the SDL-backed Maze example!";
}
else version(UseAllegro5)
{
    import sbxs.engine.backends.allegro5;

    alias Engine = Allegro5Engine;
    enum windowTitle = "Allegro 5 Maze";
    enum helloMessage = "Hello from the Allegro-backed Maze example!";
}
else
{
    static assert(false, "Please define either `UseSDL2` or `UseAllegro5` version");
}


/// The entry point, you know.
void main()
{
    import std.stdio;

    Engine engine;
    engine.initialize();
    scope(exit)
        engine.shutdown();

    writeln(helloMessage);

    engine.events.addHandler(
        delegate(Engine.Event* event)
        {
            import core.stdc.stdlib: exit;
            if (event.type == EventType.keyUp)
            {
                writefln("KEY UP! (%s - %s)", event.display, event.display.title);
                if (event.keyCode == Engine.KeyCode.escape)
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
                writefln("Mouse: %s x %s, %s (%s)!", event.mouseX, event.mouseY, event.display, event.display.title);
            }
            return false;
        },
        0 // prio
    );

    DisplayParams dp;
    dp.title = windowTitle;
    auto d = engine.display.create(dp);
    writefln("Created display %s/%s: %sx%s, %s", d.handle, d, d.width, d.height, d.title);

    while(engine.os.getTime() < 5.0)
    {
        engine.events.tick(0.2);
        engine.events.draw(0.2);
        engine.os.sleep(0.2);
        writefln("Now it is %s...", engine.os.getTime());
    }

    writefln("Leaving after 5 seconds.");
}
