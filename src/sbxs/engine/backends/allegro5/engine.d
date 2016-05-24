/**
 * An engine backed by Allegro 5.
 *
 * License: MIT License, see the `LICENSE` file.
 *
 * Authors: Leandro Motta Barros.
 */

module sbxs.engine.backends.allegro5.engine;

version(HaveAllegro5)
{
    import sbxs.engine;


    /**
     * Performs basic Allegro 5 initialization (all the required initialization
     * which is not done by any subsystem).
     *
     * This must be called during the initialization of any Engine based on
     * Allegro 5.
     */
    public void initializeAllegro5()
    {
        import derelict.allegro5.allegro;
        import derelict.opengl3.gl3;

        // General back end initialization
        try
        {
            DerelictAllegro5.load();
        }
        catch(Exception e)
        {
            throw new BackendException("Error loading the Allegro 5 library: "
            ~ e.msg);
        }

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
     */
    public void shutdownAllegro5()
    {
        import derelict.allegro5.allegro: al_uninstall_system;
        al_uninstall_system();
    }


    /// An engine entirely backed by Allegro 5.
    public struct Allegro5Engine
    {
        import sbxs.engine.backends.allegro5;

        mixin EngineCommon;

        /// The Display subsystem.
        public Allegro5DisplaySubsystem!Allegro5Engine display;

        /// The Events subsystem.
        public Allegro5EventsSubsystem!Allegro5Engine events;

        /// The Raster subsystem.
        public Allegro5RasterSubsystem!Allegro5Engine raster;

        /// The Time subsystem.
        public Allegro5TimeSubsystem!Allegro5Engine time;

        /// Initializes the Allegro 5 library.
        package(sbxs.engine) void initializeBackend()
        {
            initializeAllegro5();
        }

        /// Shuts the Allegro 5 library down.
        package(sbxs.engine)void shutdownBackend()
        {
            shutdownAllegro5();
        }
    }

} // version HaveAllegro5
