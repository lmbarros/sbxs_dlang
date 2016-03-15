/**
 * Definitions related with the Core engine subsystem.
 *
 * License: MIT License, see the `LICENSE` file.
 *
 * Authors: Leandro Motta Barros.
 */

module sbxs.engine.core;


mixin template CoreSubsystem(BE)
{
    /**
     * Returns the current time, as the number of seconds passed since the
     * program started running.
     *
     * Returns: The number of seconds elapsed since the program started
     *     running.
     */
    public double getTime() { return _backend.core.getTime(); }

    /**
     * Makes the calling thread to sleep for a given time.
     *
     * Parameters:
     *     timeInSecs = The amount of time to sleep, in seconds.
     */
    public void sleep(double timeInSecs) { _backend.core.sleep(timeInSecs); }
}
