/**
 * SDL 2 back end: Core.
 *
 * License: MIT License, see the `LICENSE` file.
 *
 * Authors: Leandro Motta Barros.
 */

module sbxs.engine.backends.sdl2.core;

version(HasSDL2)
{
    import derelict.sdl2.sdl;
    import derelict.opengl3.gl3;
    import sbxs.engine.backend;
    import sbxs.engine.backends.sdl2.helpers;

    /**
     * Back end Core subsystem, based on the SDL 2 library.
     *
     * Parameters:
     *     BE = The type of the back end.
     */
    public struct SDL2CoreBE(BE)
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

            DerelictSDL2.load();
            DerelictGL3.load();
            if (SDL_Init(0) < 0)
                throw new BackendInitializationException(sdlGetError());
        }

        /// Shuts the subsystem down.
        public void shutdown() nothrow @nogc
        {
            SDL_Quit();
        }

        /// Returns the current wall time, in seconds since some unspecified epoch.
        public double getTime() nothrow @nogc
        {
            return SDL_GetTicks() / 1000.0;
        }

        /// Sleeps the current thread for a given number of seconds.
        public void sleep(double timeInSecs) nothrow @nogc
        {
            SDL_Delay(cast(uint)(timeInSecs * 1000));
        }

        /// The back end.
        private BE* _backend;
    }

    import sbxs.engine.backends.sdl2.backend;
    static assert(isCoreBE!(SDL2CoreBE!SDL2Backend));

} // version HasSDL2
