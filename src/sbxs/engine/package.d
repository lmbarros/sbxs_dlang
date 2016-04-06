/**
 * Includes everything from Engine, with a single, handy `import`.
 *
 * License: MIT License, see the `LICENSE` file.
 *
 * Authors: Leandro Motta Barros.
 */

module sbxs.engine;

public import sbxs.engine.backend;
public import sbxs.engine.display;
public import sbxs.engine.engine;
public import sbxs.engine.events;
public import sbxs.engine.os;


// Just a dummy test, to make this otherwise code-less file appear as 100%
// covered. I don't want "false negatives" taking my attention instead of real
// issues.
unittest
{
    assert(true);
}
