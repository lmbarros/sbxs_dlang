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
        public double deltaTimeInSecs;

        /// Time elapsed since the program started to run, in seconds.
        public double tickTimeInSecs;
    }


    /// Back end Events subsystem, based on the SDL 2 library.
    public struct SDL2EventsBE
    {
        /// Initializes the subsystem.
        public void initialize()
        {
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

        /// Enqueues a tick event.
        public void enqueueTickEvent(double deltaTimeInSecs, double tickTimeInSecs)
        {
            import core.stdc.string: memset;

            SDL_Event tickEvent;
            memset(&tickEvent, SDL_Event.sizeof, 0);
            _tickEventData.deltaTimeInSecs = deltaTimeInSecs;
            _tickEventData.tickTimeInSecs = tickTimeInSecs;
            tickEvent.type = eventTypeTick;
            tickEvent.user.data1 = _tickEventData;
            const rc = SDL_PushEvent(&tickEvent);
            if (rc != 1)
            {
                // TODO: Do what on error? abort? log only?
            }
        }

        /**
         * Removes and returns an event from the event queue, if available.
         *
         * Parameters:
         *    event = In available, the event will be stored here. `null` is
         *    not acceptable.
         *
         * Returns:
         *    `true` if an event was available; `false` otherwise.
         */
        public bool dequeueEvent(Event* event)
        in
        {
            assert(event !is null);
        }
        body
        {
            SDL_Event sdlEvent;
            const gotEvent = SDL_PollEvent(&sdlEvent) == 1;
            if (gotEvent)
                *event = Event(sdlEvent);
            return gotEvent;
        }

        /// Key codes; they are codes that represent keyboard keys, you know.
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

        /**
         * An event.
         *
         * Wraps an `SDL_Event`, providing the interface expected by the
         * engine.
         */
        public struct Event
        {
            /// Constructs the `Event` from an `SDL_Event`.
            private this(const ref SDL_Event event)
            {
                this._event = event;
            }

            /// The wrapped `SDL_Event`.
            private SDL_Event _event;

            //
            // Common
            //

            public @property EventType type() const nothrow @nogc
            {
                //if (_event.type == eventTypeTick)
                    //return EventType.tick;
                //else if (_event.type == eventTypeTick)
                switch (_event.type)
                {
                    case eventTypeTick: return EventType.tick;
                    case SDL_KEYUP: return EventType.keyUp;
                    default: return EventType.unknown;
                }
            }

            // xxxxxxxxxxxxx TODO: Doc me (er, make it same first!)
            public @property double tickTime() const nothrow @nogc
            {
                assert(_event.common.type == eventTypeTick); // xxxxxx && user.code == bla
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
         * Data passed to tick events. Since at any moment we have at
         * most one single tick event in the SDL event queue, we can use
         * this single instance.
         *
         * BTW, this a pointer pointing to `malloc`ed memory (instead of
         * a regular member) just because I don't want to have this data
         * being handled by the garbage collector. My fear is that some
         * future implementation of the garbage collector may move data
         * around the memory (and SDL-managed structures would still
         * point to the old, noe incorrect address).
         */
        private TickEventData* _tickEventData;

        /// The number of SDL event types to reserve for the engine.
        private enum numUserEvents = 8;

        /// The ID of the first SDL event type allocated for the engine.
        private Uint32 firstUserEventType;

        /// Event type used for tick events.
        public static Uint32 eventTypeTick;

        /// Event type used for app state events.
        public static Uint32 eventTypeAppState;
    }

    static assert(isEventsBE!SDL2EventsBE);

} // version HasSDL2
