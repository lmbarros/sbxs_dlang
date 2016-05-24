/**
 * Raster subsystem based on Allegro 5.
 *
 * License: MIT License, see the `LICENSE` file.
 *
 * Authors: Leandro Motta Barros.
 */

module sbxs.engine.backends.allegro5.raster;

version(HaveAllegro5)
{
    import sbxs.engine.raster;
    import sbxs.engine.backend;
    import derelict.allegro5;

    /**
     * Converts an `ALLEGRO_BITMAP` between the "memory" and "video" types.
     *
     * If the bitmap is already of the request type, nothing happens (except
     * wasting some CPU cycles).
     *
     * Parameters:
     *     bitmap = The Bitmap to convert.
     *     desiredType= The desired format, to which the bitmap will be
     *         converted. Either `ALLEGRO_MEMORY_BITMAP` or
     *         `ALLEGRO_VIDEO_BITMAP`.
     *
     * Throws:
     *     BitmapCreationException If the conversion fails.
     */
    private void convertTo(ALLEGRO_BITMAP* bitmap, int desiredType)
    {
        // Check if we really need to convert
        auto flags = al_get_bitmap_flags(bitmap);

        if (flags & desiredType)
            return;

        // Yes, we need to convert; do it
        const sourceType = (desiredType == ALLEGRO_MEMORY_BITMAP)
            ? ALLEGRO_VIDEO_BITMAP
            : ALLEGRO_MEMORY_BITMAP;

        flags &= ~sourceType;
        flags |= desiredType;

        al_set_new_bitmap_flags(flags);
        al_convert_bitmap(bitmap);

        // Check if got what we wanted
        flags = al_get_bitmap_flags(bitmap);
        if (!(flags & ALLEGRO_MEMORY_BITMAP))
        {
            const strDesiredType = (desiredType == ALLEGRO_VIDEO_BITMAP)
                ? "hardware (VIDEO)"
                : "software (MEMORY)";

            throw new BitmapCreationException("", "Couldn't convert bitmap "
                ~ "to a " ~ strDesiredType ~ " bitmap.");
        }
    }

    /// A "Software Bitmap" backed by Allegro 5.
    public struct Allegro5SWBitmap
    {
        /**
         * Constructs the Bitmap.
         *
         * Parameters:
         *     width = The Bitmap width, in pixels.
         *     height = The Bitmap height, in pixels.
         *
         * Throws:
         *     BitmapCreationException If something goes wrong.
         *
         * TODO: Consider passing other parameters -- pixel format, in
         *     particular.
         */
        public this(int width, int height)
        {
            al_set_new_bitmap_flags(ALLEGRO_MEMORY_BITMAP);

            _bitmap = al_create_bitmap(width, height);

            if (_bitmap is null)
                throw new BitmapCreationException();
        }

        /// Constructs the Bitmap from a non-null `ALLEGRO_BITMAP`.
        private this(ALLEGRO_BITMAP* bitmap)
        in
        {
            assert(bitmap !is null);
        }
        body
        {
            _bitmap = bitmap;
            _bitmap.convertTo(ALLEGRO_MEMORY_BITMAP);
        }

        /// Destroys the Bitmap, freeing its resources.
        public void destroy()
        {
            al_destroy_bitmap(_bitmap);
        }

        /// The Allegro Bitmap object.
        private ALLEGRO_BITMAP* _bitmap;
    }

    /**
     * A "Hardware Bitmap", backed by Allegro 5.
     */
    public struct Allegro5HWBitmap
    {
        /**
         * Constructs the Bitmap.
         *
         * Parameters:
         *     width = The Bitmap width, in pixels.
         *     height = The Bitmap height, in pixels.
         *     params = Assorted parameters describing how you want your Bitmap.
         */
        public this(int width, int height, HWBitmapParams params = HWBitmapParams.init)
        {
            // Set the creation flags according to `params`
            int flags = ALLEGRO_VIDEO_BITMAP;

            if (params.scalingQuality >= BitmapScalingQuality.medium)
                flags |= (ALLEGRO_MIN_LINEAR | ALLEGRO_MAG_LINEAR);

            if (params.useMipmaps)
                flags |= ALLEGRO_MIPMAP;

            al_set_new_bitmap_flags(flags);

            // Let there be a bitmap
            _bitmap = al_create_bitmap(width, height);

            // I am not omnipotent, better check if it worked
            if (_bitmap is null)
            {
                throw new BitmapCreationException(
                    "Error creating hardware bitmap.");
            }

            flags = al_get_bitmap_flags(_bitmap);
            if (!(flags & ALLEGRO_VIDEO_BITMAP))
            {
                throw new BitmapCreationException("", "Got a software (MEMORY) "
                    ~ "bitmap instead of a hardware (VIDEO) one. Looks like a "
                    ~ "bug; maybe no Display was created yet?");
            }
        }

        /**
         * Constructs the Bitmap from an `ALLEGRO_BITMAP`.
         *
         * Throws:
         *     BitmapCreationException If something goes wrong.
         */
        private this(ALLEGRO_BITMAP* bitmap)
        {
            _bitmap = bitmap;
            _bitmap.convertTo(ALLEGRO_VIDEO_BITMAP);
        }

        /// Destroys the Bitmap, freeing its resources.
        public void destroy() @nogc nothrow
        {
            al_destroy_bitmap(_bitmap);
        }

        /**
         * Draws the Bitmap to the current render target.
         *
         * Parameters:
         *     x = The horizontal coordinate of the desired draw position. This
         *         is in pixels, with subpixel accuracy.
         *     x = The vertical coordinate of the desired draw position. This
         *         is in pixels, with subpixel accuracy.
         */
        public void draw(float x, float y)
        {
            enum flags = 0;
            al_draw_bitmap(_bitmap, x, y, flags);
        }

        /// The Allegro Bitmap object.
        private ALLEGRO_BITMAP* _bitmap;
    }

    /**
     * Raster subsystem based on the Allegro 5 library.
     *
     * Parameters:
     *     E = The type of the engine using this subsystem.
     */
    public struct Allegro5RasterSubsystem(E)
    {
        import sbxs.engine.raster: RasterCommon;

        mixin RasterCommon!E;

        /// Type for "Hardware Bitmaps".
        public alias HWBitmap = Allegro5HWBitmap;

        /// Type for "Software Bitmaps".
        public alias SWBitmap = Allegro5SWBitmap;

        /// Loads Allegro image addon.
        package(sbxs.engine) void initializeBackend()
        {
            DerelictAllegro5Image.load();
            const success = al_init_image_addon();

            if (!success)
            {
                throw new BackendInitializationException(
                    "Could not load Allegro's image addon");
            }
        }

        /// Shuts Allegro image addon down.
        package(sbxs.engine) void shutdownBackend()
        {
            al_shutdown_image_addon();
        }

        /**
         * Loads an image file and returns it as a "Hardware Bitmap".
         *
         * Parameters:
         *     fileName = Path to the desired file.
         *
         * TODO: I am currently not using premultiplied alpha, but this is
         *     something I should consider doing.
         */
        HWBitmap loadHWBitmap(string fileName)
        {
            import std.string: toStringz;
            ALLEGRO_BITMAP* bitmap = al_load_bitmap_flags(
                fileName.toStringz, ALLEGRO_NO_PREMULTIPLIED_ALPHA);

            if (bitmap is null)
            {
                throw new BitmapCreationException(
                    fileName, "Error loading bitmap from file.");
            }

            if (!(al_get_bitmap_flags(bitmap) & ALLEGRO_VIDEO_BITMAP))
            {
                // Allegro creates hardware (VIDEO) bitmaps by default, if
                // possible. Trying to convert it would be useless -- something
                // is precluding a hardware bitmap to be created (like, there
                // is no active Display).
                throw new BitmapCreationException(fileName, "Bitmap was created "
                    ~ "as a software bitmap, but we expected a hardware one.");
            }

            // If we got to this point, we have a genuine hardware-accelerated
            // bitmap
            return HWBitmap(bitmap);
        }
    }

} // version HaveAllegro5
