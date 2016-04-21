/**
 * Time subsystem based on Allegro 5.
 *
 * License: MIT License, see the `LICENSE` file.
 *
 * Authors: Leandro Motta Barros.
 */

module sbxs.engine.backends.allegro5.time;

version(HaveAllegro5)
{
    import derelict.allegro5.allegro;

    /**
     * Time subsystem based on the Allegro 5 library.
     *
     * Parameters:
     *     E = The type of the engine using this subsystem.
     */
    public struct Allegro5TimeSubsystem(E)
    {
        import sbxs.engine.time: TimeCommon;

        mixin TimeCommon!E;

        /// Returns the current wall time, in seconds since some unspecified epoch.
        public double getTime()
        {
            return al_get_time();
        }

        /// Sleeps the calling thread for a given number of seconds.
        public void sleep(double timeInSecs)
        {
            al_rest(timeInSecs);
        }
    }

} // version HaveAllegro5
