/**
 * An engine back end based on the SDL 2 library (and OpenGL).
 *
 * License: MIT License, see the `LICENSE` file.
 *
 * Authors: Leandro Motta Barros.
 *
 * See_also: http://libsdl.org
 *
 * TODO: There is too much code replication among SDL and Allegro backends.
 */

module sbxs.engine.backends.sdl2;

version(HasSDL2)
{
    import std.exception: enforce; // TODO: Use proper error handling
    import derelict.sdl2.sdl;
    import derelict.opengl3.gl3;
    import sbxs.engine.backend;
    import sbxs.engine.display;


    //
    // Core subsystem
    //

    /// Back end core subsystem, based on the SDL 2 library.
    public struct SDL2CoreBE
    {
        /// Initializes the subsystem.
        public static void initialize()
        {
            DerelictSDL2.load();
            DerelictGL3.load();
            enforce(SDL_Init(0) == 0); // TODO: Do proper error handling
        }

        /// Shuts the subsystem down.
        public static void shutdown() nothrow @nogc
        {
            SDL_Quit();
        }

        /// Returns the current wall time, in seconds since some unspecified epoch.
        public static double getTime() nothrow @nogc
        {
            return SDL_GetTicks() / 1000.0;
        }

        /// Sleeps the current thread for a given number of seconds.
        public static void sleep(double timeInSecs) nothrow @nogc
        {
            SDL_Delay(cast(uint)(timeInSecs * 1000));
        }
    }

    static assert(isCoreBE!SDL2CoreBE);


    //
    // Display subsystem
    //

    /// SDL 2 implementation of the Display interface.
    public struct SDL2Display
    {
        @disable this(this);

        /**
         * Constructs the `SDL2Display`.
         *
         * Parameters:
         *     dp = The parameters specifying how the Display shall be like.
         */
        public this(DisplayParams dp)
        {
            SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, dp.graphicsAPIMajorVersion);
            SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, dp.graphicsAPIMinorVersion);
            SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_CORE);

            Uint32 flags = SDL_WINDOW_OPENGL;

            // TODO: implement real full screen
            if (dp.windowingMode == WindowingMode.fullScreen
                || dp.windowingMode == WindowingMode.fakeFullScreen)
            {
                flags |= SDL_WINDOW_FULLSCREEN_DESKTOP;
            }

            if (!dp.decorations)
                flags |= SDL_WINDOW_BORDERLESS;

            if (dp.resizable)
                flags |= SDL_WINDOW_RESIZABLE;

            import std.string: toStringz;
            _window = SDL_CreateWindow(
                dp.title.toStringz,
                SDL_WINDOWPOS_CENTERED,
                SDL_WINDOWPOS_CENTERED,
                dp.width,
                dp.height,
                flags);

            enforce(_window !is null); // TODO: Error handling!

            scope(failure)
                SDL_DestroyWindow(_window);

            // Set window minimum and maximum dimensions
            SDL_SetWindowMinimumSize(_window, dp.minWidth, dp.minHeight);
            SDL_SetWindowMaximumSize(_window, dp.maxWidth, dp.maxHeight);

            // Create the OpenGL context
            _context = SDL_GL_CreateContext(_window);
            enforce(_context !is null); // TODO: Error handling!

            scope(failure)
                SDL_GL_DeleteContext(_context);

            // Now that we have a context, we can reload the OpenGL bindings, and
            // we'll get all the OpenGL 3+ stuff
            DerelictGL3.reload();

            // Enable VSync (TODO: Failing here shouldn't be an error. Log?)
            enforce (SDL_GL_SetSwapInterval(1) == 0);
        }

        /// Destroys the Display.
        public ~this() nothrow @nogc
        {
            SDL_GL_DeleteContext(_context);
            SDL_DestroyWindow(_window);
        }

        /// The Display width, in pixels.
        public @property int width() nothrow @nogc
        {
            int w, h;
            SDL_GetWindowSize(_window, &w, &h);
            return w;
        }

        /// The Display height, in pixels.
        public @property int height() nothrow @nogc
        {
            int w, h;
            SDL_GetWindowSize(_window, &w, &h);
            return h;
        }

        /// Make this Display the current target for rendering.
        public void makeCurrent() nothrow @nogc
        {
            SDL_GL_MakeCurrent(_window, _context);
        }

        /// Swap buffers, show stuff.
        public void swapBuffers() nothrow @nogc
        {
            SDL_GL_SwapWindow(_window);
        }

        /// A handle that uniquely identifies this Display.
        public @property handle_t handle() nothrow @nogc
        {
            return SDL_GetWindowID(_window);
        }

        /// The SDL window pointer.
        package SDL_Window* _window = null;

        /// The SDL OpenGL context object.
        private SDL_GLContext _context = null;

        /// A type for a handle that uniquely identifies a Display.
        public alias handle_t = uint;
    }

    static assert(isDisplay!SDL2Display);


    /// Back end Display subsystem, based on the SDL 2 library.
    public struct SDL2DisplayBE
    {
        import sbxs.containers.nc_array: NCArray;

        /// Initializes the subsystem.
        public void initialize()
        {
            enforce(SDL_InitSubSystem(SDL_INIT_VIDEO) == 0); // TODO: Proper error handling.
        }

        /// Shuts the subsystem down.
        public void shutdown() nothrow @nogc
        {
            _displays.clear();
            SDL_QuitSubSystem(SDL_INIT_VIDEO);
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

        /// Creates and returns a Display.
        public Display* createDisplay(DisplayParams dp)
        {
            if (_displays.capacity == 0)
                _displays.reserve(1);

            assert(_displays.capacity > _displays.length,
                "Call `reserveDisplays` if you want to create more than one Display.");

            _displays.insertBack(dp);

            return &_displays.back();
        }

        /// The Displays managed by this back end.
        private NCArray!Display _displays;

        /// The type used as Display.
        public alias Display = SDL2Display;
    }

    static assert(isDisplayBE!SDL2DisplayBE);


    //
    // The back end itself
    //

    /// Engine back end based on the SDL 2 library.
    public struct SDL2Backend
    {
        /// Initializes the back end.
        public void initialize()
        {
            core.initialize();
            display.initialize();
        }

        /// Shuts the back end down.
        public void shutdown() nothrow @nogc
        {
            display.shutdown();
            core.shutdown();
        }

        /// The core subsystem.
        public SDL2CoreBE core;

        /// The Display subsystem.
        public SDL2DisplayBE display;
    }

    static assert(isBackend!SDL2Backend);

} // version HasSDL2
