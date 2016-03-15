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



/**
 * Implementation of the Events engine subsystem. This is a `mixin template`
 * just to allow me to easily (should I say "lazily"?) split the engine
 * implementation in multiple files.
 */
mixin template EventsSubsystem(BE)
{
    // TODO: Doc me xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
    public alias Event = BE.events.Event;
    public alias KeyCode = BE.events.KeyCode;
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
     *
     */
    public alias EventHandler = bool delegate(const Event* event);
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
    public void addEventHandler(EventHandler handler, int prio)
    in
    {
        assert(handler !is null);
    }
    body
    {
        import std.algorithm: sort;
        _eventHandlers ~= EventHandlerEntry(handler, prio);
        _eventHandlers.sort!"a.prio < b.prio"();
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
    public final bool removeEventHandler(EventHandler handler)
    {
        import std.algorithm: remove;

        const lenBefore = _eventHandlers.length;

        _eventHandlers = _eventHandlers.remove!(a => a.handler is handler)();

        return _eventHandlers.length < lenBefore;
    }

    // xxxxxxxxxxxxxx TODO: Doc me!
    private struct EventHandlerEntry
    {
        /// The event handler itself.
        public EventHandler handler;

        /// The priority. Smaller number means higher priority.
        public int prio;
    }

   /**
    * This must be called from the main game loop to indicate that a "tick"
    * has happened.
    *
    * This will trigger a tick event and will cause all other input events
    * to be processed.
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
        _backend.events.enqueueTickEvent(deltaTimeInSecs, _tickTimeInSecs);

        // Handle events
        Event event;
        while (_backend.events.dequeueEvent(&event))
        {
            // App state events are handled right here by the engine
            // itself, not by user-supplied handlers
            if (event.type == EventType.appState)
            {
                // App State events are handled here
                // TODO: Implement me!
                // handleAppStateEvent(event); // xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
            }
            else
            {
                auto eventAlreadyHandled = false;

                // Give global event handlers a chance to handle the event
                foreach (handlerEntry; _eventHandlers)
                {
                    if (handlerEntry.handler(&event))
                    {
                        eventAlreadyHandled = true;
                        break;
                    }
                }

                //// Let 'AppState'-specific event handlers handle the event
                //if (!eventAlreadyHandled && numAppStates > 0 && _appStates.back.handle(event))
                //    break;
            }
        }
    }

    /**
     * This must be called from the main game loop to indicate that a new
     * frame must be drawn.
     *
     * TODO: xxxxxxxxxxxxxxxxxxxxxxx "Causes a draw event to be generated".
     *     Must think about it a bit; drawing will be special, will it not?
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
        /*
        // Return immediately if we are out of 'AppState's. (This happens when
        // exiting the program.)
        if (numAppStates == 0)
            return;
        */

        // Update the drawing time
        _drawingTimeInSecs += deltaTimeInSecs;

        /*
        // Call draw() on the current App State
        const timeSinceTick = _drawingTime - _tickTime;
        _appStates.back.onDraw(deltaTime, _drawingTime, timeSinceTick);
        */

        // TODO: xxxxxxxxxxxxxxxxxx This will method exist only if a Display
        //     subsystem exists? Maybe not, I could draw to a console...
        //     Anyway, swapAllBuffers() will be called only if a Display back
        //     end exists.
        //
        // And flip the buffers
        swapAllBuffers();
    }

    /**
     * The tick time, in seconds, since the program started running.
     *
     * In normal circumnstances, this advances at the same rate as the clock
     * time, and measures the passing of time from the engine point of view
     * (which might or might not be the same as the time in the game world).
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
    private EventHandlerEntry[] _eventHandlers;
}
