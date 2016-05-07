/**
 * Engine display subsystem based on SDL 2.
 *
 * License: MIT License, see the `LICENSE` file.
 *
 * Authors: Leandro Motta Barros.
 */

module sbxs.engine.backends.sdl2.display;

version(HaveSDL2)
{
    import derelict.sdl2.sdl;
    import derelict.opengl3.gl3;
    import sbxs.engine;
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
         *     params = The parameters specifying how the Display shall be like.
         */
        package(sbxs.engine) this(DisplayParams params)
        {
            SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, params.graphicsAPIMajorVersion);
            SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, params.graphicsAPIMinorVersion);
            SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_CORE);

            Uint32 flags = SDL_WINDOW_OPENGL;

            // TODO: implement real full screen
            if (params.windowingMode == WindowingMode.fullScreen
                || params.windowingMode == WindowingMode.fakeFullScreen)
            {
                flags |= SDL_WINDOW_FULLSCREEN_DESKTOP;
            }

            if (!params.decorations)
                flags |= SDL_WINDOW_BORDERLESS;

            if (params.resizable)
                flags |= SDL_WINDOW_RESIZABLE;

            import std.string: toStringz;
            _window = SDL_CreateWindow(
                params.title.toStringz,
                SDL_WINDOWPOS_CENTERED,
                SDL_WINDOWPOS_CENTERED,
                params.width,
                params.height,
                flags);

            if (_window is null)
                throw new DisplayCreationException(sdlGetError());

            scope(failure)
                SDL_DestroyWindow(_window);

            // Set window minimum and maximum dimensions
            SDL_SetWindowMinimumSize(_window, params.minWidth, params.minHeight);
            SDL_SetWindowMaximumSize(_window, params.maxWidth, params.maxHeight);

            // Create the OpenGL context
            _context = SDL_GL_CreateContext(_window);
            if (_context is null)
                throw new DisplayCreationException(sdlGetError());

            scope(failure)
                SDL_GL_DeleteContext(_context);

            // Now that we have a context, we can reload the OpenGL bindings, and
            // we'll get all the OpenGL 3+ stuff
            try
            {
                DerelictGL3.reload();
            }
            catch(Exception e)
            {
                throw new BackendException("Error reloading the OpenGL bindings: "
                ~ e.msg);
            }

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

        /**
         * A handle different than any valid Display handle.
         *
         * Er, actually considering that `0` does not seem to be officially
         * guaranteed (nothing is mentioned in the API documentation), but I
         * think I saw this on SDL sources (in `src/video/SDL_video.c`,
         * `SDL_VideoInit()`, it says `_this->next_object_id = 1;`).
         */
        public enum invalidDisplay = 0;

        /// A type for a handle that uniquely identifies a Display.
        public alias handleType = Uint32;
    }


    /**
     * Display engine subsystem back end, based on the SDL 2 library.
     *
     * Parameters:
     *     E = The type of the engine using this subsystem back end.
     */
    public struct SDL2DisplaySubsystem(E)
    {
        mixin DisplayCommon!E;

        /// The type used as Display.
        public alias Display = SDL2Display;

        /// Initializes the subsystem.
        package(sbxs.engine) void initializeBackend()
        in
        {
            assert(_engine !is null);
        }
        body
        {
            if (SDL_InitSubSystem(SDL_INIT_VIDEO) < 0)
                throw new BackendInitializationException(sdlGetError());

            try
            {
                DerelictGL3.load();
            }
            catch(Exception e)
            {
                throw new BackendException("Error loading OpenGL bindings: "
                ~ e.msg);
            }
        }

        /// Shuts the subsystem down.
        package(sbxs.engine) void shutdownBackend() nothrow @nogc
        {
            SDL_QuitSubSystem(SDL_INIT_VIDEO);
        }
    }

} // version HaveSDL2
