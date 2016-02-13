/**
 * An engine back end based on the SDL 2 library (and OpenGL).
 *
 * License: MIT License, see the `LICENSE` file.
 *
 * Authors: Leandro Motta Barros.
 *
 * TODO: Add `@nogc`, `nothrow` and friends. Or maybe just templatize
 *     everything.
 */

module sbxs.engine.backend.sdl2;

version(HasSDL2)
{
    import std.exception: enforce; // TODO: Use proper error handling

    import derelict.sdl2.sdl;
    import derelict.opengl3.gl3;

    /// Back end core subsystem, based on the SDL 2 library.
    public struct SDL2BackendCore
    {
        /// Initializes the subsystem.
        public void initialize()
        {
            DerelictSDL2.load();
            DerelictGL3.load();
            enforce (SDL_Init(0) == 0); // TODO: Do proper error handling
        }

        /// Shuts the subsystem down.
        public void shutdown()
        {
            SDL_Quit();
        }

        /// Returns the current wall time, in seconds since some unspecified epoch.
        public double getTime()
        {
            return SDL_GetTicks() / 1000.0;
        }

        /// Sleeps the current thread for a given number of seconds.
        public void sleep(double timeInSecs)
        {
            SDL_Delay(cast(uint)(timeInSecs * 1000));
        }
    }

    /// Back end display subsystem, based on the SDL 2 library.
    public struct SDL2BackendDisplay
    {
        /// Initializes the subsystem.
        public void initialize()
        {
            SDL_InitSubSystem(SDL_INIT_VIDEO);
        }

        /// Shuts the subsystem down.
        public void shutdown()
        {
            SDL_QuitSubSystem(SDL_INIT_VIDEO);
        }
    }

    /// Engine back end based on the SDL 2 library.
    public struct SDL2Backend
    {
        /// Initializes the back end.
        public void initialize()
        {
            core.initialize();
            display.initialize();
        }

        /// Shuts the back end down.
        public void shutdown()
        {
            display.shutdown();
            core.shutdown();
        }

        // The core subsystem.
        public SDL2BackendCore core;

        // The display subsystem.
        public SDL2BackendDisplay display;
    }

} // version HasSDL2
