/**
 * The engine (as in "game engine", though this may not qualify as a real one).
 *
 * License: MIT License, see the `LICENSE` file.
 *
 * Authors: Leandro Motta Barros.
 *
 * TODO: Add `@nogc`, `nothrow` and friends. Or maybe just templatize
 *     everything.
 */

module sbxs.engine.engine;

import sbxs.engine.backend;
import sbxs.engine.display;
import sbxs.engine.events;


/**
 * A game engine (if we can call it so).
 *
 * Unlike many implementations of game engines we have nowadays, this
 * is not a singleton. I don't know why one would want to have multiple
 * instances of an `Engine`, but I am not here to prohibit this.
 *
 * Now, depending on the back end used, it may not be legal to create
 * multiple instances of the engine. In this case, feel free to
 * encapsulate and instance of `Engine` into a singleton. Likewise, if
 * you want the convenience of global access to the engine, go ahead and
 * create a singleton-like encapsulation for your project.
 *
 * Concerning thread safety: it's probably a good idea to make all calls to
 * `Engine` methods from the same thread. Some things may work when called
 * from other threads, but better safe than sorry.
 *
 * Parameters:
 *     BE = The back end providing the lower-level stuff to the engine.
 */
public struct Engine(BE)
{
    import sbxs.containers.nc_array: NCArray;

    // `Engine`s cannot be copied.
    @disable this(this);

    //
    // General stuff
    //

    /// The back end.
    private BE _backend;

    /**
     * Initializes the engine. This must be called before using the `Engine`.
     *
     * See_also: `shutdown()`
     */
    public void initialize()
    {
        _backend.initialize();
    }

    /**
     * Shuts the engine down. This must be called before exiting your
     * program. `scope (exit)` is your friend. After calling this, you
     * should not use the engine anymore.
     *
     * See_also: `initialize()`
     */
    public void shutdown()
    {
        _displays.clear();
        _backend.shutdown();
    }


    //
    // Core subsystem
    //

    /**
     * Returns the current time, as the number of seconds passed since the
     * program started running.
     *
     * Returns: The number of seconds elapsed since the program started
     *     running.
     */
    public double getTime() { return _backend.core.getTime(); }

    /**
     * Makes the calling thread to sleep for a given time.
     *
     * Parameters:
     *     timeInSecs = The amount of time to sleep, in seconds.
     */
    public void sleep(double timeInSecs) { _backend.core.sleep(timeInSecs); }


    //
    // Events subsystem
    //

    static if (implementsEventsBE!BE)
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


    //
    // Display subsystem
    //

    static if (implementsDisplayBE!BE)
    {
        // xxxxxxxxxxxxxx TODO: Doc me!
        public alias Display = _backend.display.Display;

        /**
         * Reserve in the internal data structures enough memory for storing
         * `numDisplays` Displays.
         *
         * You must call this before calling `createDisplay()` if you intend to
         * create more than one Display.
         *
         * TODO: This shouldn't be necessary, ideally. At least, I should
         *     document why is needed (because reallocation would invalidate
         *     pointers to Displays).
         */
        public void reserveDisplays(size_t numDisplays)
        {
            _displays.reserve(numDisplays);
        }

        /// Creates and returns a Display.
        public Display* createDisplay(DisplayParams dp)
        {
            if (_displays.capacity == 0)
                _displays.reserve(1);

            // xxxxxxxxxxx TODO: Is this `assert()` correct?!
            assert(_displays.capacity > _displays.length,
                "Call `reserveDisplays` if you want to create more than one Display.");

            _backend.display.createDisplay(dp, _displays);
            return &_displays.back();
        }

        /// Swap the buffers of all Displays.
        private void swapAllBuffers()
        {
            foreach (ref display; _displays)
                display.swapBuffers();
        }

        /// The Displays managed by this back end.
        private NCArray!Display _displays;
    }
}
