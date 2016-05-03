/**
 * Engine display subsystem based on Allegro 5.
 *
 * License: MIT License, see the `LICENSE` file.
 *
 * Authors: Leandro Motta Barros.
 */

module sbxs.engine.backends.allegro5.display;

version(HaveAllegro5)
{
    import derelict.allegro5.allegro;
    import derelict.opengl3.gl3;
    import sbxs.engine;


    /**
     * Allegro 5 implementation of a Display.
     *
     * Note: Displays have reference semantics, despite being implemented as
     *     `struct`s! You must create all your Displays through the Display
     *     subsystem, which owns all Displays and is responsible for their
     *     destruction.
     */
    public struct Allegro5Display
    {
        /**
         * Constructs the `Allegro5Display`.
         *
         * Parameters:
         *     params = The parameters specifying how the Display shall be like.
         */
        package(sbxs.engine) this(DisplayParams params)
        {
            // Set the flags for newly created windows according to what the
            // caller asked for
            int flags = ALLEGRO_OPENGL_3_0 | ALLEGRO_OPENGL;

            // TODO: Add `ALLEGRO_PROGRAMMABLE_PIPELINE` when it become
            //     available (since Allegro 5.0.16).

            switch (params.windowingMode)
            {
                case WindowingMode.fullScreen: flags |= ALLEGRO_FULLSCREEN; break;
                case WindowingMode.fakeFullScreen: flags |= ALLEGRO_FULLSCREEN_WINDOW; break;
                default: flags |= ALLEGRO_WINDOWED; break;
            }

            if (!params.decorations)
                flags |= ALLEGRO_FRAMELESS;

            if (params.resizable)
                flags |= ALLEGRO_RESIZABLE;

            if (params.wantsExposeEvents)
                flags |= ALLEGRO_GENERATE_EXPOSE_EVENTS;

            al_set_new_display_flags(flags);

            // Create the display
            _display = al_create_display(params.width, params.height);
            if (_display is null)
                throw new DisplayCreationException();

            scope(failure)
                al_destroy_display(_display);

            import std.string: toStringz;
            _title = params.title;
            al_set_window_title(_display, _title.toStringz);

            // Allegro creates new Displays as the current one; let the
            // internal state reflect this.
            _currentDisplay = _display;

            // Now that we have a context, we can reload the OpenGL bindings, and
            // we'll get all the OpenGL 3+ stuff
            DerelictGL3.reload();
        }

        /// Destroys the Display.
        package(sbxs.engine) void destroy() nothrow @nogc
        {
            al_destroy_display(_display);
        }

        /// The Display width, in pixels.
        public @property int width() nothrow @nogc
        {
            return al_get_display_width(_display);
        }

        /// The Display height, in pixels.
        public @property int height() nothrow @nogc
        {
            return al_get_display_height(_display);
        }

        /// The Display title.
        public @property string title() nothrow @nogc const
        {
            return _title;
        }

        /// Make this Display the current target for rendering.
        public void makeCurrent() nothrow @nogc
        {
            if (_currentDisplay != _display)
            {
                al_set_target_bitmap(al_get_backbuffer(_display));
                _currentDisplay = _display;
            }
        }

        /**
         * Swap buffers, show stuff.
         *
         * This implementation might not be terribly efficent,
         * especially when more than one Display is used.
         */
        public void swapBuffers() nothrow @nogc
        {
            if (_display !is null && _currentDisplay != _display)
                al_set_target_bitmap(al_get_backbuffer(_display));

            al_flip_display();

            if (_currentDisplay !is null && _currentDisplay != _display)
                al_set_target_bitmap(al_get_backbuffer(_currentDisplay));
        }

        /// A handle that uniquely identifies this Display.
        public @property handleType handle() nothrow @nogc
        {
            return cast(handleType)(_display);
        }

        /// The Allegro object representing the Display.
        private ALLEGRO_DISPLAY* _display;

        /// The Display title (Allegro does not provide means to read it!).
        private string _title;

        /// A handle different than any valid Display handle.
        public enum invalidDisplay = null;

        /**
         * The Display currently active. `null` if no Display was created yet.
         *
         * TODO: Maybe will also be `null` when an off-screen render target is
         *     active.
         */
        private static ALLEGRO_DISPLAY* _currentDisplay = null;

        /// A type for a handle that uniquely identifies a Display.
        public alias handleType = size_t;
    }


    /**
     * Display engine subsystem back end, based on the Allegro 5 library.
     *
     * Parameters:
     *     E = The type of the engine using this subsystem back end.
     */
    public struct Allegro5DisplaySubsystem(E)
    {
        mixin DisplayCommon!E;

        /// The type used as Display.
        public alias Display = Allegro5Display;

        /// Initializes the OpenGL bindings.
        public void initializeBackend()
        {
            DerelictGL3.load();
        }
    }

} // version HaveAllegro5
