/**
 * Design-by-Introspection utilities targeted for Engines.
 *
 * License: MIT License, see the `LICENSE` file.
 *
 * Authors: Leandro Motta Barros.
 *
 * See_also: Andrei Alexandrescu's "Generic Programming Must Go" presentation:
 *    $(LINK2 http://dconf.org/2015/talks/alexandrescu.pdf, slides) and
 *    $(LINK2 https://www.youtube.com/watch?v=mCrVYYlFTrA, video).
 */

module sbxs.engine.dbi;

import std.traits: hasMember;

/**
 * Yields `true` if and only if Engine `E` has a subsystem `subsystem` which
 * has a member `member`.
 */
public enum engineHasMember(E, string subsystem, string member) =
    __traits(compiles, mixin("E." ~ subsystem ~ "." ~ member));

///
unittest
{
    struct OS
    {
        void sleep(double timeInSecs) { }
    }

    struct Engine
    {
        OS os;
    }

    static assert(engineHasMember!(Engine, "os", "sleep"));
    static assert(!engineHasMember!(Engine, "os", "getTime"));
    static assert(!engineHasMember!(Engine, "ooss", "sleep"));
}
