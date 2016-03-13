/**
 * SDL 2 back end: helpers.
 *
 * License: MIT License, see the `LICENSE` file.
 *
 * Authors: Leandro Motta Barros.
 */

module sbxs.engine.backends.sdl2.helpers;

version(HasSDL2)
{
    import derelict.sdl2.sdl;

    /// Returns `SDL_GetError()` conveniently converted to a proper `string`.
    package string sdlGetError()
    {
        import std.conv: to;
        return to!string(SDL_GetError());
    }
}
