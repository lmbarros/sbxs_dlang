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
        // TODO: This would be useful to take the "id to Display" logic to the Engine
        public alias handle_t = Uint32;
    }

    static assert(isDisplay!SDL2Display);


    /**
     * Back end Display subsystem, based on the SDL 2 library.
     *
     * Parameters:
     *     BE = The type of the back end.
     */
    public struct SDL2DisplayBE(BE)
    {
        /**
         * Initializes the subsystem.
         *
         * Parameters:
         *     backend = The back end, passed here so that this submodule can
         *         call its services.
         */
        public void initialize(BE* backend)
        in
        {
            assert(backend !is null);
        }
        body
        {
            _backend = backend;

            if (SDL_InitSubSystem(SDL_INIT_VIDEO) < 0)
                throw new BackendInitializationException(sdlGetError());
        }

        /// Shuts the subsystem down.
        public void shutdown() nothrow @nogc
        {
            SDL_QuitSubSystem(SDL_INIT_VIDEO);
        }

        /// Creates a Display and `insertBack()`s it into `container`.
        public void createDisplay(C)(DisplayParams dp, ref C container)
        {
            container.insertBack(dp);
            auto display = &(container.back());
            _idToDisplay[SDL_GetWindowID(display._window)] = display;
        }

        /// Convers an SDL window ID to a Display.
        package inout(Display*) windowIDToDisplay(Uint32 windowID) inout
        {
            auto pDisplay = windowID in _idToDisplay;
            if (pDisplay is null)
                return null;
            else
                return *pDisplay;
        }

        /// Maps window IDs to Displays.
        private Display*[Uint32] _idToDisplay;

        /// The type used as Display.
        public alias Display = SDL2Display;

        /// The back end.
        private BE* _backend;
    }

    import sbxs.engine.backends.sdl2.backend;
    static assert(isDisplayBE!(SDL2DisplayBE!SDL2Backend));

} // version HasSDL2
