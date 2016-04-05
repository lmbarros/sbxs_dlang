/**
 * A mocked engine back end, used for testing.
 *
 * License: MIT License, see the `LICENSE` file.
 *
 * Authors: Leandro Motta Barros.
 *
 * See_also: http://liballeg.org
 */

module sbxs.engine.backends.mocked;

public import sbxs.engine.backends.mocked.backend;
public import sbxs.engine.backends.mocked.os;
public import sbxs.engine.backends.mocked.display;
public import sbxs.engine.backends.mocked.events;


// Just a dummy test, to make this otherwise code-less file appear as 100%
// covered. I don't want "false negatives" taking my attention instead of real
// issues.
unittest
{
    assert(true);
}
