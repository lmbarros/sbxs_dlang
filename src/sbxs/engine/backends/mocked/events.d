/**
 * Mocked back end: Events subsystem.
 *
 * License: MIT License, see the `LICENSE` file.
 *
 * Authors: Leandro Motta Barros.
 */

module sbxs.engine.backends.mocked.events;

import sbxs.engine.backend;
import sbxs.engine.events;

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


/**
 * Mocked Events engine subsystem back end.
 *
 * Parameters:
 *     E = The type of the engine using this subsystem back end.
 */
package struct MockedEventsSubsystem(E)
{
    /// The Engine using this subsystem back end.
    private E* _engine;

    /**
     * The event queue.
     *
     * This is public so that users can fill it as desired. It's a mock, after
     * all.
     */
    public Event[] mockedEventQueue;

    /**
     * Initializes the subsystem.
     *
     * Parameters:
     *     engine = The engine using this subsystem.
     */
    public void initialize(E* engine)
    in
    {
        assert(engine !is null);
    }
    body
    {
        _engine = engine;
    }

    /// Shuts the subsystem down.
    public void shutdown()
    {
        // Nothing here.
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
        auto event = Event(_engine, EventType.tick);
        event._tickEventData.deltaTimeInSecs = deltaTimeInSecs;
        event._tickEventData.tickTimeInSecs = tickTimeInSecs;

        mockedEventQueue ~= event;
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
        double timeSinceTickInSecs)
    {
        return Event.makeDrawEvent(
            _engine, deltaTimeInSecs, drawingTimeInSecs, timeSinceTickInSecs);
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
        if (mockedEventQueue.length == 0)
            return false;

        *event = mockedEventQueue[0];

        mockedEventQueue = mockedEventQueue[1..$];

        return true;
    }

    /// An event.
    public struct Event
    {
        /// The type of Display handles.
        private alias displayHandleType = E.backendType.Display.handleType;

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
            _type = EventType.unknown;
        }

        /**
         * Constructs the `Event` from an Engine and and event type.
         *
         * Parameters:
         *     engine = The Engine where this event lives in.
         *     type = The event type.
         *
         */
        public this(E* engine, EventType type) @nogc nothrow
        in
        {
            assert(engine !is null);
        }
        body
        {
            _engine = engine;
            _type = type;
        }

        //
        // Constructor-like static methods
        //

        /// Creates a Draw event.
        public static Event makeDrawEvent(E* engine, double deltaTimeInSecs,
            double drawingTimeInSecs, double timeSinceTickInSecs)
        {
            auto event = Event(engine, EventType.draw);

            event._drawEventData.deltaTimeInSecs = deltaTimeInSecs;
            event._drawEventData.drawingTimeInSecs = drawingTimeInSecs;
            event._drawEventData.timeSinceTickInSecs = timeSinceTickInSecs;

            return event;
        }

        /// Creates a Tick event.
        public static Event makeDrawEvent(E* engine, double deltaTimeInSecs,
            double drawingTimeInSecs)
        {
            auto event = Event(engine, EventType.tick);

            event._tickEventData.deltaTimeInSecs = deltaTimeInSecs;
            event._tickEventData.tickTimeInSecs = drawingTimeInSecs;

            return event;
        }

        /// Creates a Key Down event.
        public static Event makeKeyDownEvent(E* engine, KeyCode keyCode,
            displayHandleType displayHandle)
        {
            auto event = Event(engine, EventType.keyDown);

            event._keyCode = keyCode;
            event._displayHandle = displayHandle;

            return event;
        }

        /// Creates a Key Up event.
        public static Event makeKeyDownEvent(E* engine, KeyCode keyCode,
            displayHandleType displayHandle)
        {
            auto event = Event(engine, EventType.keyUp);

            event._keyCode = keyCode;
            event._displayHandle = displayHandle;

            return event;
        }


        //
        // Event data
        //

        /// The Engine where this Event lives in.
        private E* _engine;

        /// The event type.
        private EventType _type;

        /// Ditto
        public @property EventType type() const nothrow @nogc
        {
            return _type;
        }

        /// Draw event data associated with this event.
        private DrawEventData _drawEventData;

        /// Tick event data associated with this event.
        private TickEventData _tickEventData;

        /// Event key code.
        private KeyCode _keyCode;

        /// Horizontal mouse coordinate.
        private int _mouseX;

        /// Vertical mouse coordinate.
        private int _mouseY;

        /// Mouse button.
        private MouseButton _mouseButton;

        /// Handle of the display with focus when the event happened.
        private displayHandleType _displayHandle;

        //
        // Public access to event data
        //

        /**
         * Returns the tick time, in seconds
         *
         * Valid for: `tick`.
         */
        public @property double tickTimeInSecs() const nothrow @nogc
        in
        {
            assert(_type == EventType.tick);
        }
        body
        {
            return _tickEventData.tickTimeInSecs;
        }

        /**
         * Returns the time elapsed, in seconds, since the previous event
         * of the same type.
         *
         * Valid for: `tick`, `draw`.
         */
        public @property double deltaTimeInSecs() const nothrow @nogc
        in
        {
            assert(_type == EventType.tick || _type == EventType.draw);
        }
        body
        {
            switch(_type)
            {
                case EventType.tick: return _tickEventData.deltaTimeInSecs;
                case EventType.draw: return _drawEventData.deltaTimeInSecs;
                default: assert(false, "Invalid event type");
            }
        }

        /**
         * Returns the current drawing time, in seconds.
         *
         * Valid for: `draw`.
         */
        public @property double drawingTimeInSecs() const nothrow @nogc
        in
        {
            assert(_type == EventType.draw);
        }
        body
        {
            return _drawEventData.drawingTimeInSecs;
        }

        /**
         * Returns the time elapsed since the last tick event, in seconds.
         *
         * Valid for: `draw`.
         */
        public @property double timeSinceTickInSecs() const nothrow @nogc
        in
        {
            assert(type == EventType.draw);
        }
        body
        {
            return _drawEventData.timeSinceTickInSecs;
        }

        /**
         * Returns the `KeyCode` for the key generating the event.
         *
         * Valid for: `keyDown`, `keyUp`.
         */
        public @property KeyCode keyCode() const nothrow @nogc
        in
        {
            assert(_type == EventType.keyDown || _type == EventType.keyUp);
        }
        body
        {
            return _keyCode;
        }

        static if (hasMember!(typeof(E.backend), "display"))
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
            public @property inout(E.backendType.Display*) display() inout nothrow @nogc
            in
            {
                assert(_type == EventType.keyDown
                    || _type == EventType.keyUp
                    || _type == EventType.mouseMove
                    || _type == EventType.mouseDown
                    || _type == EventType.mouseUp
                    || _type == EventType.displayResize
                    || _type == EventType.displayExpose);
            }
            body
            {
                return _engine.display.displayFromHandle(_displayHandle);
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
            public @property displayHandleType displayHandle() const nothrow @nogc
            in
            {
                assert(_type == EventType.keyDown
                    || _type == EventType.keyUp
                    || _type == EventType.mouseMove
                    || _type == EventType.mouseDown
                    || _type == EventType.mouseUp
                    || _type == EventType.displayResize
                    || _type == EventType.displayExpose);
            }
            body
            {
                return _displayHandle;
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
            assert(_type == EventType.mouseMove
                || _type == EventType.mouseDown
                || _type == EventType.mouseUp);
        }
        body
        {
            return _mouseX;
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
            assert(_type == EventType.mouseMove
                || _type == EventType.mouseDown
                || _type == EventType.mouseUp);
        }
        body
        {
            return _mouseY;
        }

        /**
         * Returns the mouse button that generated the event.
         *
         * Valid for: `mouseDown`, `mouseUp`.
         */
        public @property MouseButton mouseButton() const nothrow @nogc
        in
        {
            assert(_type == EventType.mouseDown || _type == EventType.mouseUp);
        }
        body
        {
            return _mouseButton;
        }
    }

    /+
    public enum
    {
        /// Event type used for tick events.
        userEventTypeTick,

        /// Event type used for draw events.
        userEventTypeDraw,

        /// Event type used for app state events.
        userEventTypeAppState,
    }
    +/

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
    public enum KeyCode
    {
        q,  w,  e,  r,  t,  y,  u,  i,  o,  p,  a,  s,  d,
        f,  g,  h,  j,  k,  l,  z,  x,  c,  v,  b,  n,  m,

        _1,  _2,  _3,  _4, _5,  _6,  _7,  _8, _9,  _0,

        f1,  f2,  f3,  f4,  f5,  f6,  f7,  f8,  f9,  f10,  f11,  f12,

        left,  right,  up,  down,

        lShift,  rShift,  lCtrl,  rCtrl,  lWin,  rWin,  lAlt,  rAlt,  menu,

        space,  _return, escape,  tab,  backspace,
        printScreen,  scrollLock, pause,  capsLock,

        backquote,  minus,  equals,  backslash,  openBracket,
        closeBracket,  semicolon,  quote,  comma,  period,  slash,

        home,  end,  pageUp,  pageDown,

        numLock,

        kp0,  kp1,  kp2,  kp3,  kp4,  kp5,  kp6,  kp7,  kp8, kp9,

        kpDivide,  kpMultiply,  kpMinus,  kpPlus,  kpDecimal, kpEnter,
    }
}
