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


    /// Data associated with draw events.
    private struct DrawEventData
    {
        /// Time elapsed since the last draw event, in seconds.
        public double deltaTimeInSecs;

        /// Time elapsed since the program started to run, in seconds.
        public double drawingTimeInSecs;

        /// Time elapsed since the last tick event, in seconds.
        public double timeSinceTickInSecs;
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
            const firstUserEventType = SDL_RegisterEvents(numUserEvents);
            if (firstUserEventType == Uint32.max)
            {
                throw new BackendInitializationException(
                    "Error allocating event types for the engine.");
            }

            sdlEventTypeTick = firstUserEventType;
            sdlEventTypeDraw = firstUserEventType + 1;
            sdlEventTypeAppState = firstUserEventType + 2;

            // Allocate memory for `_tickEventData`
            import core.stdc.stdlib: malloc;
            _tickEventData = cast(TickEventData*)malloc(TickEventData.sizeof);
            if (_tickEventData is null)
            {
                throw new BackendInitializationException(
                    "Error allocating memory for tick event data.");
            }

            // Allocate memory for `_drawEventData`
            _drawEventData = cast(DrawEventData*)malloc(DrawEventData.sizeof);
            if (_drawEventData is null)
            {
                throw new BackendInitializationException(
                    "Error allocating memory for draw event data.");
            }
        }

        /// Shuts the subsystem down.
        public void shutdown() nothrow @nogc
        {
            // Free the `_tickEventData` memory
            import core.stdc.stdlib: free;
            free(_tickEventData);

            // Free the `_drawEventData` memory
            free(_drawEventData);

            // Shut down the SDL events subsystem
            SDL_QuitSubSystem(SDL_INIT_EVENTS);
        }

        /**
         * Creates and returns one of these SDL events used internally by the
         * engine.
         *
         * Parameters:
         *     eventType = The type of event to create.
         *     data = The data that will be assigned to `user.data1`.
         *
         * Returns: The created event.
         */
        private SDL_Event makeSDLEvent(Uint32 eventType, void* data) nothrow @nogc
        {
            import core.stdc.string: memset;

            SDL_Event event;
            memset(&event, SDL_Event.sizeof, 0);
            event.type = eventType;
            event.user.data1 = data;
            return event;
        }

        /**
         * Enqueues a tick event.
         *
         * Parameters:
         *     deltaTimeInSecs = Time elapsed since last tick event, in seconds.
         *     tickTimeInSecs = Tick time elapsed since tghe program started to
         *         run, in seconds.
         */
        public void enqueueTickEvent(double deltaTimeInSecs, double tickTimeInSecs) nothrow @nogc
        {
            _tickEventData.deltaTimeInSecs = deltaTimeInSecs;
            _tickEventData.tickTimeInSecs = tickTimeInSecs;
            auto tickEvent = makeSDLEvent(sdlEventTypeTick, _tickEventData);
            const rc = SDL_PushEvent(&tickEvent);
            if (rc != 1)
            {
                // TODO: Do what on error? abort? log only?
            }
        }

        /**
         * Creates and returns a draw event.
         *
         * Parameters:
         *     deltaTimeInSecs = The time elapsed, since the last draw event,
         *         in seconds.
         *     drawingTimeInSecs = The current drawing time, measured in seconds
         *         since the program started to run.
         *     timeSinceTickInSecs = The time elapsed since the lastest tick
         *         event, in seconds.
         *
         * Returns: A draw event.
         */
        public Event makeDrawEvent(double deltaTimeInSecs, double drawingTimeInSecs,
                                   double timeSinceTickInSecs) nothrow @nogc
        {
            _drawEventData.deltaTimeInSecs = deltaTimeInSecs;
            _drawEventData.drawingTimeInSecs = drawingTimeInSecs;
            _drawEventData.timeSinceTickInSecs = timeSinceTickInSecs;

            return Event(makeSDLEvent(sdlEventTypeDraw, _drawEventData));
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

        /**
         * An event.
         *
         * Wraps an `SDL_Event`, providing the interface expected by the
         * engine.
         */
        public struct Event
        {
            /// Constructs the `Event` from an `SDL_Event`.
            private this(const SDL_Event event) @nogc nothrow
            {
                this._event = event;
            }

            /// The wrapped `SDL_Event`.
            private SDL_Event _event;

            /// Returns the event type.
            public @property EventType type() const nothrow @nogc
            {
                switch (_event.type)
                {
                    case sdlEventTypeDraw: return EventType.draw;
                    case sdlEventTypeTick: return EventType.tick;
                    case SDL_KEYUP: return EventType.keyUp;
                    case SDL_MOUSEMOTION: return EventType.mouseMove;
                    default: return EventType.unknown;
                }
            }

            /**
             * Returns the tick time, in seconds
             *
             * Valid for: `tick`.
             */
            public @property double tickTimeInSecs() const nothrow @nogc
            {
                assert(_event.common.type == sdlEventTypeTick);
                const pTED = cast(TickEventData*)_event.user.data1;
                return pTED.tickTimeInSecs;
            }

            /**
             * Returns the tick time elapsed since the previous `tick` event.
             *
             * Valid for: `tick`.
             */
            public @property double deltaTimeInSecs() const nothrow @nogc
            {
                assert(_event.common.type == sdlEventTypeTick);
                const pTED = cast(TickEventData*)_event.user.data1;
                return pTED.deltaTimeInSecs;
            }

            /**
             * Returns the `KeyCode` for the key generating the event.
             *
             * Valid for: `keyUp`.
             */
            public @property KeyCode keyCode() const nothrow @nogc
            {
                assert(_event.common.type == SDL_KEYUP);
                return cast(KeyCode)(_event.key.keysym.sym);
            }

            /**
             * Returns the horizontal coordinate of the mouse, in pixels.
             *
             * Zero is the left side of the Display.
             *
             * Valid for: `mouseMove`.
             */
            public @property int mouseX() const nothrow @nogc
            {
                assert(_event.common.type == SDL_MOUSEMOTION);
                return _event.motion.x;
            }

            /**
             * Returns the vertical coordinate of the mouse, in pixels.
             *
             * Zero is the top side of the Display.
             *
             * Valid for: `mouseMove`.
             */
            public @property int mouseY() const nothrow @nogc
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

        /**
         * Data passed to draw events. Everything said about `_tickEventData`
         * holds here, too.
         */
        private DrawEventData* _drawEventData;

        /// The number of SDL event types to reserve for the engine.
        private enum numUserEvents = 8;

        /// Event type used for tick events.
        public static Uint32 sdlEventTypeTick;

        /// Event type used for draw events.
        public static Uint32 sdlEventTypeDraw;

        /// Event type used for app state events.
        public static Uint32 sdlEventTypeAppState;

        /**
         * Key codes.
         *
         * These are codes that represent keyboard keys, you know.
         *
         * Overall, names here tend to be a bit PC-centric, as this is what I
         * use. No big deal, I guess.
         *
         * `_0` through `_1` represent the number keys from 0 to 1 in the main
         * section of the keyboard (usually right under the function keys).
         * Keys on the numeric key pad are prefixed by `kp`.
         *
         * `_return` is the "Return" key on the main section of the keyboard;
         * `kpEnter` is the one on the numeric keypad.
         */
        public enum KeyCode: SDL_Keycode
        {
            q = SDLK_q,  w = SDLK_w,  e = SDLK_e,  r = SDLK_r,
            t = SDLK_t,  y = SDLK_y,  u = SDLK_u,  i = SDLK_i,
            o = SDLK_o,  p = SDLK_p,  a = SDLK_a,  s = SDLK_s,
            d = SDLK_d,  f = SDLK_f,  g = SDLK_g,  h = SDLK_h,
            j = SDLK_j,  k = SDLK_k,  l = SDLK_l,  z = SDLK_z,
            x = SDLK_x,  c = SDLK_c,  v = SDLK_v,  b = SDLK_b,
            n = SDLK_n,  m = SDLK_m,

            _1 = SDLK_1,  _2 = SDLK_2,  _3 = SDLK_3,  _4 = SDLK_4,
            _5 = SDLK_5,  _6 = SDLK_6,  _7 = SDLK_7,  _8 = SDLK_8,
            _9 = SDLK_9,  _0 = SDLK_0,

            f1 = SDLK_F1,  f2 = SDLK_F2,    f3 = SDLK_F3,    f4 = SDLK_F4,
            f5 = SDLK_F5,  f6 = SDLK_F6,    f7 = SDLK_F7,    f8 = SDLK_F8,
            f9 = SDLK_F9,  f10 = SDLK_F10,  f11 = SDLK_F11,  f12 = SDLK_F12,

            left = SDLK_LEFT,  right = SDLK_RIGHT,  up = SDLK_UP,  down = SDLK_DOWN,

            lShift = SDLK_LSHIFT,   rShift = SDLK_LSHIFT,
            lCtrl = SDLK_LCTRL,     rCtrl = SDLK_RCTRL,
            lWin = SDLK_LGUI,       rWin = SDLK_RGUI,
            lAlt = SDLK_LALT,       rAlt = SDLK_RALT,
            menu = SDLK_MENU,

            space = SDLK_SPACE,          _return = SDLK_RETURN,
            escape = SDLK_ESCAPE,        tab = SDLK_TAB,
            backspace = SDLK_BACKSPACE,

            printScreen = SDLK_PRINTSCREEN,    scrollLock = SDLK_SCROLLLOCK,
            pause = SDLK_PAUSE,                capsLock = SDLK_CAPSLOCK,

            backquote = SDLK_BACKQUOTE,      minus = SDLK_MINUS,
            equals = SDLK_EQUALS,            backslash = SDLK_BACKSLASH,
            openBracket = SDLK_LEFTBRACKET,  closeBracket = SDLK_RIGHTBRACKET,
            openParen = SDLK_LEFTPAREN,      closeParen = SDLK_RIGHTPAREN,
            semicolon = SDLK_SEMICOLON,      quote = SDLK_QUOTE,
            comma = SDLK_COMMA,              period = SDLK_PERIOD,
            slash = SDLK_SLASH,

            home = SDLK_HOME,       end = SDLK_END,
            pageUp = SDLK_PAGEUP,   pageDown = SDLK_PAGEDOWN,

            numLock = SDLK_NUMLOCKCLEAR,

            kp0 = SDLK_KP_0,  kp1 = SDLK_KP_1,  kp2 = SDLK_KP_2,  kp3 = SDLK_KP_3,
            kp4 = SDLK_KP_4,  kp5 = SDLK_KP_5,  kp6 = SDLK_KP_6,  kp7 = SDLK_KP_7,
            kp8 = SDLK_KP_8,  kp9 = SDLK_KP_9,

            kpDivide = SDLK_KP_DIVIDE,  kpMultiply = SDLK_KP_MULTIPLY,
            kpMinus = SDLK_KP_MINUS,    kpPlus = SDLK_KP_PLUS,
            kpPeriod = SDLK_KP_PERIOD,  kpComma = SDLK_KP_COMMA,
            kpEnter = SDLK_KP_ENTER,
        }
    }

    static assert(isEventsBE!SDL2EventsBE);

} // version HasSDL2
