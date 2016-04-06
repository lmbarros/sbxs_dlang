/**
 * SDL 2 back end: the back end itself.
 *
 * License: MIT License, see the `LICENSE` file.
 *
 * Authors: Leandro Motta Barros.
 */

module sbxs.engine.backends.sdl2.backend;

version(HasSDL2)
{
    import derelict.sdl2.sdl;
    import sbxs.engine;
    import sbxs.engine.backends.sdl2;

    /// Engine back end based on the SDL 2 library.
    public struct SDL2Backend
    {
        /// The type of an Engine using this back end.
        public alias engineType = Engine!SDL2Backend;

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
            import sbxs.engine.backends.sdl2.helpers;

            _engine = engine;

            // General back end initialization
            DerelictSDL2.load();
            DerelictGL3.load();
            if (SDL_Init(0) < 0)
                throw new BackendInitializationException(sdlGetError());

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

            // Shutdown SDL itself
            SDL_Quit();
        }

        /// The OS subsystem.
        public SDL2OSSubsystem!engineType os;

        /// The Display subsystem.
        public SDL2DisplaySubsystem!engineType display;

        /// The Events subsystem.
        public SDL2EventsSubsystem!engineType events;

        /// The Display type, as provided by the back end.
        public alias Display = typeof(display).Display;
    }
}
