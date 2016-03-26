/**
 * SDL 2 back end: Operating System subsystem.
 *
 * License: MIT License, see the `LICENSE` file.
 *
 * Authors: Leandro Motta Barros.
 */

module sbxs.engine.backends.sdl2.os;

import derelict.sdl2.sdl;

version(HasSDL2)
{
    /**
     * Operating System engine subsystem, based on the SDL 2 library.
     */
    package struct SDL2OSSubsystem
    {
        /**
         * Initializes the subsystem.
         *
         * Parameters:
         *     engine = The engine using this subsystem.
         */
        public void initialize(E)(E* engine)
        in
        {
            assert(engine !is null);
        }
        body
        {
            // Nothing here!
        }

        /**
         * Shuts the subsystem down.
         *
         * Parameters:
         *     engine = The engine using this subsystem.
         */
        public void shutdown(E)(E* engine)
        in
        {
            assert(engine !is null);
        }
        body
        {
            // Nothing here!
        }

        /// Returns the current wall time, in seconds since some unspecified epoch.
        public double getTime(E)(E* engine)
        in
        {
            assert(engine !is null);
        }
        body
        {
            return SDL_GetTicks() / 1000.0;
        }

        /// Sleeps the current thread for a given number of seconds.
        public void sleep(E)(E* engine, double timeInSecs)
        in
        {
            assert(engine !is null);
        }
        body
        {
            SDL_Delay(cast(uint)(timeInSecs * 1000));
        }
    }

} // version HasSDL2
