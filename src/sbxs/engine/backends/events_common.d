/**
 * Events-related things which are shared among some different back ends.
 *
 * License: MIT License, see the `LICENSE` file.
 *
 * Authors: Leandro Motta Barros.
 */

module sbxs.engine.backends.events_common;


/// Data associated with tick events.
package struct TickEventData
{
    /// Time elapsed since the last tick event, in seconds.
    public double deltaTimeInSecs;

    /// Time elapsed since the program started to run, in seconds.
    public double tickTimeInSecs;
}


/// Data associated with draw events.
package struct DrawEventData
{
    /// Time elapsed since the program started to run, in seconds.
    public double drawingTimeInSecs;

    /// Time elapsed since the last tick event, in seconds.
    public double timeSinceTickInSecs;
}