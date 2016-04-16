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


/**
 * Generates nice code to call some parameterless function if it exists as
 * a member of an aggregate.
 *
 * Parameters:
 *    funcName = The name of the function to call.
 */
public string smCallIfMemberExists(string funcName)
{
    return `
        static if (__traits(hasMember, typeof(this), "` ~ funcName ~ `"))
        {
            ` ~ funcName ~ `();
        }`;
}

///
unittest
{
    auto called = false;

    struct S
    {
        void myFunc() { called = true; }
        void doTheCalls()
        {
            mixin(smCallIfMemberExists("myFunc"));
            mixin(smCallIfMemberExists("yourFunc"));
        }
    }

    S s;
    s.doTheCalls();
    assert(called == true);
}

// Calls the string mixin generator in runtime, to count it as covered. It is
// actually tested, but in a another `unittest` block.
unittest
{
    smCallIfMemberExists("myFunc");
}
