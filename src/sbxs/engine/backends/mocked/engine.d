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
    MockedDisplaySubsystem!MockedEngine display;

    /// The events subsystem.
    MockedEventsSubsystem!MockedEngine events;

    /// The time subsystem.
    MockedTimeSubsystem!MockedEngine time;
}
