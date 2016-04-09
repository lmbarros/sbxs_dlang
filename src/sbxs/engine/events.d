/**
 * Definitions related with events and event handling.
 *
 * License: MIT License, see the `LICENSE` file.
 *
 * Authors: Leandro Motta Barros.
 */

module sbxs.engine.events;

import std.traits: hasMember;


/// The possible types of events.
public enum EventType
{
    /// The clock ticked. Kinda like the heartbeat of the engine.
    tick,

    /**
     * The screen shall b e redrawn; all drawing shall happen in response to
     * `draw` events.
     */
    draw,

    /// A keyboard key was pressed.
    keyDown,

    /// A keyboard key was released.
    keyUp,

    /// The mouse pointer has moved.
    mouseMove,

    /// A mouse button was pressed.
    mouseDown,

    /// A mouse button was released.
    mouseUp,

    /// The mouse wheel was rolled up.
    mouseWheelUp,

    /// The mouse wheel was rolled down.
    mouseWheelDown,

    /// A Display was resized.
    displayResize,

    /// A Display (or part of it) was exposed and should be redrawn.
    displayExpose,

    /// An app state event; used internally by the engine, don't mess with it.
    appState,

    /// An event type that is unknown to the engine.
    unknown,
}


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
    private alias Event = E.backendType.events.Event;

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
     * Note: The `event` passed is not `const` because many of its interesting
     *     methods are not `const` (due to constrains imposed by the back end
     *     APIs). Anyway, there shouldn't be anything harmful one could do by
     *     calling mutable methods of an Event.
     *
     * TODO: Think about the semantics of the return value. Does the
     *     description above make sense? Is it useful?
     */
    public alias EventHandler = bool delegate(Event* event);

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
     * Returns: `true` if any of the registered evnt handlers returned `true`;
     *     `false` otherwise.
     *
     * Parameters:
     *     event = The event to be handled.
     */
    private bool callEventHandlers(Event* event)
    {
        auto eventAlreadyHandled = false;

        // Give global event handlers a chance to handle the event
        foreach (handlerEntry; _handlers)
        {
            if (handlerEntry.handler(event))
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
        _engine.backend.events.enqueueTickEvent(deltaTimeInSecs, _tickTimeInSecs);

        // Handle events
        auto event = Event(_engine);

        while (_engine.backend.events.dequeueEvent(&event))
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
                callEventHandlers(&event);
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
     *     timeSinceTickInSecs = The tick time, in seconds, elapsed since the
     *         last tick event..
     */
    public void draw(double timeSinceTickInSecs)
    {
        // TODO: Implement app states!
        // Return immediately if we are out of 'AppState's. (This happens when
        // exiting the program.)
        //if (numAppStates == 0)
        //    return;

        // Compute the new drawing time
        const newDrawingTimeInSecs = _tickTimeInSecs + timeSinceTickInSecs;
        const deltaDrawingTimeInSecs = newDrawingTimeInSecs - _drawingTimeInSecs;
        assert(deltaDrawingTimeInSecs >= 0.0, "Drawing time cannot flow backward");

        // Call event handlers so that they can perform the drawing
        auto drawEvent = _engine.backend.events.makeDrawEvent(
            newDrawingTimeInSecs, timeSinceTickInSecs);

        callEventHandlers(&drawEvent);

        // Update the drawing time
        _drawingTimeInSecs = newDrawingTimeInSecs;

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



// -----------------------------------------------------------------------------
// Unit tests
// -----------------------------------------------------------------------------

// Simple event handling test.
unittest
{
    import sbxs.engine;
    import sbxs.engine.backends.mocked;

    Engine!MockedBackend engine;
    engine.initialize();

    alias Event = typeof(engine).Event;

    // Add an event handler
    bool handlerRan = false;

    engine.events.addHandler(
        delegate(Event* event) { handlerRan = true; return true; },
        0);

    assert(handlerRan == false); // sanity check

    // Call handlers
    auto event = engine.backend.events.makeTickEvent(0.2, 0.4);
    engine.events.callEventHandlers(&event);
    assert(handlerRan == true);
}


// Checks if `callEventHandlers()` returns the expected value.
unittest
{
    import sbxs.engine;
    import sbxs.engine.backends.mocked;

    Engine!MockedBackend engine;
    engine.initialize();

    alias Event = typeof(engine).Event;

    // First, with a single event handler that returns `false`
    auto event = engine.backend.events.makeTickEvent(0.2, 0.4);

    engine.events.addHandler((Event* event) => false, 0);
    assert(engine.events.callEventHandlers(&event) == false);

    // Then, with a second event handler, which returns `true`
    engine.events.addHandler((Event* event) => true, 0);
    assert(engine.events.callEventHandlers(&event) == true);
}


// Checks if multiple event handlers are called in the correct, priority-based order.
unittest
{
    import sbxs.engine;
    import sbxs.engine.backends.mocked;

    Engine!MockedBackend engine;
    engine.initialize();

    alias Event = typeof(engine).Event;

    bool firstRan = false;
    bool secondRan = false;
    bool thirdRan = false;

    auto event = engine.backend.events.makeTickEvent(0.2, 0.4);

    // Add handler with priority 2; will hopefully be the second to be called
    engine.events.addHandler(
        delegate(Event* event)
        {
            assert(firstRan == true);
            assert(secondRan == false);
            assert(thirdRan == false);
            secondRan = true;

            return false; // so that others have the chance to be called
        },
        2
    );

    // Add handler with priority 1; will hopefully be the first to be called
    engine.events.addHandler(
        delegate(Event* event)
        {
            assert(firstRan == false);
            assert(secondRan == false);
            assert(thirdRan == false);
            firstRan = true;

            return false; // so that others have the chance to be called
        },
        1
    );

    // Add handler with priority 3; will hopefully be the third to be called
    engine.events.addHandler(
        delegate(Event* event)
        {
            assert(firstRan == true);
            assert(secondRan == true);
            assert(thirdRan == false);
            thirdRan = true;

            return false; // so that others have the chance to be called
        },
        3
    );

    // Call handlers
    engine.events.callEventHandlers(&event);

    // Just in case, check all of them were called
    assert(firstRan == true);
    assert(secondRan == true);
    assert(thirdRan == true);
}


// Checks if a handler returning `true` precludes other handlers to be called. Also
// tests `removeHandler()`.
unittest
{
    import sbxs.engine;
    import sbxs.engine.backends.mocked;

    Engine!MockedBackend engine;
    engine.initialize();

    alias Event = typeof(engine).Event;

    bool firstRan = false;
    bool secondRan = false;

    auto event = engine.backend.events.makeTickEvent(0.2, 0.4);

    // First handler, returns `true`.
    auto firstHandler = delegate(Event* event)
                        {
                            firstRan = true;
                            return true; // preclude subsequent handlers to run
                        };

    engine.events.addHandler(firstHandler, 1);

    // Second handler, also returns `true` (but this doesn't matter)
    engine.events.addHandler(
        delegate(Event* event)
        {
            secondRan = true;
            return true;
        },
        2
    );

    // Call handlers, just the first one shall be actually called
    engine.events.callEventHandlers(&event);

    assert(firstRan == true);
    assert(secondRan == false);

    // Remove the first handler, call handlers again
    assert(engine.events.removeHandler(firstHandler) == true);

    engine.events.callEventHandlers(&event);

    assert(secondRan == true);
}


// Tests `tick()` generates a Tick event
unittest
{
    import sbxs.engine;
    import sbxs.engine.backends.mocked;

    Engine!MockedBackend engine;
    engine.initialize();

    alias Event = typeof(engine).Event;

    int numTicks = 0;

    engine.events.addHandler(
        delegate(Event* event)
        {
            if (event.type == EventType.tick)
                ++numTicks;

            return false;
        },
        1
    );

    // Initially, no ticks
    assert(numTicks == 0);

    // Call `tick()`, check if our handler was called as expected
    engine.events.tick(0.1);
    assert(numTicks == 1);

    engine.events.tick(0.1);
    engine.events.tick(0.1);
    engine.events.tick(0.1);
    assert(numTicks == 4);
}


// Tests `tick()` calls the event handlers for the enqueued input events.
unittest
{
    import sbxs.engine;
    import sbxs.engine.backends.mocked;

    Engine!MockedBackend engine;
    engine.initialize();

    alias Event = typeof(engine).Event;
    alias KeyCode = typeof(engine).KeyCode;

    int numTicks = 0;
    int numKeyUps = 0;
    int numWheelUps = 0;

    engine.events.addHandler(
        delegate(Event* event)
        {
            switch(event.type)
            {
                case EventType.tick: ++numTicks; break;
                case EventType.keyUp: ++numKeyUps; break;
                case EventType.mouseWheelUp: ++numWheelUps; break;
                default: break;
            }

            return false;
        },
        1
    );

    // Initially, no events
    assert(numTicks == 0);
    assert(numKeyUps == 0);
    assert(numWheelUps == 0);

    // Call `tick()`, without having enqueued any other event
    engine.events.tick(0.1);
    assert(numTicks == 1);
    assert(numWheelUps == 0);
    assert(numKeyUps == 0);

    // Simulate some input events, call `tick()` again
    enum fakeDisplayHandle = 1;

    engine.backend.events.mockedEventQueue ~= engine.backend.events.makeKeyUpEvent(
        KeyCode.a, fakeDisplayHandle);
    engine.backend.events.mockedEventQueue ~= engine.backend.events.makeKeyUpEvent(
        KeyCode.b, fakeDisplayHandle);
    engine.backend.events.mockedEventQueue ~= engine.backend.events.makeMouseWheelUpEvent(
        fakeDisplayHandle);

    engine.events.tick(0.1);
    assert(numTicks == 2);
    assert(numWheelUps == 1);
    assert(numKeyUps == 2);

    // Agaaaain, agaaaain
    engine.backend.events.mockedEventQueue ~= engine.backend.events.makeMouseWheelUpEvent(
        fakeDisplayHandle);
    engine.backend.events.mockedEventQueue ~= engine.backend.events.makeMouseWheelUpEvent(
        fakeDisplayHandle);
    engine.backend.events.mockedEventQueue ~= engine.backend.events.makeKeyUpEvent(
        KeyCode.a, fakeDisplayHandle);
    engine.backend.events.mockedEventQueue ~= engine.backend.events.makeMouseWheelUpEvent(
        fakeDisplayHandle);
    engine.backend.events.mockedEventQueue ~= engine.backend.events.makeKeyUpEvent(
        KeyCode.b, fakeDisplayHandle);

    engine.events.tick(0.1);
    assert(numTicks == 3);
    assert(numWheelUps == 4);
    assert(numKeyUps == 4);

    // Here we are ready with the test itself. Let's just force the execution
    // of the event handler once more, with an event type different than those
    // we are explicitly handling. Why? Just to exercise that `default`
    // `switch` case in the evenr handler, in order to get 100% coverage.
    engine.events.draw(0.1);
}


// Tests if `tick()` makes the time pass.
unittest
{
    import sbxs.engine;
    import sbxs.engine.backends.mocked;

    Engine!MockedBackend engine;
    engine.initialize();

    alias Event = typeof(engine).Event;

    int numTicks = 0;

    engine.events.addHandler(
        delegate(Event* event)
        {
            if (numTicks == 0)
                assert(event.tickTimeInSecs == 1.0);
            else if (numTicks == 1)
                assert(event.tickTimeInSecs == 2.0);
            else if (numTicks == 2)
                assert(event.tickTimeInSecs == 5.0);
            else if (numTicks == 3)
                assert(event.tickTimeInSecs == 7.0);

            ++numTicks;
            return false;
        },
        1
    );

    // Call `tick()`, passing delta times of 1, 1, 3, and 2 seconds
    engine.events.tick(1.0);
    engine.events.tick(1.0);
    engine.events.tick(3.0);
    engine.events.tick(2.0);
}


// Tests if `draw()` generates calls Draw event handlers.
unittest
{
    import sbxs.engine;
    import sbxs.engine.backends.mocked;

    Engine!MockedBackend engine;
    engine.initialize();

    alias Event = typeof(engine).Event;

    int numDraws = 0;

    engine.events.addHandler(
        delegate(Event* event)
        {
            if (event.type == EventType.draw)
                ++numDraws;

            return false;
        },
        1
    );

    // Initially, no draws
    assert(numDraws == 0);

    // Call `draw()`, check if our handler was called as expected
    engine.events.draw(0.1);
    assert(numDraws == 1);

    engine.events.draw(0.1);
    engine.events.draw(0.1);
    engine.events.draw(0.1);
    assert(numDraws == 4);
}


// Tests if `draw()` advances the time as expected.
unittest
{
    import sbxs.engine;
    import sbxs.engine.backends.mocked;

    Engine!MockedBackend engine;
    engine.initialize();

    alias Event = typeof(engine).Event;

    int numDraws = 0;

    engine.events.addHandler(
        delegate(Event* event)
        {
            if (event.type != EventType.draw)
                return false;

            if (numDraws == 0)
            {
                assert(event.drawingTimeInSecs == 2.0);
                assert(event.timeSinceTickInSecs == 1.0);
            }
            else if (numDraws == 1)
            {
                assert(event.drawingTimeInSecs == 4.0);
                assert(event.timeSinceTickInSecs == 3.0);
            }
            else if (numDraws == 2)
            {
                assert(event.drawingTimeInSecs == 6.0);
                assert(event.timeSinceTickInSecs == 0.0);
            }

            ++numDraws;

            return false;
        },
        1
    );

    // Call `draw()` and `tick()`, passing interesting delta times, as in the
    // diagram below. An "o" is a call to either `draw()` or `tick()`. Double
    // lines ("===") indicate where the tick time is advancing in response to a
    // call to `tick()`, or where the drawing time is advancing in response to
    // a call to `draw()`. A single line ("---") shows where the drawing time
    // advanced in reponse to a `tick()` call (ticks always resinchronize the
    // tick and draw times). An "O" marks a point just after `tick()` or
    // `draw()` was called.
    //
    //        0   1   2   3   4   5   6
    //        |   |   |   |   |   |   |
    // tick   +===O===+===+===+===+===O
    //        |   |   |   |   |   |   |
    // draw   +---+===O===+===O---+---O
    //        |   |   |   |   |   |   |

    assert(numDraws == 0);

    engine.events.tick(1.0);
    engine.events.draw(1.0);
    assert(numDraws == 1);

    engine.events.draw(3.0);
    assert(numDraws == 2);

    engine.events.tick(5.0);
    engine.events.draw(0.0);
    assert(numDraws == 3);
}


// Tests if `draw()` swaps buffers for all Displays.
unittest
{
    import sbxs.engine;
    import sbxs.engine.backends.mocked;

    Engine!MockedBackend engine;
    engine.initialize();

    // Create two Displays
    DisplayParams params;

    auto display1 = engine.display.create(params);
    auto display2 = engine.display.create(params);

    assert(display1.swapBuffersCount == 0);
    assert(display2.swapBuffersCount == 0);

    // Check if `draw()` swaps their buffers
    engine.events.draw(0.1);

    assert(display1.swapBuffersCount == 1);
    assert(display2.swapBuffersCount == 1);

    engine.events.draw(0.1);
    engine.events.draw(0.1);

    assert(display1.swapBuffersCount == 3);
    assert(display2.swapBuffersCount == 3);

    // Create a third Display
    auto display3 = engine.display.create(params);

    assert(display1.swapBuffersCount == 3);
    assert(display2.swapBuffersCount == 3);
    assert(display3.swapBuffersCount == 0);

    // Draw more
    engine.events.draw(0.1);
    engine.events.draw(0.1);
    engine.events.draw(0.1);

    assert(display1.swapBuffersCount == 6);
    assert(display2.swapBuffersCount == 6);
    assert(display3.swapBuffersCount == 3);
}
