/**
 * Exception-related stuff.
 *
 * License: MIT License, see the `LICENSE` file.
 *
 * Authors: Leandro Motta Barros.
 */

module sbxs.error.exception;


/// Base class for all SBXS exceptions.
public class SBXSException: Exception
{
    public this(string msg, string file = __FILE__, size_t line = __LINE__,
        Throwable next = null) nothrow @nogc @safe
    {
        super(msg, file, line, next);
    }
}


version(unittest)
{
    /// Checks if a given exception message includes `msg`.
    void assertThrownWithMessage(T)(string msg)
    {
        bool caught = false;

        try
        {
            throw new T(msg);
        }
        catch(T e)
        {
            import std.string: indexOf;
            assert(indexOf(e.msg, msg) >= 0);
            caught = true;
        }

        // Sanity check: did we really got into that exception handler?
        assert(caught == true);
    }

    /// Checks if a given exception message doesn't include `msg`.
    void assertThrownWithoutMessage(T)(string msg)
    {
        bool caught = false;

        try
        {
            throw new T;
        }
        catch(T e)
        {
            import std.string: indexOf;
            assert(indexOf(e.msg, msg) < 0);
            caught = true;
        }

        // Sanity check: did we really got into that exception handler?
        assert(caught == true);
    }
}

// Not much to test in `SBXSException`. Just check if `msg` is as expected.
unittest
{
    assertThrownWithMessage!SBXSException("Augh!");
}
