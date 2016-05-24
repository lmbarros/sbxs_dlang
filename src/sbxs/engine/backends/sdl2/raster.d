/**
 * Raster subsystem based on SDL 2.
 *
 * License: MIT License, see the `LICENSE` file.
 *
 * Authors: Leandro Motta Barros.
 */

module sbxs.engine.backends.sdl2.raster;

version(HaveSDL2)
{
    import derelict.sdl2.sdl;

    // xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
    public struct SDL2Bitmap
    {

    }

    /**
     * Raster subsystem based on the Allegro 5 library.
     *
     * Parameters:
     *     E = The type of the engine using this subsystem.
     */
    public struct SDL2RasterSubsystem(E)
    {
        import sbxs.engine.raster: RasterCommon;

        mixin RasterCommon!E;

        // xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

        public alias Bitmap = SDL2Bitmap;
    }

} // version HaveSDL2
