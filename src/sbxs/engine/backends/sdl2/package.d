/**
 * Engine back end parts based on the SDL 2 library (and OpenGL).
 *
 * License: MIT License, see the `LICENSE` file.
 *
 * Authors: Leandro Motta Barros.
 *
 * See_also: http://libsdl.org
 */

module sbxs.engine.backends.sdl2;

public import sbxs.engine.backends.sdl2.engine;
public import sbxs.engine.backends.sdl2.os;
public import sbxs.engine.backends.sdl2.display;
public import sbxs.engine.backends.sdl2.events;


// Just a dummy test, to make this otherwise code-less file appear as 100%
// covered. I don't want "false negatives" taking my attention instead of real
// issues.
unittest
{
    assert(true);
}
