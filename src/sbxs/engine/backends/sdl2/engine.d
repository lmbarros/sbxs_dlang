/**
 * An engine backed by SDL 2.
 *
 * License: MIT License, see the `LICENSE` file.
 *
 * Authors: Leandro Motta Barros.
 */

module sbxs.engine.backends.sdl2.engine;

version(HaveSDL2)
{
    import sbxs.engine;
    import derelict.sdl2.sdl;

    /**
     * Performs basic SDL 2 initialization (all the required initialization
     * which is not done by any subsystem).
     *
     * This must be called during the initialization of any Engine based on
     * SDL 2.
     */
    public void initializeSDL2()
    {
        import sbxs.engine.backends.sdl2.helpers: sdlGetError;

        try
        {
            DerelictSDL2.load();
        }
        catch (Exception e)
        {
            throw new BackendException("Error loading the SDL 2 library: "
                ~ e.msg);
        }

        if (SDL_Init(0) < 0)
            throw new BackendInitializationException(sdlGetError());
    }

    /**
     * Performs basic SDL 2 shutdown (all the required shutdown tasks
     * which are not done by any subsystem).
     *
     * This must be called during the shutdown of any Engine based on
     * SDL 2.
     */
    public void shutdownSDL2()
    {
        SDL_Quit();
    }


    /// An engine entirely backed by SDL 2.
    public struct SDL2Engine
    {
        import sbxs.engine.backends.sdl2;

        mixin EngineCommon;

        /// The Display subsystem.
        public SDL2DisplaySubsystem!SDL2Engine display;

        /// The Events subsystem.
        public SDL2EventsSubsystem!SDL2Engine events;

        /// The Raster subsystem.
        public SDL2RasterSubsystem!SDL2Engine raster;

        /// The Time subsystem.
        public SDL2TimeSubsystem!SDL2Engine time;

        /// Initializes the SDL 2 library.
        package(sbxs.engine) void initializeBackend()
        {
            initializeSDL2();
        }

        /// Shuts down the SDL 2 library.
        package(sbxs.engine) void shutdownBackend()
        {
            shutdownSDL2();
        }
    }

} // version HaveSDL2
