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
    import sbxs.engine.backend;
    import sbxs.engine.backends.sdl2.core;
    import sbxs.engine.backends.sdl2.display;
    import sbxs.engine.backends.sdl2.events;

    /// Engine back end based on the SDL 2 library.
    public struct SDL2Backend
    {
        /// Initializes the back end.
        public void initialize()
        {
            core.initialize();
            display.initialize();
            events.initialize();
        }

        /// Shuts the back end down.
        public void shutdown() nothrow @nogc
        {
            events.shutdown();
            display.shutdown();
            core.shutdown();
        }

        /// The core subsystem.
        public SDL2CoreBE core;

        /// The Display subsystem.
        public SDL2DisplayBE display;

        /// The Events subsystem.
        public SDL2EventsBE events;

        // TODO: xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
        public alias Event = SDL2EventsBE.Event;
        public alias KeyCode = SDL2EventsBE.KeyCode;
    }

    static assert(isBackend!SDL2Backend);
}
