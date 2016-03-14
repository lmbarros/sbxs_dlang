/**
 * Definitions related with events and event handling.
 *
 * License: MIT License, see the `LICENSE` file.
 *
 * Authors: Leandro Motta Barros.
 */

module sbxs.engine.events;


/**
 * The possible types of events.
 */
public enum EventType
{
    /// The clock ticked. Kinda like the heartbeat of the engine.
    tick,

    /// An app state event; used internally by the engine, don't mess with it.
    appState,

    /// A keyboard key was released.
    keyUp,

    /// The mouse pointer has moved.
    mouseMove,

    /// An event type that is unknown to the engine.
    unknown,
}



/**
 * Checks if something is an event.
 *
 * An event is
 */
public enum isEvent(T) =
    // Must be implemented as a struct.
    is (T == struct)

    // Must provide a `type` member.
    && hasMember!(T, "type")
    && is (typeof(T.type) == EventType)


    /*
    // Must provide a handle that uniquely identifies them. This shall
    // be a lightweight cheaply copyable type.
    && hasMember!(T, "handle")
    && hasMember!(T, "handle_t")
    && is (T.handle_t)
    && is (typeof(T.handle) == T.handle_t)

    // Must provide ways to access their width and height, in pixels.
    && hasMember!(T, "width")
    && is (typeof(T.width) : int)
    && hasMember!(T, "height")
    && is (typeof(T.height) : int)

    // Displays must provide a `makeCurrent()` method, used to set them
    // as the target for subsequent rendering.
    && __traits(compiles, T.init.makeCurrent())

    // Displays must provide a `swapBuffers()` method, used to, well,
    // swap buffers. This implies that double buffering is expected, but
    // an implemention could just implement this as a no-op (and just
    // pretend to be double buffered).
    && __traits(compiles, T.init.swapBuffers())
    */
;
