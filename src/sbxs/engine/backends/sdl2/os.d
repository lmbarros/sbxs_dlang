/**
 * SDL 2 back end: Operating System subsystem.
 *
 * License: MIT License, see the `LICENSE` file.
 *
 * Authors: Leandro Motta Barros.
 */

module sbxs.engine.backends.sdl2.os;

version(HasSDL2)
{
    import derelict.sdl2.sdl;

    /**
     * Operating System engine subsystem back end, based on the SDL 2 library.
     *
     * Parameters:
     *     E = The type of the engine using this subsystem back end.
     */
    package struct SDL2OSSubsystem(E)
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
        }

        /// Shuts the subsystem down.
        public void shutdown() { }

        /// Returns the current wall time, in seconds since some unspecified epoch.
        public double getTime()
        {
            return SDL_GetTicks() / 1000.0;
        }

        /// Sleeps the current thread for a given number of seconds.
        public void sleep(double timeInSecs)
        {
            SDL_Delay(cast(uint)(timeInSecs * 1000));
        }
    }

} // version HasSDL2
