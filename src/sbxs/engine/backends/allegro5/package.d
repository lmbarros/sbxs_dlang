/**
 * Engine back end parts based on the Allegro 5 library (and OpenGL).
 *
 * License: MIT License, see the `LICENSE` file.
 *
 * Authors: Leandro Motta Barros.
 *
 * See_also: http://liballeg.org
 */

module sbxs.engine.backends.allegro5;

public import sbxs.engine.backends.allegro5.display;
public import sbxs.engine.backends.allegro5.engine;
public import sbxs.engine.backends.allegro5.events;
public import sbxs.engine.backends.allegro5.raster;
public import sbxs.engine.backends.allegro5.time;


// Just a dummy test, to make this otherwise code-less file appear as 100%
// covered. I don't want "false negatives" taking my attention instead of real
// issues.
unittest
{
    assert(true);
}
