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

    // Must provide ways to be initialized and uninitialized.
    && __traits(compiles, T.init.initialize())
    && __traits(compiles, T.init.shutdown())

    // Must provide a way to get the current time, as the number of
    // seconds passed since some arbitrary epoch.
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

    // Must provide ways to be initialized and uninitialized.
    && __traits(compiles, T.init.initialize())
    && __traits(compiles, T.init.shutdown())

    // Must provide a `Display` type, which implements the Display interface.
    && hasMember!(T, "Display")
    && is(T.Display)
    && isDisplay!(T.Display)

    // Must provide a way to create Displays.
    && hasMember!(T, "createDisplay")
    && is(ReturnType!(T.createDisplay) == T.Display*)
    && __traits(compiles, T.init.createDisplay(DisplayParams.init))
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

    // Must provide ways to be initialized and uninitialized.
    && __traits(compiles, T.init.initialize())
    && __traits(compiles, T.init.shutdown())

    // Must provide implementing the core subsystem.
    && implementsCoreBE!T
;
