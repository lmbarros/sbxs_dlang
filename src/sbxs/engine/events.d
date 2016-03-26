/**
 * Definitions related with events and event handling.
 *
 * License: MIT License, see the `LICENSE` file.
 *
 * Authors: Leandro Motta Barros.
 */

module sbxs.engine.events;

import std.traits: hasMember;


/**
 * The possible types of events.
 *
 * TODO: This list is obviously incomplete. I am focusing at the infrastructure
 *     right now.
 */
public enum EventType
{
    /// The clock ticked. Kinda like the heartbeat of the engine.
    tick,

    /**
     * The screen shall b e redrawn; all drawing shall happen in response to
     * `draw` events.
     */
    draw,

    /// A keyboard key was released.
    keyUp,

    /// The mouse pointer has moved.
    mouseMove,

    /// An app state event; used internally by the engine, don't mess with it.
    appState,

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



/**
 * Implementation of the Events engine subsystem.
 *
 * This provides services like detecting when input events happen and make them
 * available in a queue-like interface.
 *
 * Parameters:
 *     E = The type of the engine being used.
 */
package struct EventsSubsystem(E)
{
    /// An Event, as defined by the back end in use.
    public alias Event = E.backendType.events.Event;

    /// The key codes, as defined by the back end in use.
    public alias KeyCode = E.backendType.events.KeyCode;

    /**
     * A low-level event handler function.
     *
     * Receives the event data as parameter. The return value is typically
     * used to determine if other event handlers will have a chance to be
     * also called. Usually, returning `true` is interpreted as "I did
     * actually handle this event and other handlers shall be precluded to
     * handle the same event", while returning `false` is taken to mean "I
     * ended up not handling this event, so give other event handlers a
     * chance."
     *
     * TODO: Think about the semantics of the return value. Does the
     *     description above make sense? Is it useful?
     */
    public alias EventHandler = bool delegate(const Event* event);

    /// The engine being used.
    private E* _engine;

    /**
     * Initializes the subsystem.
     *
     * Parameters:
     *     engine = The engine being used.
     */
    void initialize(E* engine)
    in
    {
        assert(engine !is null);
    }
    body
    {
        _engine = engine;
    }

    /// Shuts the subsystem down.
    void shutdown() { }

    /**
     * Register a given `EventHandler` with the Event subsystem, with a
     * given priority.
     *
     * Parameters:
     *     handler = The event handler to add. Not `null`, please.
     *     prio = The priority; lower numbers have higher priority. In
     *         other words, handlers with a lower `prio` will be called
     *         before handlers with higher `prio` values.
     */
    public void addHandler(EventHandler handler, int prio)
    in
    {
        assert(handler !is null);
    }
    body
    {
        import std.algorithm: sort;
        _handlers ~= EventHandlerEntry(handler, prio);
        _handlers.sort!"a.prio < b.prio"();
    }

    /**
     * Removes a given `EventHandler`.
     *
     * Parameters:
     *     handler = The event handler to remove.
     *
     * Returns:
     *     `true` if the event handler was removed; `false` otherwise
     *     (because it was not registered with the Events subsystem).
     */
    public final bool removeHandler(EventHandler handler)
    {
        import std.algorithm: remove;

        const lenBefore = _handlers.length;

        _handlers = _handlers.remove!(a => a.handler is handler)();

        return _handlers.length < lenBefore;
    }

    /**
     * An entry in a list of event handlers: contains the event handler itself
     * and its priority.
     */
    private struct EventHandlerEntry
    {
        /// The event handler itself.
        public EventHandler handler;

        /// The priority. Smaller number means higher priority.
        public int prio;
    }

    /**
     * Calls the registered event handlers to handle a given event.
     *
     * Parameters:
     *     event = The event to be handled.
     */
    private bool callEventHandlers(const ref Event event)
    {
        auto eventAlreadyHandled = false;

        // Give global event handlers a chance to handle the event
        foreach (handlerEntry; _handlers)
        {
            if (handlerEntry.handler(&event))
                return true;
        }

        // TODO: Implement app states!
        //// Let 'AppState'-specific event handlers handle the event
        //if (!eventAlreadyHandled && numAppStates > 0 && _appStates.back.handle(event))
        //    break;

        return false;
    }

    /**
     * This must be called from the main game loop to indicate that a "tick"
     * has happened.
     *
     * This will trigger a tick event and will cause all input events to be
     * processed.
     *
     * Ticks are the game logic heartbeats. Tick handlers are the usual
     * places where the game state is updated.
     *
     * Parameters:
     *     deltaTimeInSecs = The tick time, in seconds, elapsed since the
     *         last time this function was called.
     */
    public void tick(double deltaTimeInSecs)
    {
        // Update tick time, re-sync drawing time with it
        _tickTimeInSecs += deltaTimeInSecs;
        _drawingTimeInSecs = _tickTimeInSecs;

        // Put a tick event on the event queue
        _engine.backend.events.enqueueTickEvent(_engine, deltaTimeInSecs, _tickTimeInSecs);

        // Handle events
        Event event;

        while (_engine.backend.events.dequeueEvent(_engine, &event))
        {
            // App state events are handled right here by the engine
            // itself, not by user-supplied handlers
            if (event.type == EventType.appState)
            {
                // TODO: Implement app states!
                // App State events are handled here
                // handleAppStateEvent(event); // xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
            }
            else
            {
                callEventHandlers(event);
            }
        }
    }

    /**
     * This must be called from the main game loop to indicate that a new
     * frame must be drawn.
     *
     * Causes a draw event to be generated, and all drawing should be made
     * in response to draw events.
     *
     * Parameters:
     *     deltaTimeInSecs = The tick time, in seconds, elapsed since the last
     *         time this function was called.
     */
    public void draw(double deltaTimeInSecs)
    {
        // TODO: Implement app states!
        // Return immediately if we are out of 'AppState's. (This happens when
        // exiting the program.)
        //if (numAppStates == 0)
        //    return;

        // Update the drawing time
        _drawingTimeInSecs += deltaTimeInSecs;

        const timeSinceTickInSecs = _drawingTimeInSecs - _tickTimeInSecs;

        // Call event handlers so that they can perform the drawing
        const drawEvent = _engine.backend.events.makeDrawEvent(
            _engine, deltaTimeInSecs, _drawingTimeInSecs, timeSinceTickInSecs);

        callEventHandlers(drawEvent);

        // And flip the buffers (if our back end supports this)
        static if (hasMember!(E, "display") && hasMember!(typeof(E.display), "swapAllBuffers"))
        {
            _engine.display.swapAllBuffers();
        }
    }

    /**
     * The tick time, in seconds, since the program started running.
     *
     * In normal circumnstances, this advances at the same rate as the
     * clock (wall) time, and measures the passing of time from the
     * engine point of view (which might or might not be the same as the
     * time in the game world).
     *
     * It gets updated whenever `tick()` is called.
     */
    private double _tickTimeInSecs = 0.0;

    /**
     * The drawing time, in seconds, since the program started running.
     *
     * This will advance along with the tick time (`_tickTimeInSecs`), but may
     * get temporarily ahead of it, if multiple "draw" events happen between two
     * "tick" events. This will happen if some kind of "extrapolation" is used to
     * draw things at (estimated) updated positions without running the whole
     * (presumably CPU-intensive) game logic in between.
     *
     * It gets updated whenever `draw()` or `tick()` is called.
     */
    private double _drawingTimeInSecs = 0.0;

    /// The registered event handlers.
    private EventHandlerEntry[] _handlers;
}
