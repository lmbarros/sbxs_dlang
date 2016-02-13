/**
 * An engine back end based on the Allegro 5 library (and OpenGL).
 *
 * License: MIT License, see the `LICENSE` file.
 *
 * Authors: Leandro Motta Barros.
 *
 * TODO: Add `@nogc`, `nothrow` and friends. Or maybe just templatize
 *     everything.
 */

module sbxs.engine.backend.allegro5;

version(HasAllegro5)
{
    import std.exception: enforce; // TODO: Use proper error handling

    import derelict.allegro5.allegro;
    import derelict.opengl3.gl3;

    /// Back end core subsystem, based on the Allegro 5 library.
    public struct Allegro5BackendCore
    {
        /// Initializes the subsystem.
        public void initialize()
        {
            version(linux)
            {
                // TODO: Make this work portably (and by "portably", I mean "even
                //       across different Linux distros"). This is just a hack I
                //       did to make it work on my system.
                DerelictAllegro5.load("liballegro.so.5.0");
            }
            else
            {
                DerelictAllegro5.load();
            }
            DerelictGL3.load();
            enforce (al_install_system(ALLEGRO_VERSION_INT, null)); // TODO: Do proper error handling
        }

        /// Shuts the subsystem down.
        public void shutdown()
        {
            al_uninstall_system();
        }

        /// Returns the current wall time, in seconds since some unspecified epoch.
        public double getTime()
        {
            return al_get_time();
        }

        /// Sleeps the current thread for a given number of seconds.
        public void sleep(double timeInSecs)
        {
            al_rest(timeInSecs);
        }
    }

    /// Back end display subsystem, based on the Allegro5 library.
    public struct Allegro5BackendDisplay
    {
        /// Initializes the subsystem.
        public void initialize() { }

        /// Shuts the subsystem down.
        public void shutdown() { }
    }

    /// Engine back end based on the Allegro5 library.
    public struct Allegro5Backend
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
        public Allegro5BackendCore core;

        // The display subsystem.
        public Allegro5BackendDisplay display;
    }

} // version HasAllegro5
