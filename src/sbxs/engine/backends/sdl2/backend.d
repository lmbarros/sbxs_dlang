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
        /// Initializes the back end.
        public void initialize(Engine!SDL2Backend* engine)
        {
            import derelict.opengl3.gl3;
            import sbxs.engine.backends.sdl2.helpers;

            // General back end initialization
            DerelictSDL2.load();
            DerelictGL3.load();
            if (SDL_Init(0) < 0)
                throw new BackendInitializationException(sdlGetError());

            // Initialize each subsystem
            os.initialize(engine);
            events.initialize(engine);
            display.initialize(engine);
        }

        /// Shuts the back end down.
        public void shutdown(Engine!SDL2Backend* engine)
        {
            // Shutdown each subsystem
            display.shutdown(engine);
            events.shutdown(engine);
            os.shutdown(engine);

            // General back end shutdown
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
