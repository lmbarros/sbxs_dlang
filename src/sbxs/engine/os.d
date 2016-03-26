/**
 * Definitions related with the Operating System subsystem.
 *
 * License: MIT License, see the `LICENSE` file.
 *
 * Authors: Leandro Motta Barros.
 */

module sbxs.engine.os;


/**
 * Implementation of the Operating System engine subsystem.
 *
 * This provides Operating System services. Er, I mean, those that are
 * not provided by any other subsystem.
 *
 * Parameters:
 *     E = The type of the engine being used.
 */
package struct OSSubsystem(E)
{
    /// The engine being used.
    private E* _engine;

    /**
     * Initializes the subsystem.
     *
     * Parameters:
     *     engine = The engine being used.
     */
    void initialize(E* engine)
    in
    {
        assert(engine !is null);
    }
    body
    {
        _engine = engine;
    }

    /**
     * Shuts the subsystem down.
     *
     * Parameters:
     *     engine = The engine being used.
     */
    void shutdown(E* engine)
    in
    {
        assert(engine !is null);
    }
    body
    {
        // Nothing here!
    }

    /**
     * Returns the current time, as the number of seconds passed since the
     * program started running.
     *
     * Parameters:
     *     backend = The back end being used.
     *
     * Returns: The number of seconds elapsed since the program started
     *     running.
     */
    public double getTime()
    {
        return _engine._backend.os.getTime(_engine);
    }

    /**
     * Makes the calling thread to sleep for a given time.
     *
     * Parameters:
     *     engine = The Engine being used.
     *
     * Parameters:
     *     timeInSecs = The amount of time to sleep, in seconds.
     */
    public void sleep(double timeInSecs)
    {
        _engine._backend.os.sleep(_engine, timeInSecs);
    }
}
