/**
 * Time subsystem based on SDL 2.
 *
 * License: MIT License, see the `LICENSE` file.
 *
 * Authors: Leandro Motta Barros.
 */

module sbxs.engine.backends.sdl2.time;

version(HaveSDL2)
{
    import derelict.sdl2.sdl;

    /**
     * Time subsystem based on the Allegro 5 library.
     *
     * Parameters:
     *     E = The type of the engine using this subsystem.
     */
    public struct SDL2TimeSubsystem(E)
    {
        import sbxs.engine.time: TimeCommon;

        mixin TimeCommon!E;

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

} // version HaveSDL2
