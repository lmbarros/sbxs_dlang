/**
 * An engine backed by Allegro 5.
 *
 * License: MIT License, see the `LICENSE` file.
 *
 * Authors: Leandro Motta Barros.
 */

module sbxs.engine.backends.allegro5.engine;

import sbxs.engine;
import sbxs.engine.backends.allegro5;


/**
 * Performs basic Allegro 5 initialization (all the required initialization
 * which is not done by any subsystem).
 *
 * This must be called during the initialization of any Engine based on
 * Allegro 5.
 *
 * Parameters:
 *     E = The type of engine being initialized.
 */
public void initializeAllegro5(E)()
{
    import derelict.allegro5.allegro;
    import derelict.opengl3.gl3;

    // General back end initialization
    DerelictAllegro5.load();

    const success = al_install_system(ALLEGRO_VERSION_INT, null);
    if (!success)
        throw new BackendInitializationException();
}


/// An engine entirely backed by Allegro 5.
public struct Allegro5Engine
{
    mixin EngineCommon;

    /// The display subsystem.
    Allegro5DisplaySubsystem!Allegro5Engine display;

    /// The events subsystem.
    Allegro5EventsSubsystem!Allegro5Engine events;

    /// The operating system subsystem.
    Allegro5OSSubsystem!Allegro5Engine os;

    /// Initializes the Allegro 5 library.
    void initializeBackend()
    {
        initializeAllegro5!(typeof(this))();
    }
}
