
/**
 * An engine backed by Allegro 5.
 *
 * License: MIT License, see the `LICENSE` file.
 *
 * Authors: Leandro Motta Barros.
 */

module sbxs.engine.backends.allegro5.engine;


version(HasAllegro5)
{
    import sbxs.engine;


    /**
     * Performs basic Allegro 5 initialization (all the required initialization
     * which is not done by any subsystem).
     *
     * This must be called during the initialization of any Engine based on
     * Allegro 5.
     *
     * Parameters:
     *     E = The type of engine being initialized.
     */
    public void initializeAllegro5(E)()
    {
        import derelict.allegro5.allegro;
        import derelict.opengl3.gl3;

        // General back end initialization
        DerelictAllegro5.load();

        const success = al_install_system(ALLEGRO_VERSION_INT, null);
        if (!success)
            throw new BackendInitializationException();
    }

    /**
     * Performs basic Allegro 5 shutdown (all the required shutdown
     * tasks which are not done by any subsystem).
     *
     * This must be called during the shutdown of any Engine based on
     * Allegro 5.
     *
     * Parameters:
     *     E = The type of engine being shutdown.
     */
    public void shutdownAllegro5(E)()
    {
        import derelict.allegro5.allegro: al_uninstall_system;
        al_uninstall_system();
    }


    /// An engine entirely backed by Allegro 5.
    public struct Allegro5Engine
    {
        import sbxs.engine.backends.allegro5;

        mixin EngineCommon;

        /// The display subsystem.
        Allegro5DisplaySubsystem!Allegro5Engine display;

        /// The events subsystem.
        Allegro5EventsSubsystem!Allegro5Engine events;

        /// The operating system subsystem.
        Allegro5OSSubsystem!Allegro5Engine os;

        /// Initializes the Allegro 5 library.
        void initializeBackend()
        {
            initializeAllegro5!(typeof(this))();
        }

        /// Shuts the Allegro 5 library down.
        void shutdownBackend()
        {
            shutdownAllegro5!(typeof(this))();
        }
    }

} // version(HasAllegro5)
