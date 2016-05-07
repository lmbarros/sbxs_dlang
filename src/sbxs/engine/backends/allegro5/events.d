/**
 * Engine events subsystem based on Allegro 5.
 *
 * License: MIT License, see the `LICENSE` file.
 *
 * Authors: Leandro Motta Barros.
 */

module sbxs.engine.backends.allegro5.events;

version(HaveAllegro5)
{
    import derelict.allegro5.allegro;
    import sbxs.engine;
    import sbxs.engine.backends.events_common;


    /**
     * Engine events subsystem based on the Allegro 5 library.
     *
     * Parameters:
     *     E = The type of the engine using this subsystem.
     */
    public struct Allegro5EventsSubsystem(E)
    {
        mixin EventsCommon!E;

        /**
         * Performs any further, back end-specific initialization of the
         * subsystem.
         *
         * This is called from `EventsCommon`, in a compile-time version of the
         * factory method design pattern.
         */
        package(sbxs.engine) void initializeBackend()
        {
            // Initialize the required Allegro subsystems
            if (!al_install_keyboard())
            {
                throw new BackendInitializationException(
                    "Error initializing the keyboard subsystem");
            }

            scope(failure)
                al_uninstall_keyboard();

            if (!al_install_mouse())
            {
                throw new BackendInitializationException(
                    "Error initializing the mouse subsystem");
            }

            scope(failure)
                al_uninstall_mouse();

            if (!al_install_joystick())
            {
                throw new BackendInitializationException(
                    "Error initializing the joystick subsystem");
            }

            scope(failure)
                al_uninstall_joystick();

            // Initialize the event queue
            _eventQueue = al_create_event_queue();
            if (_eventQueue is null)
            {
                throw new BackendInitializationException(
                    "Error creating event queue");
            }

            scope (failure)
                al_destroy_event_queue(_eventQueue);

            // Register the standard event sources
            al_register_event_source(_eventQueue, al_get_keyboard_event_source());
            scope (failure)
                al_unregister_event_source(_eventQueue, al_get_keyboard_event_source());

            al_register_event_source(_eventQueue, al_get_mouse_event_source());
            scope (failure)
                al_unregister_event_source(_eventQueue, al_get_mouse_event_source());

            al_register_event_source(_eventQueue, al_get_joystick_event_source());
            scope (failure)
                al_unregister_event_source(_eventQueue, al_get_joystick_event_source());

            // Initialize and register the user event source
            al_init_user_event_source(&_userEventSource);
            scope(failure)
                al_destroy_user_event_source(&_userEventSource);

            al_register_event_source(_eventQueue, &_userEventSource);
            scope(failure)
                al_unregister_event_source(_eventQueue, &_userEventSource);
        }

        /// Shuts the subsystem down.
        package(sbxs.engine) void shutdownBackend()
        {
            // Remove the event sources
            al_unregister_event_source(_eventQueue, al_get_joystick_event_source());
            al_unregister_event_source(_eventQueue, al_get_mouse_event_source());
            al_unregister_event_source(_eventQueue, al_get_keyboard_event_source());
            al_unregister_event_source(_eventQueue, &_userEventSource);

            // Destroy the other event-related objects
            al_destroy_event_queue(_eventQueue);
            al_destroy_user_event_source(&_userEventSource);

            // Shutdown the Allegro input subsystems
            al_uninstall_joystick();
            al_uninstall_mouse();
            al_uninstall_keyboard();
        }

        /**
         * Creates and returns one of these Allegro events used internally by
         * the engine.
         *
         * Parameters:
         *     eventType = The type of event to create.
         *     data = The data that will be assigned to `user.data1`.
         *
         * Returns: The created event.
         */
        private ALLEGRO_EVENT makeAllegroEvent(uint eventType, void* data)
        {
            import core.stdc.string: memset;
            import std.stdint: intptr_t;

            ALLEGRO_EVENT event;
            memset(&event, ALLEGRO_EVENT.sizeof, 0);
            event.type = eventType;
            event.user.data1 = cast(intptr_t)data;
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
        public void enqueueTickEvent(double deltaTimeInSecs, double tickTimeInSecs)
        {
            _tickEventData.deltaTimeInSecs = deltaTimeInSecs;
            _tickEventData.tickTimeInSecs = tickTimeInSecs;
            auto tickEvent = makeAllegroEvent(userEventTypeTick, &_tickEventData);
            const success = al_emit_user_event(&_userEventSource, &tickEvent, null);
            if (!success)
            {
                // TODO: Do what on error? Abort? Log only? Logging seems good.
            }
        }

        /**
         * Creates and returns a draw event.
         *
         * Parameters:
         *     drawingTimeInSecs = The current drawing time, measured in seconds
         *         since the program started to run.
         *     timeSinceTickInSecs = The time elapsed since the lastest tick
         *         event, in seconds.
         *
         * Returns: A draw event.
         */
        public Event makeDrawEvent(double drawingTimeInSecs, double timeSinceTickInSecs)
        {
            _drawEventData.drawingTimeInSecs = drawingTimeInSecs;
            _drawEventData.timeSinceTickInSecs = timeSinceTickInSecs;

            return Event(makeAllegroEvent(userEventTypeDraw, &_drawEventData), _engine);
        }

        /**
         * Removes and returns an event from the event queue, if available.
         *
         * Parameters:
         *     event = In available, the event will be stored here. `null` is
         *         not acceptable.
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
            ALLEGRO_EVENT allegroEvent;
            const gotEvent = al_get_next_event(_eventQueue, &allegroEvent);
            if (gotEvent)
                *event = Event(allegroEvent, _engine);
            return gotEvent;
        }

        /**
         * An event backed by Allegro 5.
         *
         * Wraps an `ALLEGRO_EVENT`, providing the interface expected by the
         * engine.
         */
        public struct Event
        {
            // Disable default constructor so that we can be surer that the
            // `_engine` member will be properly initialized.
            @disable this();

            /**
             * Constructs the `Event` from an Engine.
             *
             * Parameters:
             *     engine = The Engine where this event lives in.
             *
             */
            public this(E* engine) @nogc nothrow
            in
            {
                assert(engine !is null);
            }
            body
            {
                _engine = engine;
            }

            /**
             * Constructs the `Event` from an `ALLEGRO_EVENT` and Engine.
             *
             * Parameters:
             *     event = The ALLEGRO_EVENT event which will wrapped by this
             *         `Event`.
             *     engine = The Engine where the events lives in.
             */
            public this(ALLEGRO_EVENT event, E* engine) @nogc nothrow
            in
            {
                assert(engine !is null);
            }
            body
            {
                _event = event;
                _engine = engine;
            }

            /// The Engine where this Event lives in.
            private E* _engine;

            /// The wrapped `ALLEGRO_EVENT`.
            private ALLEGRO_EVENT _event;

            /// Returns the event type.
            public @property EventType type() const nothrow @nogc
            {
                switch (_event.type)
                {
                    case userEventTypeDraw: return EventType.draw;
                    case userEventTypeTick: return EventType.tick;
                    case ALLEGRO_EVENT_KEY_UP: return EventType.keyUp;
                    case ALLEGRO_EVENT_KEY_DOWN: return EventType.keyDown;
                    case ALLEGRO_EVENT_MOUSE_AXES:
                    {
                        if (_event.mouse.dz > 0)
                            return EventType.mouseWheelUp;
                        else if (_event.mouse.dz < 0)
                            return EventType.mouseWheelDown;
                        else
                            return EventType.mouseMove;
                    }
                    case ALLEGRO_EVENT_MOUSE_BUTTON_DOWN: return EventType.mouseDown;
                    case ALLEGRO_EVENT_MOUSE_BUTTON_UP: return EventType.mouseUp;
                    case ALLEGRO_EVENT_DISPLAY_RESIZE: return EventType.displayResize;
                    case ALLEGRO_EVENT_DISPLAY_EXPOSE: return EventType.displayExpose;
                    default: return EventType.unknown;
                }
            }

            /**
             * Returns the tick time, in seconds.
             *
             * Valid for: `tick`.
             */
            public @property double tickTimeInSecs() const nothrow @nogc
            in
            {
                assert(_event.type == userEventTypeTick);
            }
            body
            {
                const pTED = cast(TickEventData*)_event.user.data1;
                return pTED.tickTimeInSecs;
            }

            /**
             * Returns the time elapsed, in seconds, since the previous tick event.
             *
             * Valid for: `tick`.
             */
            public @property double deltaTimeInSecs() const nothrow @nogc
            in
            {
                assert(_event.type == userEventTypeTick);
            }
            body
            {
                const pTED = cast(TickEventData*)_event.user.data1;
                return pTED.deltaTimeInSecs;
            }

            /**
             * Returns the current drawing time, in seconds.
             *
             * Valid for: `draw`.
             */
            public @property double drawingTimeInSecs() const nothrow @nogc
            in
            {
                assert(_event.type == userEventTypeDraw);
            }
            body
            {
                const pDED = cast(DrawEventData*)_event.user.data1;
                return pDED.drawingTimeInSecs;
            }

            /**
             * Returns the time elapsed since the last tick event, in seconds.
             *
             * Valid for: `draw`.
             */
            public @property double timeSinceTickInSecs() const nothrow @nogc
            in
            {
                assert(_event.type == userEventTypeDraw);
            }
            body
            {
                const pDED = cast(DrawEventData*)_event.user.data1;
                return pDED.timeSinceTickInSecs;
            }

            /**
             * Returns the key code of the key generating the event.
             *
             * Valid for: `keyDown`, `keyUp`.
             */
            public @property KeyCode keyCode() const nothrow @nogc
            in
            {
                assert(_event.type == ALLEGRO_EVENT_KEY_DOWN
                    || _event.type == ALLEGRO_EVENT_KEY_UP);
            }
            body
            {
                return cast(KeyCode)(_event.keyboard.keycode);
            }

            static if (engineHasMember!(E, "display", "Display"))
            {
                /**
                 * Returns the Display which had the focus when the event was
                 * generated.
                 *
                 * TODO: Er, and what about "null"? Do I need a special
                 *     "invalidHandle" constant?
                 *
                 * Valid for: `keyDown`, `keyUp`, `mouseMove`, `mouseDown`,
                 * `mouseUp`, `mouseWheelUp`,  `mouseWheelDown`, `displayResize`,
                 * `displayExpose`.
                 */
                public @property inout(E.Display*) display() inout nothrow @nogc
                in
                {
                    assert(_event.type == ALLEGRO_EVENT_KEY_DOWN
                        || _event.type == ALLEGRO_EVENT_KEY_UP
                        || _event.type == ALLEGRO_EVENT_MOUSE_AXES
                        || _event.type == ALLEGRO_EVENT_MOUSE_BUTTON_DOWN
                        || _event.type == ALLEGRO_EVENT_MOUSE_BUTTON_UP
                        || _event.type == ALLEGRO_EVENT_DISPLAY_RESIZE
                        || _event.type == ALLEGRO_EVENT_DISPLAY_EXPOSE);
                }
                body
                {
                    switch (_event.type)
                    {
                        case ALLEGRO_EVENT_MOUSE_AXES:
                        case ALLEGRO_EVENT_MOUSE_BUTTON_DOWN:
                        case ALLEGRO_EVENT_MOUSE_BUTTON_UP:
                        {
                            return _engine.display.displayFromHandle(
                                cast(size_t)_event.mouse.display);
                        }

                        case ALLEGRO_EVENT_KEY_DOWN:
                        case ALLEGRO_EVENT_KEY_UP:
                        {
                            return _engine.display.displayFromHandle(
                                cast(size_t)_event.keyboard.display);
                        }

                        case ALLEGRO_EVENT_DISPLAY_RESIZE:
                        case ALLEGRO_EVENT_DISPLAY_EXPOSE:
                        {
                            return _engine.display.displayFromHandle(
                                cast(size_t)_event.display.source);
                        }

                        default:
                        {
                            assert(false, "Invalid event type");
                        }
                    }
                }

                /**
                 * Returns the handle of the Display which had the focus when
                 * the event was generated.
                 *
                 * TODO: Er, and what about "null"? Do I need a special
                 *     "invalidHandle" constant?
                 *
                 * Valid for: `keyDown`, `keyUp`, `mouseMove`, `mouseDown`,
                 * `mouseUp`, `mouseWheelUp`,  `mouseWheelDown`, `displayResize`,
                 * `displayExpose`.
                 */
                public @property E.Display.handleType displayHandle() const nothrow @nogc
                in
                {
                    assert(_event.type == ALLEGRO_EVENT_KEY_DOWN
                        || _event.type == ALLEGRO_EVENT_KEY_UP
                        || _event.type == ALLEGRO_EVENT_MOUSE_AXES
                        || _event.type == ALLEGRO_EVENT_MOUSE_BUTTON_DOWN
                        || _event.type == ALLEGRO_EVENT_MOUSE_BUTTON_UP
                        || _event.type == ALLEGRO_EVENT_DISPLAY_RESIZE
                        || _event.type == ALLEGRO_EVENT_DISPLAY_EXPOSE);
                }
                body
                {
                    alias handleType = E.Display.handleType;

                    switch (_event.type)
                    {
                        case ALLEGRO_EVENT_MOUSE_AXES:
                        case ALLEGRO_EVENT_MOUSE_BUTTON_DOWN:
                        case ALLEGRO_EVENT_MOUSE_BUTTON_UP:
                            return cast(handleType)_event.mouse.display;

                        case ALLEGRO_EVENT_KEY_UP:
                        case ALLEGRO_EVENT_KEY_DOWN:
                            return cast(handleType)_event.keyboard.display;

                        case ALLEGRO_EVENT_DISPLAY_RESIZE:
                        case ALLEGRO_EVENT_DISPLAY_EXPOSE:
                            return cast(handleType)_event.display.source;

                        default:
                            assert(false, "Invalid event type");
                    }
                }
            }

            /**
             * Returns the horizontal coordinate of the mouse, in pixels.
             *
             * Zero is the left side of the Display.
             *
             * Valid for: `mouseMove`, `mouseDown`, `mouseUp`.
             */
            public @property int mouseX() const nothrow @nogc
            in
            {
                assert(_event.type == ALLEGRO_EVENT_MOUSE_AXES
                    || _event.type == ALLEGRO_EVENT_MOUSE_BUTTON_DOWN
                    || _event.type == ALLEGRO_EVENT_MOUSE_BUTTON_UP);
            }
            body
            {
                return _event.mouse.x;
            }

            /**
             * Returns the vertical coordinate of the mouse, in pixels.
             *
             * Zero is the top side of the Display.
             *
             * Valid for: `mouseMove`, `mouseDown`, `mouseUp`.
             */
            public @property int mouseY() const nothrow @nogc
            in
            {
                assert(_event.type == ALLEGRO_EVENT_MOUSE_AXES
                    || _event.type == ALLEGRO_EVENT_MOUSE_BUTTON_DOWN
                    || _event.type == ALLEGRO_EVENT_MOUSE_BUTTON_UP);
            }
            body
            {
                return _event.mouse.y;
            }

            /**
             * Returns the mouse button that generated the event.
             *
             * Valid for: `mouseDown`, `mouseUp`.
             */
            public @property MouseButton mouseButton() const nothrow @nogc
            in
            {
                assert(_event.type == ALLEGRO_EVENT_MOUSE_BUTTON_DOWN
                    || _event.type == ALLEGRO_EVENT_MOUSE_BUTTON_UP);
            }
            body
            {
                return _event.mouse.button > MouseButton.extra2
                    ? MouseButton.other
                    : cast(MouseButton)_event.mouse.button;
            }
        } // struct Event

        /**
         * Data passed to tick events.
         *
         * Since at any moment we have at most one single tick event in
         * the SDL event queue, we can use this single instance.
         */
        private TickEventData _tickEventData;

        /**
         * Data passed to draw events.
         *
         * What was said about `_tickEventData` holds here, too.
         */
        private DrawEventData _drawEventData;

        /// The one and only event queue used by the Engine.
        private ALLEGRO_EVENT_QUEUE* _eventQueue;

        /// Event source for user-defined events.
        private ALLEGRO_EVENT_SOURCE _userEventSource;

        /// The first event type used by this library.
        private enum _firstEventType = ALLEGRO_GET_EVENT_TYPE('S','B','X','S');

        /// Event type used for tick events.
        public enum userEventTypeTick = _firstEventType;

        /// Event type used for draw events.
        public enum userEventTypeDraw = _firstEventType + 1;

        /// Event type used for app state events.
        public enum userEventTypeAppState = _firstEventType + 2;

        /// Key codes.
        public enum KeyCode: typeof(ALLEGRO_KEY_A)
        {
            q = ALLEGRO_KEY_Q,  w = ALLEGRO_KEY_W,  e = ALLEGRO_KEY_E,  r = ALLEGRO_KEY_R,
            t = ALLEGRO_KEY_T,  y = ALLEGRO_KEY_Y,  u = ALLEGRO_KEY_U,  i = ALLEGRO_KEY_I,
            o = ALLEGRO_KEY_O,  p = ALLEGRO_KEY_P,  a = ALLEGRO_KEY_A,  s = ALLEGRO_KEY_S,
            d = ALLEGRO_KEY_D,  f = ALLEGRO_KEY_F,  g = ALLEGRO_KEY_G,  h = ALLEGRO_KEY_H,
            j = ALLEGRO_KEY_J,  k = ALLEGRO_KEY_K,  l = ALLEGRO_KEY_L,  z = ALLEGRO_KEY_Z,
            x = ALLEGRO_KEY_X,  c = ALLEGRO_KEY_C,  v = ALLEGRO_KEY_V,  b = ALLEGRO_KEY_B,
            n = ALLEGRO_KEY_N,  m = ALLEGRO_KEY_M,

            _1 = ALLEGRO_KEY_1,  _2 = ALLEGRO_KEY_2,  _3 = ALLEGRO_KEY_3,  _4 = ALLEGRO_KEY_4,
            _5 = ALLEGRO_KEY_5,  _6 = ALLEGRO_KEY_6,  _7 = ALLEGRO_KEY_7,  _8 = ALLEGRO_KEY_8,
            _9 = ALLEGRO_KEY_9,  _0 = ALLEGRO_KEY_0,

            f1  = ALLEGRO_KEY_F1,   f2  = ALLEGRO_KEY_F2,   f3  = ALLEGRO_KEY_F3,
            f4  = ALLEGRO_KEY_F4,   f5  = ALLEGRO_KEY_F5,   f6  = ALLEGRO_KEY_F6,
            f7  = ALLEGRO_KEY_F7,   f8  = ALLEGRO_KEY_F8,   f9  = ALLEGRO_KEY_F9,
            f10 = ALLEGRO_KEY_F10,  f11 = ALLEGRO_KEY_F11,  f12 = ALLEGRO_KEY_F12,

            left = ALLEGRO_KEY_LEFT,  right = ALLEGRO_KEY_RIGHT,
            up = ALLEGRO_KEY_UP,  down = ALLEGRO_KEY_DOWN,

            lShift = ALLEGRO_KEY_LSHIFT,   rShift = ALLEGRO_KEY_LSHIFT,
            lCtrl = ALLEGRO_KEY_LCTRL,     rCtrl = ALLEGRO_KEY_RCTRL,
            lWin = ALLEGRO_KEY_LWIN,       rWin = ALLEGRO_KEY_RWIN,
            lAlt = ALLEGRO_KEY_ALT,       rAlt = ALLEGRO_KEY_ALTGR,
            menu = ALLEGRO_KEY_MENU,

            space = ALLEGRO_KEY_SPACE,          _return = ALLEGRO_KEY_ENTER,
            escape = ALLEGRO_KEY_ESCAPE,        tab = ALLEGRO_KEY_TAB,
            backspace = ALLEGRO_KEY_BACKSPACE,

            printScreen = ALLEGRO_KEY_PRINTSCREEN,    scrollLock = ALLEGRO_KEY_SCROLLLOCK,
            pause = ALLEGRO_KEY_PAUSE,                capsLock = ALLEGRO_KEY_CAPSLOCK,

            backquote = ALLEGRO_KEY_BACKQUOTE,      minus = ALLEGRO_KEY_MINUS,
            equals = ALLEGRO_KEY_EQUALS,            backslash = ALLEGRO_KEY_BACKSLASH,
            openBracket = ALLEGRO_KEY_OPENBRACE,    closeBracket = ALLEGRO_KEY_CLOSEBRACE,
            semicolon = ALLEGRO_KEY_SEMICOLON,      quote = ALLEGRO_KEY_QUOTE,
            comma = ALLEGRO_KEY_COMMA,              period = ALLEGRO_KEY_FULLSTOP,
            slash = ALLEGRO_KEY_SLASH,

            home = ALLEGRO_KEY_HOME,     end = ALLEGRO_KEY_END,
            pageUp = ALLEGRO_KEY_PGUP,   pageDown = ALLEGRO_KEY_PGDN,

            numLock = ALLEGRO_KEY_NUMLOCK,

            kp0 = ALLEGRO_KEY_PAD_0,  kp1 = ALLEGRO_KEY_PAD_1,  kp2 = ALLEGRO_KEY_PAD_2,
            kp3 = ALLEGRO_KEY_PAD_3,  kp4 = ALLEGRO_KEY_PAD_4,  kp5 = ALLEGRO_KEY_PAD_5,
            kp6 = ALLEGRO_KEY_PAD_6,  kp7 = ALLEGRO_KEY_PAD_7,  kp8 = ALLEGRO_KEY_PAD_8,
            kp9 = ALLEGRO_KEY_PAD_9,

            kpDivide = ALLEGRO_KEY_PAD_SLASH,   kpMultiply = ALLEGRO_KEY_PAD_ASTERISK,
            kpMinus = ALLEGRO_KEY_PAD_MINUS,    kpPlus = ALLEGRO_KEY_PAD_PLUS,
            kpDecimal = ALLEGRO_KEY_PAD_DELETE, kpEnter = ALLEGRO_KEY_PAD_ENTER,
        }

        /// The mouse buttons.
        public enum MouseButton
        {
            /// The left mouse button.
            left = 1,

            /// The middle mouse button.
            middle,

            /// The right mouse button.
            right,

            /// The first "extra" mouse button.
            extra1,

            /// The second "extra" mouse button.
            extra2,

            /// Other mouse button.
            other,
        }
    }

} // version HaveAllegro5
