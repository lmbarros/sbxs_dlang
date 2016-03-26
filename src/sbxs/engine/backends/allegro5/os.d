/**
 * Allegro 5 back end: Operating System subsystem.
 *
 * License: MIT License, see the `LICENSE` file.
 *
 * Authors: Leandro Motta Barros.
 */

module sbxs.engine.backends.allegro5.os;

import derelict.allegro5.allegro;

version(HasAllegro5)
{
    /**
     * Operating System engine subsystem back end, based on the Allegro 5 library.
     *
     * Parameters:
     *     E = The type of the engine using this subsystem back end.
     */
    package struct Allegro5OSSubsystem(E)
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
            return al_get_time();
        }

        /// Sleeps the current thread for a given number of seconds.
        public void sleep(double timeInSecs)
        {
            al_rest(timeInSecs);
        }
    }

} // version HasAllegro5
