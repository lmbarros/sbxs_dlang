/**
 * SDL 2 back end: Display subsystem.
 *
 * License: MIT License, see the `LICENSE` file.
 *
 * Authors: Leandro Motta Barros.
 */

module sbxs.engine.backends.sdl2.display;

version(HasSDL2)
{
    import derelict.sdl2.sdl;
    import derelict.opengl3.gl3;
    import sbxs.engine.backend;
    import sbxs.engine.display;
    import sbxs.engine.backends.sdl2.helpers;

    /**
     * SDL 2 implementation of a Display.
     *
     * Note: Displays have reference semantics, despite being implemented as
     *     `struct`s! You must create all your Displays through the Display
     *     subsystem, which owns all Displays and is responsible for their
     *     destruction.
     */
    public struct SDL2Display
    {
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

            if (_window is null)
                throw new DisplayCreationException(sdlGetError());

            scope(failure)
                SDL_DestroyWindow(_window);

            // Set window minimum and maximum dimensions
            SDL_SetWindowMinimumSize(_window, dp.minWidth, dp.minHeight);
            SDL_SetWindowMaximumSize(_window, dp.maxWidth, dp.maxHeight);

            // Create the OpenGL context
            _context = SDL_GL_CreateContext(_window);
            if (_context is null)
                throw new DisplayCreationException(sdlGetError());

            scope(failure)
                SDL_GL_DeleteContext(_context);

            // Now that we have a context, we can reload the OpenGL bindings, and
            // we'll get all the OpenGL 3+ stuff
            DerelictGL3.reload();

            // Enable VSync (TODO: Failing here shouldn't be an error. Log?)
            if (SDL_GL_SetSwapInterval(1) != 0)
                throw new DisplayCreationException(sdlGetError());
        }

        /// Destroys the Display.
        package(sbxs.engine) void destroy() nothrow @nogc
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

        /// The Display title.
        public @property string title() nothrow
        {
            import std.conv: to;
            return to!string(SDL_GetWindowTitle(_window));
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
        public @property handleType handle() nothrow @nogc
        {
            return SDL_GetWindowID(_window);
        }

        /// The SDL window pointer.
        package SDL_Window* _window = null;

        /**
         * The SDL OpenGL context object.
         *
         * Notice that `SDL_GLContext` is an `alias` to a pointer type (as
         * ensured by the `static assert` below). This is relevant because
         * otherwise guaranteeing the reference semantics of Display would be
         * a bit harder.
         */
        private SDL_GLContext _context = null;

        // Be sure that `SDL_GLContext` is a pointer.
        import std.traits: isPointer;
        static assert(isPointer!SDL_GLContext);

        /// A type for a handle that uniquely identifies a Display.
        public alias handleType = Uint32;
    }


    /**
     * Display engine subsystem back end, based on the SDL 2 library.
     *
     * Parameters:
     *     E = The type of the engine using this subsystem back end.
     */
    package struct SDL2DisplaySubsystem(E)
    {
        /// The Engine using this subsystem back end.
        private E* _engine;

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

            if (SDL_InitSubSystem(SDL_INIT_VIDEO) < 0)
                throw new BackendInitializationException(sdlGetError());
        }

        /// Shuts the subsystem down.
        public void shutdown() nothrow @nogc
        {
            SDL_QuitSubSystem(SDL_INIT_VIDEO);
        }

        /**
         * Creates and returns a Display.
         *
         * Parameters:
         *     params = The parameters describing the desired Display
         *         characteristics.
         */
        public Display create(DisplayParams params)
        {
            auto newDisplay = Display(params);
            _handleToDisplay[newDisplay.handle] = newDisplay;
            return newDisplay;
        }

        /**
         * Converts an SDL window ID to a Display.
         *
         * Parameters:
         *     handle = The Display handle handle (an SDL window ID).
         *
         * Returns: The Display whose handle is `handle`. May be `null`, if no
         *     such Display exists.
         */
        public inout(Display*) displayFromHandle(Display.handleType handle) inout
        {
            auto pDisplay = handle in _handleToDisplay;
            if (pDisplay is null)
                return null;
            else
                return pDisplay;
        }

        /// Maps window IDs to Displays.
        private Display[Display.handleType] _handleToDisplay;

        /// The type used as Display.
        public alias Display = SDL2Display;
    }

} // version HasSDL2
