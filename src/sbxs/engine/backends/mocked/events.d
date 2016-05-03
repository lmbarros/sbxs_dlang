/**
 * Mocked back end: Events subsystem.
 *
 * License: MIT License, see the `LICENSE` file.
 *
 * Authors: Leandro Motta Barros.
 */

module sbxs.engine.backends.mocked.events;


import sbxs.engine;
import sbxs.engine.backends.events_common;


/**
 * Mocked events engine subsystem back end, for testing.
 *
 * Parameters:
 *     E = The type of the engine using this subsystem back end.
 */
package struct MockedEventsSubsystem(E)
{
    mixin EventsCommon!E;

    /**
     * The event queue.
     *
     * This is public so that users can fill it as desired. It's a mock, after
     * all.
     */
    public Event[] mockedEventQueue;

    /// Initializes the subsystem.
    public void initializeBackend()
    {
        _isInited = true;
    }

    /// Shuts the subsystem down.
    public void shutdownBackend()
    {
        _isInited = false;
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
     * This is part of the interface every back end is supposed to implement.
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
        auto event = Event(_engine, EventType.draw);

        event._drawEventData.drawingTimeInSecs = drawingTimeInSecs;
        event._drawEventData.timeSinceTickInSecs = timeSinceTickInSecs;

        return event;
    }

    /// Creates a Tick event; convenience for testing.
    public Event makeTickEvent(double deltaTimeInSecs, double tickTimeInSecs)
    {
        auto event = Event(_engine, EventType.tick);

        event._tickEventData.deltaTimeInSecs = deltaTimeInSecs;
        event._tickEventData.tickTimeInSecs = tickTimeInSecs;

        return event;
    }

    static if (engineHasMember!(E, "display", "Display"))
    {
        /// The type of Display handles.
        private alias displayHandleType = E.display.Display.handleType;

        /// Creates a Key Down event; convenience for testing.
        public Event makeKeyDownEvent(KeyCode keyCode, displayHandleType displayHandle)
        {
            auto event = Event(_engine, EventType.keyDown);

            event._keyCode = keyCode;
            event._displayHandle = displayHandle;

            return event;
        }

        /// Creates a Key Up event; convenience for testing.
        public Event makeKeyUpEvent(KeyCode keyCode, displayHandleType displayHandle)
        {
            auto event = Event(_engine, EventType.keyUp);

            event._keyCode = keyCode;
            event._displayHandle = displayHandle;

            return event;
        }

        /// Creates a Mouse Move event; convenience for testing.
        public Event makeMouseMoveEvent(int mouseX, int mouseY, displayHandleType displayHandle)
        {
            auto event = Event(_engine, EventType.mouseMove);

            event._mouseX = mouseX;
            event._mouseY = mouseY;
            event._displayHandle = displayHandle;

            return event;
        }

        /// Creates a Mouse Down event; convenience for testing.
        public Event makeMouseDownEvent(MouseButton mouseButton, int mouseX, int mouseY,
            displayHandleType displayHandle)
        {
            auto event = Event(_engine, EventType.mouseDown);

            event._mouseX = mouseX;
            event._mouseY = mouseY;
            event._mouseButton = mouseButton;
            event._displayHandle = displayHandle;

            return event;
        }

        /// Creates a Mouse Up event; convenience for testing.
        public Event makeMouseUpEvent(MouseButton mouseButton, int mouseX, int mouseY,
            displayHandleType displayHandle)
        {
            auto event = Event(_engine, EventType.mouseUp);

            event._mouseX = mouseX;
            event._mouseY = mouseY;
            event._mouseButton = mouseButton;
            event._displayHandle = displayHandle;

            return event;
        }

        /// Creates a Mouse Wheel Up event; convenience for testing.
        public Event makeMouseWheelUpEvent(displayHandleType displayHandle)
        {
            auto event = Event(_engine, EventType.mouseWheelUp);

            event._displayHandle = displayHandle;

            return event;
        }

        /// Creates a Mouse Wheel Down event; convenience for testing.
        public Event makeMouseWheelDownEvent(displayHandleType displayHandle)
        {
            auto event = Event(_engine, EventType.mouseWheelDown);

            event._displayHandle = displayHandle;

            return event;
        }

        /// Creates a Display Resize event; convenience for testing.
        public Event makeDisplayResizeEvent(displayHandleType displayHandle)
        {
            auto event = Event(_engine, EventType.displayResize);
            event._displayHandle = displayHandle;
            return event;
        }

        /// Creates a Display Expose event; convenience for testing.
        public Event makeDisplayExposeEvent(displayHandleType displayHandle)
        {
            auto event = Event(_engine, EventType.displayExpose);
            event._displayHandle = displayHandle;
            return event;
        }

    } // static if (engineHasMember!(E, "display", "Display"))


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

    /// Is this back end initialized?
    public @property bool isInited() const nothrow @nogc { return _isInited; }

    /// Ditto
    private bool _isInited = false;

    /// A mocked event.
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
         * Returns the time elapsed, in seconds, since the previous tick event.
         *
         * Valid for: `tick`
         */
        public @property double deltaTimeInSecs() const nothrow @nogc
        in
        {
            assert(_type == EventType.tick);
        }
        body
        {
            return _tickEventData.deltaTimeInSecs;
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

        static if (engineHasMember!(E, "display", "Display"))
        {
            /// Handle of the display with focus when the event happened.
            private displayHandleType _displayHandle;

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
            public @property inout(E.display.Display*) display() inout nothrow @nogc
            in
            {
                assert(_type == EventType.keyDown
                    || _type == EventType.keyUp
                    || _type == EventType.mouseMove
                    || _type == EventType.mouseDown
                    || _type == EventType.mouseUp
                    || _type == EventType.mouseWheelDown
                    || _type == EventType.mouseWheelUp
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
                    || _type == EventType.mouseWheelDown
                    || _type == EventType.mouseWheelUp
                    || _type == EventType.displayResize
                    || _type == EventType.displayExpose);
            }
            body
            {
                return _displayHandle;
            }

        } // static if (engineHasMember!(E, "display", "Display"))

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

    /**
     * The mouse buttons.
     *
     * TODO: What about pseudo clicks generated by touch events? SDL 2 has a
     *     special mouse button (`SDL_TOUCH_MOUSEID`) for them; Allegro doesn't
     *     seem to.
     */
    public enum MouseButton
    {
        /// The left mouse button.
        left,

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


// -----------------------------------------------------------------------------
// Unit tests
// -----------------------------------------------------------------------------

version(unittest)
{
    import sbxs.engine;
    import sbxs.engine.backends.mocked;

    struct TestEngineSimple
    {
        mixin EngineCommon;
        MockedEventsSubsystem!TestEngineSimple events;
    }

    struct TestEngineWithDisplay
    {
        mixin EngineCommon;
        MockedDisplaySubsystem!TestEngineWithDisplay display;
        MockedEventsSubsystem!TestEngineWithDisplay events;
    }
}


// Tests initialization and finalization.
unittest
{
    MockedEventsSubsystem!TestEngineSimple theEvents;
    assert(theEvents.isInited == false);

    theEvents.initializeBackend();
    assert(theEvents.isInited == true);

    theEvents.shutdownBackend();
    assert(theEvents.isInited == false);
}


// Tests `enqueueTickEvent()`.
unittest
{
    TestEngineSimple engine;
    engine.initialize();

    // Initially, no events in the queue
    assert(engine.events.mockedEventQueue.length == 0);

    // Call `enqueueTickEvent()`, check if it works as expected
    engine.events.enqueueTickEvent(0.2, 0.1);
    assert(engine.events.mockedEventQueue.length == 1);

    engine.events.enqueueTickEvent(0.3, 0.35);
    assert(engine.events.mockedEventQueue.length == 2);

    assert(engine.events.mockedEventQueue[0].type == EventType.tick);
    assert(engine.events.mockedEventQueue[0].deltaTimeInSecs == 0.2);
    assert(engine.events.mockedEventQueue[0].tickTimeInSecs == 0.1);

    assert(engine.events.mockedEventQueue[1].type == EventType.tick);
    assert(engine.events.mockedEventQueue[1].deltaTimeInSecs == 0.3);
    assert(engine.events.mockedEventQueue[1].tickTimeInSecs == 0.35);
}


// Tests `makeDrawEvent()`.
unittest
{
    TestEngineSimple engine;
    engine.initialize();

    // Call `makeDrawEvent()`, check if it works as expected
    auto event = engine.events.makeDrawEvent(0.15, 0.2);

    assert(event.type == EventType.draw);
    assert(event.drawingTimeInSecs == 0.15);
    assert(event.timeSinceTickInSecs == 0.2);

    // Again, again!
    event = engine.events.makeDrawEvent(0.35, 0.4);

    assert(event.type == EventType.draw);
    assert(event.drawingTimeInSecs == 0.35);
    assert(event.timeSinceTickInSecs == 0.4);
}


// Create several different events, enqueue and dequeue them.
unittest
{
    TestEngineWithDisplay engine;
    engine.initialize();

    alias KeyCode = TestEngineWithDisplay.KeyCode;
    alias MouseButton = TestEngineWithDisplay.MouseButton;
    alias Event = TestEngineWithDisplay.Event;

    // Create and enqueue events
    engine.events.mockedEventQueue ~= engine.events.makeTickEvent(0.1, 0.2);
    engine.events.mockedEventQueue ~= engine.events.makeKeyDownEvent(KeyCode.backspace, 111);
    engine.events.mockedEventQueue ~= engine.events.makeKeyUpEvent(KeyCode.f5, 222);
    engine.events.mockedEventQueue ~= engine.events.makeMouseMoveEvent(33, 44, 333);
    engine.events.mockedEventQueue ~= engine.events.makeMouseDownEvent(MouseButton.left, 100, 20, 444);
    engine.events.mockedEventQueue ~= engine.events.makeMouseUpEvent(MouseButton.right, 20, 10, 555);
    engine.events.mockedEventQueue ~= engine.events.makeMouseWheelUpEvent(666);
    engine.events.mockedEventQueue ~= engine.events.makeMouseWheelDownEvent(777);

    // Dequeue and check events
    auto event = Event(&engine);

    assert(engine.events.dequeueEvent(&event) == true);
    assert(event.type == EventType.tick);
    assert(event.deltaTimeInSecs == 0.1);
    assert(event.tickTimeInSecs == 0.2);

    assert(engine.events.dequeueEvent(&event) == true);
    assert(event.type == EventType.keyDown);
    assert(event.keyCode == KeyCode.backspace);
    assert(event.displayHandle == 111);

    assert(engine.events.dequeueEvent(&event) == true);
    assert(event.type == EventType.keyUp);
    assert(event.keyCode == KeyCode.f5);
    assert(event.displayHandle == 222);

    assert(engine.events.dequeueEvent(&event) == true);
    assert(event.type == EventType.mouseMove);
    assert(event.mouseX == 33);
    assert(event.mouseY == 44);
    assert(event.displayHandle == 333);

    assert(engine.events.dequeueEvent(&event) == true);
    assert(event.type == EventType.mouseDown);
    assert(event.mouseButton == MouseButton.left);
    assert(event.mouseX == 100);
    assert(event.mouseY == 20);
    assert(event.displayHandle == 444);

    assert(engine.events.dequeueEvent(&event) == true);
    assert(event.type == EventType.mouseUp);
    assert(event.mouseButton == MouseButton.right);
    assert(event.mouseX == 20);
    assert(event.mouseY == 10);
    assert(event.displayHandle == 555);

    assert(engine.events.dequeueEvent(&event) == true);
    assert(event.type == EventType.mouseWheelUp);
    assert(event.displayHandle == 666);

    assert(engine.events.dequeueEvent(&event) == true);
    assert(event.type == EventType.mouseWheelDown);
    assert(event.displayHandle == 777);

    // No more events
    assert(engine.events.dequeueEvent(&event) == false);
}


// Test Display events with real Displays.
unittest
{
    TestEngineWithDisplay engine;
    engine.initialize();

    alias Event = TestEngineWithDisplay.Event;

    DisplayParams params;
    params.title = "Aigale!";
    auto display = engine.display.create(params);

    // Create and enqueue events
    engine.events.mockedEventQueue ~= engine.events.makeDisplayResizeEvent(display.handle);
    engine.events.mockedEventQueue ~= engine.events.makeDisplayExposeEvent(display.handle);

    // Dequeue and check events
    auto event = Event(&engine);

    assert(engine.events.dequeueEvent(&event) == true);
    assert(event.type == EventType.displayResize);
    assert(event.displayHandle == display.handle);
    assert(event.display.title == "Aigale!");

    assert(engine.events.dequeueEvent(&event) == true);
    assert(event.type == EventType.displayExpose);
    assert(event.displayHandle == display.handle);
    assert(event.display.title == "Aigale!");
}
