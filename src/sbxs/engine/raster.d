/**
 * Definitions related with the Raster subsystem.
 *
 * License: MIT License, see the `LICENSE` file.
 *
 * Authors: Leandro Motta Barros.
 */

module sbxs.engine.raster;


/// Kinds of access to the pixel data in a Bitmap.
public enum BitmapPixelAccess
{
    /**
     * Pixel data cannot be accessed. This is potentially faster than any
     * other option.
     */
    none,

    /// Pixel data is read-only.
    readOnly,

    /// Pixel data is write-only.
    writeOnly,

    /**
     * Pixel data is readable and writable. This will probably be slower than
     * any of the other options.
     */
    readWrite
}


/**
 * Quality settings used when scaling a Bitmap.
 *
 * If you ask for a quality setting that is higher than the best the back end
 * can provide, the back end should use the highest available setting.
 */
public enum BitmapScalingQuality
{
    /**
     * Low quality scaling.
     *
     * This typically equates to "nearest neighbor".
     */
    low,

    /**
     * Medium quality scaling.
     *
     * Expect something like linear interpolation (AKA linear filtering).
     */
    medium,

    /**
     * High quality scaling.
     *
     * If available, something fancy like anisotropic filtering will be used.
     */
    high
}



/**
 * A set of configurations that define how a Hardware Bitmap is to be created
 * like.
 *
 * In actual use, these may be considered hints to the back end, which may or
 * may not be obeyed. Back ends may also have special rules like "this and that
 * are mutually exclusive". Good luck creating a bitmap with the features you
 * wish.
 *
 * TODO: Maybe I can have a policy like "log when the requested parameters
 *     cannot be completely fulfilled"? Would be better than wishing good luck.
 *
 * TODO: What about pixel formats? Force one? Allow the caller to choose?
 *     Leave always the deault? Or...?
 */
public struct HWBitmapParams
{
    /// Can this bitmap can be used as the target for render-to-texture?
    public bool rttTarget = false;

    /// How kind of access to the bitmap pixel data is desired.
    public BitmapPixelAccess pixelAccess = BitmapPixelAccess.none;

    /// How nice the bitmap will look like when drawing it scaled?
    public BitmapScalingQuality scalingQuality = BitmapScalingQuality.medium;

    /**
     * Generate and use mipmaps for better downscalling?
     *
     * Back ends supporting this will veru likely ignoer this flag if the
     * Bitmap dimensions are not a power of two.
     */
    public bool useMipmaps = true;
}



/**
 * Common implementation of the Raster engine subsystem.
 *
 * Mix this in your own implementation, implement the required members (and the
 * desired optional ones) and you should obtain a working subsystem.
 *
 * This provides services related with drawing of raster images and
 * render-to-texture (RTT).
 *
 * Parameters:
 *     E = The type of the engine being used.
 *
 * Notes_for_back_end_implementers:
 *
 * xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
 *
 * The following members are required:
 *
 * $(UL
 *     $(LI `double getTime()`: Returns the current wall time, in seconds,
 *         since the engine initialization.)
 *
 *     $(LI `void sleep(double timeInSecs)`: Sleeps the calling thread for
 *         `timeInSecs` seconds.)
 * )
 *
 * And these are optional:
 *
 * $(UL
 *     $(LI `void initializeBackend()`: Performs any back end-specific
 *         initialization for this subsystem.)
 *
 *     $(LI `void shutdownBackend()`: Just like `initializeBackend()`, but for
 *         finalization.)
 *
 *     $(LI `void onEndTick()`: If implemented, this is called by the Events
 *         subsystem just at the end of the `tick()` method.)
 *
 *     $(LI `void onEndDraw()`: If implemented, this is called by the Events
 *         subsystem just at the end of the `draw()` method.)
 * )
 *
 * The `SWBitmap` type provided by the back end represents a Bitmap image that
 * resides in the main system (CPU) memory. It is fast and straightforward to
 * access its pixel data, but it cannot be drawn directly to a any render
 * target (Display or render-to-texture target); you must first convert it to a
 * `HWBitmap`. `SWBitmap`s must have reference semantics.
 *
 * xxxxxxxx Add requirements xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
 *
 * The `HWBitmap` type provided by the back end represents a Bitmap image that
 * potentially resides in the GPU memory. It may be slow and cumbersome to
 * access its pixel data, but it can be drawn directly to a render target
 * (Display or render-to-texture target). Additionaly, `HWBitmap`s may be able
 * to be render-to-texture target themselves, for off-screen rendering.
 * `HWBitmap`s must have reference semantics.
 *
 * xxxxxxxx Add requirements xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
 */
public mixin template RasterCommon(E)
{
    import sbxs.engine.dbi;

    /// The engine being used.
    private E* _engine;

    /**
     * Initializes the subsystem.
     *
     * Parameters:
     *     engine = The engine being used.
     */
    package(sbxs.engine) void initialize(E* engine)
    in
    {
        assert(engine !is null);
    }
    body
    {
        _engine = engine;
        mixin(smCallIfMemberExists("initializeBackend"));
    }

    /// Shuts the subsystem down.
    package(sbxs.engine) void shutdown()
    {
        mixin(smCallIfMemberExists("shutdownBackend"));
    }
}



// -----------------------------------------------------------------------------
// Unit tests
// -----------------------------------------------------------------------------

// Just check if we can really `mixin` this into a dummy structure. (This is
// really tested by the mocked backend tests.)
unittest
{
    import sbxs.engine;

    struct DummyEngine { }

    struct DummyTime
    {
        mixin TimeCommon!DummyEngine;
    }

    DummyEngine engine;
    DummyTime timeSS;

    timeSS.initialize(&engine);

    assert(timeSS._engine == &engine);

    timeSS.shutdown();
}
