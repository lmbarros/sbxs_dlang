/**
 * Definitions related with engine back ends.
 *
 * License: MIT License, see the `LICENSE` file.
 *
 * Authors: Leandro Motta Barros.
 */

module sbxs.engine.backend;

import std.traits;
import sbxs.engine.display;
import sbxs.error.exception;


//
// Exceptions
//

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
            ~ (additionalInfo.length > 0)
                ? "Here's what the back end has to say about it: " ~ additionalInfo
                : "The back end doesn't have anything else to say about it, sorry.";
        super(msg, file, line, next);
    }
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
            ~ (additionalInfo.length > 0)
                ? "Here's what the back end has to say about it: " ~ additionalInfo
                : "The back end doesn't have anything else to say about it, sorry.";
        super(msg, file, line, next);
    }
}



//
// Core subsystem
//

/**
 * Checks if something implements the core back end interface.
 *
 * The core back end interface (which must be implemented by every back end)
 * provides some basic features, like getting the wall time and sleeping for
 * a given amount of time.
 */
public enum isCoreBE(T) =
    // Must be implemented as a `struct`.
    is(T == struct)

    // Must provide ways to be initialized and uninitialized. This `null` would
    // be the actual engine being used.
    && __traits(compiles, T.init.initialize(null))
    && __traits(compiles, T.init.shutdown())

    // Must provide a way to get the current time, as the number of
    // seconds passed since the program started running.
    && __traits(compiles, { double t = T.init.getTime(); })

    // Must provide a way to make the current thread sleep for a given
    // number of seconds.
    && __traits(compiles, T.init.sleep(1.1))
;


/// Checks if something implements the core back end interface.
public enum implementsCoreBE(T) =
    // Has a `core` member...
    hasMember!(T, "core")

    //... which implements the core back end interface.
    && isCoreBE!(typeof(T.core))
;



//
// Display subsystem
//

/// Checks if something implements the display back end interface.
public enum isDisplayBE(T) =
    // Must be implemented as a `struct`.
    is(T == struct)

    // Must provide ways to be initialized and uninitialized. This `null` would
    // be the actual engine being used.
    && __traits(compiles, T.init.initialize(null))
    && __traits(compiles, T.init.shutdown())

    // Must provide a `Display` type, which implements the Display interface.
    && hasMember!(T, "Display")
    && is(T.Display)
    && isDisplay!(T.Display)

    // TODO: xxxxxxxxxxxxxxxxxxxxxxx update this!
    // Must provide a way to create Displays.
    && hasMember!(T, "createDisplay")
    //&& is(ReturnType!(T.createDisplay) == T.Display*)
    //&& __traits(compiles, T.init.createDisplay(DisplayParams.init))
;


/// Checks if something implements the display back end interface.
public enum implementsDisplayBE(T) =
    // Has a `display` member...
    hasMember!(T, "display")

    //... which implements the display back end interface.
    && isDisplayBE!(typeof(T.display))
;



//
// Events subsystem
//
public enum isEventsBE(T) =
    // Must be implemented as a `struct`.
    is(T == struct)
    // TODO: add stuff here! xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
;


/// Checks if something implements the events back end interface.
public enum implementsEventsBE(T) =
    // Has a `events` member...
    hasMember!(T, "events")

    //... which implements the core back end interface.
    && isEventsBE!(typeof(T.events))
;



//
// The back end itself
//

/**
 * Checks if something implements the back end interface.
 *
 * This tests for the minimal required back end implementation. There
 * are many optional parts that a back end can implement. These can be
 * tested with the `implements*BE` traits.
 */
public enum isBackend(T) =
    // Must be implemented as a `struct`.
    is(T == struct)

    // Must provide ways to be initialized and uninitialized. The `null` passed
    // here would be the engine using `T` as the back end.
    && __traits(compiles, T.init.initialize(null))
    && __traits(compiles, T.init.shutdown())

    // Must implement the core subsystem.
    && implementsCoreBE!T
;
