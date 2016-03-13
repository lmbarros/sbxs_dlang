/**
 * SDL 2 back end: Events subsystem.
 *
 * License: MIT License, see the `LICENSE` file.
 *
 * Authors: Leandro Motta Barros.
 */

module sbxs.engine.backends.sdl2.events;

version(HasSDL2)
{

    import derelict.sdl2.sdl;
    import sbxs.engine.backend;
    import sbxs.engine.events;
    import sbxs.engine.backends.sdl2.helpers;


    /// Data associated with tick events.
    private struct TickEventData
    {
        /// Time elapsed since the last tick event, in seconds.
        public double deltaTime;

        /// Time elapsed since the program started to run, in seconds.
        public double tickTime;
    }


    /**
     * Back end Events subsystem, based on the SDL 2 library.
     *
     * Parameters:
     *     BE = The back end type (the complete one, in contrast to a back end
     *         subsystem, like Events or Display).
     */
    public struct SDL2EventsBE(BE)
    {
        /// Initializes the subsystem.
        public void initialize(BE* backend)
        {
            _backend = backend;

            // Initialize the SDL events subsystem
            // TODO: SDL_INIT_JOYSTICK? SDL_INIT_GAMECONTROLLER? (Update `shutdown()` accordingly!)
            if (SDL_InitSubSystem(SDL_INIT_EVENTS) < 0)
                throw new BackendInitializationException(sdlGetError());

            // Register custom events
            firstUserEventType = SDL_RegisterEvents(numUserEvents);
            if (firstUserEventType == Uint32.max)
            {
                throw new BackendInitializationException(
                    "Error allocating event types for the engine.");
            }

            eventTypeTick = firstUserEventType;
            eventTypeAppState = firstUserEventType + 1;

            // Allocate memory for `_tickEventData`
            import core.stdc.stdlib: malloc;
            _tickEventData = cast(TickEventData*)malloc(TickEventData.sizeof);
            if (_tickEventData is null)
            {
                throw new BackendInitializationException(
                    "Error allocating memory for tick event data.");
            }
        }

        /// Shuts the subsystem down.
        public void shutdown() nothrow @nogc
        {
            // Free the `_tickEventData` memory
            import core.stdc.stdlib: free;
            free(_tickEventData);

            // Shut down the SDL events subsystem
            SDL_QuitSubSystem(SDL_INIT_EVENTS);
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
        *     deltaTime = The tick time, in seconds, elapsed since the last
        *         time this function was called.
        */
        public void tick(double deltaTime)
        {
            // Update tick time, re-sync drawing time with it
            _tickTime += deltaTime;
            _drawingTime = _tickTime;

            // Put a tick event on the event queue
            import core.stdc.string: memset;

            SDL_Event tickEvent;
            memset(&tickEvent, SDL_Event.sizeof, 0);
            _tickEventData.deltaTime = deltaTime;
            _tickEventData.tickTime = _tickTime;
            tickEvent.type = eventTypeTick;
            tickEvent.user.data1 = _tickEventData;
            const rc = SDL_PushEvent(&tickEvent);
            if (rc != 1)
            {
                // TODO: do what on error? abort? log only?
            }

            // Handle other events
            SDL_Event event;
            while (SDL_PollEvent(&event) != 0)
            {
                if (event.type == eventTypeAppState)
                {
                    // App State events are handled here
                    // TODO: Implement me!
                    // handleAppStateEvent(event); // xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
                }
                else
                {
                    // Give global event handlers a chance to handle the event
                    foreach (handlerEntry; _eventHandlers)
                    {
                        // xxxxxxxxxxxxxxxxx TODO: If event is handled here, do not even try to handle in app states
                        auto e = Event(&event);
                        if (handlerEntry.handler(&e))
                            break;
                    }

                    //// Let 'AppState'-specific event handlers handle the event
                    //if (numAppStates > 0 && _appStates.back.handle(event))
                    //    break;
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
         *     deltaTime = The tick time, in seconds, elapsed since the last
         *         time this function was called.
         */
        public void draw(double deltaTime)
        {
            /*
            // Return immediately if we are out of 'AppState's. (This happens when
            // exiting the program.)
            if (numAppStates == 0)
                return;
            */

            // Update the drawing time
            _drawingTime += deltaTime;

            /*
            // Call draw() on the current App State
            const timeSinceTick = _drawingTime - _tickTime;
            _appStates.back.onDraw(deltaTime, _drawingTime, timeSinceTick);
            */

            // And flip the buffers
            static if (implementsDisplayBE!BE)
            {
                _backend.display.swapAllBuffers();
            }
        }

        public enum KeyCode: SDL_Keycode
        {
            Escape = SDLK_ESCAPE,
            Return = SDLK_RETURN,
            Space = SDLK_SPACE,
            F1 = SDLK_F1,
            A = SDLK_a,
            N1 = SDLK_1,
            NumLock = SDLK_NUMLOCKCLEAR,
            KPEnter = SDLK_KP_ENTER,
        }

        public struct Event
        {
            private this(const SDL_Event* event)
            {
                this._event = event;
                if (_event.type == SDL_KEYUP)
                    this.type = EventType.keyUp;
            }
            //
            // Common
            //

            private const SDL_Event* _event;

            public EventType type;

            public @property double tickTime() const nothrow @nogc
            {
                assert(_event.common.type == SDL_USEREVENT); // xxxxxx && user.code == bla
                return _event.user.code; // xxxxxxxxxxxxxxxxxx
            }

            //
            // Tick
            //

            public @property double tickDeltaTime() const nothrow @nogc
            {
                assert(_event.common.type == SDL_USEREVENT); // xxxxxx && user.code == bla
                return _event.user.code; // xxxxxxxxxxxxxxxx
            }


            //
            // KeyUp
            //
            public @property KeyCode keyUpKeyCode() const nothrow @nogc
            {
                assert(_event.common.type == SDL_KEYUP);
                return cast(KeyCode)(_event.key.keysym.sym);
            }

            //
            // MouseMove
            //
            public @property int mouseMoveX() const nothrow @nogc
            {
                assert(_event.common.type == SDL_MOUSEMOTION);
                return _event.motion.x;
            }

            public @property int mouseMoveY() const nothrow @nogc
            {
                assert(_event.common.type == SDL_MOUSEMOTION);
                return _event.motion.y;
            }
        }


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
        private alias eventHandler = bool delegate(const Event* event);

        /// An entry in the list of registered event handlers.
        private struct eventHandlerEntry
        {
            /// The event handler itself.
            public eventHandler handler;

            /// The priority. Smaller number means higher priority.
            public int prio;
        }

        /// The registered event handlers.
        private eventHandlerEntry[] _eventHandlers;

        /**
         * Register a given `EventHandler` with the Event subsystem, with a
         * given priority.
         *
         * Parameters:
         *     handler = The event handler to add. Not `null`, please.
         *     prio = The priority; lower numbers have higher priority. In
         *         other words, handlers with a lower `prio` will be called
         *          before handlers with higher `prio` values.
         */
        public final void addEventHandler(eventHandler handler, int prio)
        in
        {
            assert(handler !is null);
        }
        body
        {
            import std.algorithm: sort;
            _eventHandlers ~= eventHandlerEntry(handler, prio);
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
        public final bool removeEventHandler(eventHandler handler)
        {
            import std.algorithm: remove;

            const lenBefore = _eventHandlers.length;

            _eventHandlers = _eventHandlers.remove!(a => a.handler is handler)();

            return _eventHandlers.length < lenBefore;
        }

        /// A pointer to the back end.
        private BE* _backend;

        /**
         * Data passed to tick events. Since at any moment we have at
         * most one single tick event in the SDL event queue, we can use
         * this single instance.
         *
         * BTW, this a pointer (pointing to `malloc`ed memory) just
         * because I don't want to have this data being handled by the
         * garbage collector. My fear is that some future implementation
         * of the garbage collector may move data around the memory (and
         * SDL-managed structures would still point to the old, noe
         * incorrect address).
         */
        private TickEventData* _tickEventData;

        /**
         * The tick time. This is the number of seconds elapsed since an arbitrary
         * instant (the "epoch"), which gets updated whenever `triggerTickEvent()`
         * is called.
         */
        private double _tickTime = 0.0;

        /**
         * The drawing time, which is like the tick time (`_tickTime`), but may
         * get temporarily ahead of it, if multiple "draw" events happen between two
         * "tick" events.
         *
         * This is the number of seconds elapsed since an arbitrary instant (the
         * "epoch"). It gets updated whenever `triggerDrawEvent()` or
         * `triggerTickEvent()` is called.
         */
        private double _drawingTime = 0.0;

        /// The number of SDL event types to reserve for the engine.
        private enum numUserEvents = 8;

        /// The ID of the first SDL event type allocated for the engine.
        private Uint32 firstUserEventType;

        /// Event type used for tick events.
        public Uint32 eventTypeTick;

        /// Event type used for app state events.
        public Uint32 eventTypeAppState;
    }

    //static assert(isEventsBE!SDL2EventsBE);

} // version HasSDL2
