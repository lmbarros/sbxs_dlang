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


// Not much to test in `SBXSException`. Just check if `msg` is as expected.
unittest
{
    bool caught = false;

    try
    {
        throw new SBXSException("Augh!");
    }
    catch(SBXSException e)
    {
        assert(e.msg == "Augh!");
        caught = true;
    }

    // Sanity check: did we really got into that exception handler?
    assert(caught == true);
}
