/**
 * Definitions related with engine back ends.
 *
 * License: MIT License, see the `LICENSE` file.
 *
 * Authors: Leandro Motta Barros.
 */

module sbxs.engine.backend;

import sbxs.error.exception;


/**
 * Base for all back end exceptions.
 *
 * Try to use one of the subclasses, if appropriate.
 */
public class BackendException: SBXSException
{
    public this(string msg, string file = __FILE__, size_t line = __LINE__,
        Throwable next = null) nothrow @nogc @safe
    {
        super(msg, file, line, next);
    }
}


// Not much to test in here. Just check if `msg` is as expected.
unittest
{
   bool caught = false;

   try
   {
      throw new BackendException("Augh!");
   }
   catch(BackendException e)
   {
      assert(e.msg == "Augh!");
      caught = true;
   }

   // Sanity check: did we really got into that exception handler?
   assert(caught == true);
}



/**
 * Exception thrown when an error happens during the initialization of the
 * back end.
 */
public class BackendInitializationException: BackendException
{
    /**
     * Constructs the exception.
     *
     * Parameters:
     *     additionalInfo = If the back end can add some information about what
     *         has failed or what can be done to fix it, please pass it here.
     */
    public this(string additionalInfo = "", string file = __FILE__,
        size_t line = __LINE__, Throwable next = null) nothrow @safe
    {
        const msg = "Error while initializing the engine back end. "
            ~ (additionalInfo.length > 0
                ? ("Here's what the back end has to say about it: " ~ additionalInfo)
                : "The back end doesn't have anything else to say about it, sorry.");
        super(msg, file, line, next);
    }
}

// Not much to test in here. Just check if `msg` is somewhat as expected.
unittest
{
    assertThrownWithMessage!BackendInitializationException("Augh!");
    assertThrownWithoutMessage!BackendInitializationException("Augh!");
}



/// Exception thrown when an error happens while creating a display.
public class DisplayCreationException: BackendException
{
    /**
     * Constructs the exception.
     *
     * Parameters:
     *     additionalInfo = If the back end can add some information about what
     *         has failed or what can be done to fix it, please pass it here.
     */
    public this(string additionalInfo = "", string file = __FILE__,
        size_t line = __LINE__, Throwable next = null) nothrow @safe
    {
        const msg = "Error while creating a display. "
            ~ (additionalInfo.length > 0
                ? ("Here's what the back end has to say about it: " ~ additionalInfo)
                : "The back end doesn't have anything else to say about it, sorry.");
        super(msg, file, line, next);
    }
}

// Not much to test in here. Just check if `msg` is somewhat as expected.
unittest
{
    assertThrownWithMessage!DisplayCreationException("Augh!");
    assertThrownWithoutMessage!DisplayCreationException("Augh!");
}
