/**
 * Operating System subsystem based on Allegro 5.
 *
 * License: MIT License, see the `LICENSE` file.
 *
 * Authors: Leandro Motta Barros.
 */

module sbxs.engine.backends.allegro5.os;

version(HaveAllegro5)
{
    import derelict.allegro5.allegro;

    /**
     * Operating System subsystem based on the Allegro 5 library.
     *
     * Parameters:
     *     E = The type of the engine using this subsystem.
     */
    public struct Allegro5OSSubsystem(E)
    {
        import sbxs.engine.os: OSCommon;

        mixin OSCommon!E;

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
