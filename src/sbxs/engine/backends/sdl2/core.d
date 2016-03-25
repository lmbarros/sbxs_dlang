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
     *     E = The type of the engine using this subsystem implementation.
     */
    public struct SDL2CoreBE(E)
    {
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

        /// The engine using this subsystem.
        private E* _engine;
    }

    import sbxs.engine.backends.sdl2.backend;
    static assert(isCoreBE!(SDL2CoreBE!SDL2Backend));

} // version HasSDL2
