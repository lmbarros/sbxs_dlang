/**
 * An engine back end based on the Allegro 5 library (and OpenGL).
 *
 * License: MIT License, see the `LICENSE` file.
 *
 * Authors: Leandro Motta Barros.
 *
 * See_also: http://liballeg.org
 *
 * TODO: There is too much code replication among SDL and Allegro backends.
 */

module sbxs.engine.backends.allegro5;

version(HasAllegro5)
{
    import derelict.allegro5.allegro;
    import derelict.opengl3.gl3;
    import sbxs.engine.backend;
    import sbxs.engine.display;


    //
    // Core subsystem
    //

    /// Back end core subsystem, based on the Allegro 5 library.
    public struct Allegro5CoreBE
    {
        /// Initializes the subsystem.
        public static void initialize()
        {
            version(linux)
            {
                // TODO: Make this work portably (and by "portably", I mean "even
                //       across different Linux distros"). This is just a hack I
                //       did to make it work on my system.
                DerelictAllegro5.load("liballegro.so.5.0");
            }
            else
            {
                DerelictAllegro5.load();
            }
            DerelictGL3.load();

            const success = al_install_system(ALLEGRO_VERSION_INT, null);
            if (!success)
                throw new BackendInitializationException();
        }

        /// Shuts the subsystem down.
        public static void shutdown() nothrow @nogc
        {
            al_uninstall_system();
        }

        /// Returns the current wall time, in seconds since some unspecified epoch.
        public static double getTime() nothrow @nogc
        {
            return al_get_time();
        }

        /// Sleeps the current thread for a given number of seconds.
        public static void sleep(double timeInSecs) nothrow @nogc
        {
            al_rest(timeInSecs);
        }
    }

    static assert(isCoreBE!Allegro5CoreBE);


    //
    // Display subsystem
    //

    /// Allegro 5 implementation of the Display interface.
    public struct Allegro5Display
    {
        @disable this(this);

        /**
         * Constructs the `Allegro5Display`.
         *
         * Parameters:
         *     dp = The parameters specifying how the Display shall be like.
         */
        public this(DisplayParams dp)
        {
            // TODO: Ensure that OpenGL is used.
            // TODO: Take `dp` into account for real.
            _display = al_create_display(dp.width, dp.height);
            if (_display is null)
                throw new DisplayCreationException();

            scope(failure)
                al_destroy_display(_display);

            import std.string: toStringz;
            al_set_window_title(_display, dp.title.toStringz);
        }

        /// Destroys the Display.
        public ~this() nothrow @nogc
        {
            // TODO: Will need to call `al_unregister_event_source`. How
            //       to deal with Displays and event sources? (This a point in
            //       which two different subsystems will interact.)
            al_destroy_display(_display);
        }

        /// The Display width, in pixels.
        public @property int width() nothrow @nogc
        {
            return al_get_display_width(_display);
        }

        /// The Display height, in pixels.
        public @property int height() nothrow @nogc
        {
            return al_get_display_height(_display);
        }

        /// Make this Display the current target for rendering.
        public void makeCurrent() nothrow @nogc
        {
            if (_currentDisplay != _display)
            {
                al_set_target_bitmap(al_get_backbuffer(_display));
                _currentDisplay = _display;
            }
        }

        /**
         * Swap buffers, show stuff.
         *
         * This implementation might not be terribly efficent,
         * especially when more than one Display is used.
         */
        public void swapBuffers() nothrow @nogc
        {
            if (_display !is null && _currentDisplay != _display)
                al_set_target_bitmap(al_get_backbuffer(_display));

            al_flip_display();

            if (_currentDisplay !is null && _currentDisplay != _display)
                al_set_target_bitmap(al_get_backbuffer(_currentDisplay));
        }

        /// A handle that uniquely identifies this Display.
        public @property handle_t handle() nothrow @nogc
        {
            return cast(handle_t)(_display);
        }

        /// The Allegro object representing the Display.
        private ALLEGRO_DISPLAY* _display;

        /**
         * The Display currently active. `null` if no Display was created yet.
         *
         * TODO: Will also be `null` when an off-screen render target is active.
         */
        private static ALLEGRO_DISPLAY* _currentDisplay = null;

        /// A type for a handle that uniquely identifies a Display.
        public alias handle_t = size_t;
    }

    static assert(isDisplay!Allegro5Display);


    /// Back end Display subsystem, based on the Allegro5 library.
    public struct Allegro5DisplayBE
    {
        import sbxs.containers.nc_array: NCArray;

        /**
         * A no-op, since Allegro's Display subsystem is initialized
         * automatically when Allegro iself is initialized.
         */
        public void initialize() @nogc nothrow { }

        /// Shuts the Display subsystem down. Destroys all Displays.
        public void shutdown()
        {
            _displays.clear();
        }

        /**
         * Reserve in the internal data structures enough memory for storing
         * `numDisplays` Displays.
         *
         * You must call this before calling `createDisplay()` if you intend to
         * create more than one Display.
         *
         * TODO: This shouldn't be part of the back end-specific API!
         */
        public void reserveDisplays(size_t numDisplays)
        {
            _displays.reserve(numDisplays);
        }

        /// Swap the buffers of all Displays.
        public void swapAllBuffers()
        {
            foreach (ref display; _displays)
                display.swapBuffers();
        }

        /**
         * Creates and returns a Display.
         *
         * Parameters:
         *     dp = The parameters specifying how the Display shall be like.
         *
         * Warning:
         *
         * Returns: A pointer to the newly created Display. See the warning above.
         */
        public Display* createDisplay(DisplayParams dp)
        {
            if (_displays.capacity == 0)
                _displays.reserve(1);

            assert(_displays.capacity > _displays.length,
                "Call `reserveDisplays` if you want to create more than one Display.");

            _displays.insertBack(dp);

            return &_displays.back();
        }

        /// The type used as Display.
        public alias Display = Allegro5Display;

        /// The Displays managed by this back end.
        private NCArray!Display _displays;
    }

    static assert(isDisplayBE!Allegro5DisplayBE);



    //
    // The back end itself
    //

    /// Engine back end based on the Allegro5 library.
    public struct Allegro5Backend
    {
        /// Initializes the back end.
        public void initialize()
        {
            core.initialize();
            display.initialize();
        }

        /// Shuts the back end down.
        public void shutdown()
        {
            display.shutdown();
            core.shutdown();
        }

        /// The core subsystem.
        public Allegro5CoreBE core;

        /// The Display subsystem.
        public Allegro5DisplayBE display;
    }

    static assert(isBackend!Allegro5Backend);

} // version HasAllegro5
