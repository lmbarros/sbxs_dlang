/**
 * SDL 2 back end: the back end itself.
 *
 * License: MIT License, see the `LICENSE` file.
 *
 * Authors: Leandro Motta Barros.
 */

module sbxs.engine.backends.sdl2.backend;

import derelict.sdl2.sdl;

version(HasSDL2)
{
    import sbxs.engine.backend;
    import sbxs.engine.engine;
    import sbxs.engine.backends.sdl2.os;
    import sbxs.engine.backends.sdl2.display;
    import sbxs.engine.backends.sdl2.events;

    /// Engine back end based on the SDL 2 library.
    public struct SDL2Backend
    {
        /// The engine using this back end.
        private Engine!SDL2Backend* _engine;

        /**
         * Initializes the back end.
         *
         * Parameters:
         *     engine = The engine using this back end.
         */
        public void initialize(Engine!SDL2Backend* engine)
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
            display.shutdown(_engine);
            events.shutdown(_engine);
            os.shutdown(_engine);

            // Shutdown SDL itself
            SDL_Quit();
        }

        /// The OS subsystem.
        public SDL2OSSubsystem os;

        /// The Display subsystem.
        public SDL2DisplaySubsystem display;

        /// The Events subsystem.
        public SDL2EventsSubsystem events;
    }
}
