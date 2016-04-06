/**
 * Allegro 5 back end: the back end itself.
 *
 * License: MIT License, see the `LICENSE` file.
 *
 * Authors: Leandro Motta Barros.
 */

module sbxs.engine.backends.allegro5.backend;


version(HasAllegro5)
{
    import derelict.allegro5.allegro;
    import sbxs.engine;
    import sbxs.engine.backends.allegro5;

    /// Engine back end based on the Allegro 5 library.
    public struct Allegro5Backend
    {
        /// The type of an Engine using this back end.
        public alias engineType = Engine!Allegro5Backend;

        /// The engine using this back end.
        private engineType* _engine;

        /**
         * Initializes the back end.
         *
         * Parameters:
         *     engine = The engine using this back end.
         */
        public void initialize(engineType* engine)
        in
        {
            assert(engine !is null);
        }
        body
        {
            import derelict.opengl3.gl3;

            _engine = engine;

            // General back end initialization
            version(linux)
            {
                // TODO: Make this work portably (and by "portably", I mean "even
                //       across different Linux distros"). This is just a hack I
                //       did to make it work on my system.
                DerelictAllegro5.load("liballegro.so.5.0");
            }
            else
            {
                DerelictAllegro5.load();
            }

            DerelictGL3.load();

            const success = al_install_system(ALLEGRO_VERSION_INT, null);
            if (!success)
                throw new BackendInitializationException();

            // Initialize each subsystem
            os.initialize(_engine);
            events.initialize(_engine);
            display.initialize(_engine);
        }

        /// Shuts the back end down.
        public void shutdown()
        {
            // Shutdown each subsystem
            display.shutdown();
            events.shutdown();
            os.shutdown();

            // Shutdown Allegro itself
            al_uninstall_system();
        }

        /// The OS subsystem.
        public Allegro5OSSubsystem!engineType os;

        /// The Display subsystem.
        public Allegro5DisplaySubsystem!engineType display;

        /// The Events subsystem.
        public Allegro5EventsSubsystem!engineType events;

        /// The Display type, as provided by the back end.
        public alias Display = typeof(display).Display;
    }
}
