/**
 * A mocked engine, for testing.
 *
 * License: MIT License, see the `LICENSE` file.
 *
 * Authors: Leandro Motta Barros.
 */

module sbxs.engine.backends.mocked.engine;

import sbxs.engine;


/// A completely mocked engine.
public struct MockedEngine
{
    import sbxs.engine.backends.mocked;

    mixin EngineCommon;

    /// The display subsystem.
    public MockedDisplaySubsystem!MockedEngine display;

    /// The events subsystem.
    public MockedEventsSubsystem!MockedEngine events;

    /// The time subsystem.
    public MockedTimeSubsystem!MockedEngine time;
}



// Just a dummy test, to make this otherwise code-less file appear as 100%
// covered. I don't want "false negatives" taking my attention instead of real
// issues.
unittest
{
    assert(true);
}
