/**
 * A 64-bit $(LINK2 https://en.wikipedia.org/wiki/Linear_congruential_generator, linear congruential)
 * pseudo random number generator (LCG).
 *
 * The multiplier and increment used here were apparently suggested by Don
 * Knuth, though I have taken them from Wikipedia, not from any primary source.
 *
 * This is included because it is a classic. Any of the other algorithms
 * included here should be a better alternative to this one.
 *
 * License: MIT License, see the `LICENSE` file.
 *
 * Authors: Leandro Motta Barros.
 */

module sbxs.rand.knuth_lcg;

import std.traits: isIntegral;
import sbxs.rand.rng;

version (unittest)
{
    import sbxs.util.test;
}


/// A 64-bit linear congruential (pseudo) random number generator.
public struct KnuthLCG
{
    /// Constructs the generator from a given seed.
    public this(ulong seed)
    {
        this.seed(seed);
    }

    /// The maximum value this RNG will ever return.
    public enum maxValue = ulong.max;

    /// Returns a (pseudo) random number between 0 and `maxValue`.
    public ulong draw()
    {
        _state = 6364136223846793005 * _state + 1442695040888963407;
        return _state;
    }

    /// Seeds (initializes) this generator with a given `seed` value.
    public void seed(T)(T seed)
        if (isIntegral!T)
    {
        _state = cast(ulong)seed;
    }

    /// The RNG state.
    private ulong _state;
}



// -----------------------------------------------------------------------------
// Unit tests
// -----------------------------------------------------------------------------

// Make sure this is a random number generator, according to my own criteria
static assert(isRNG!KnuthLCG);

// Test `draw()`.
unittest
{
    auto rng = KnuthLCG(112233);

    // Call `draw()` 1000 times, checking if values are in range. Well,
    // considering it is an `ulong`, it cannot be out of range, but anyway
    foreach (i; 0..1000)
        rng.draw().assertBetween(0, rng.maxValue);

    // Check the next few values, comparing them those generated by a C
    // implementation I found somewhere
    assert(rng.draw() == 14373087394460283212UL);
    assert(rng.draw() == 17919820627726294955UL);
    assert(rng.draw() == 2374928239783487326UL);
    assert(rng.draw() == 1355612529541287637UL);
    assert(rng.draw() == 14300717203320031168UL);

    // Again, with a different seed
    rng.seed(97531);
    foreach (i; 0..1000)
        rng.draw().assertBetween(0, rng.maxValue);

    assert(rng.draw() == 2475730772265627958UL);
    assert(rng.draw() == 16585264879776313805UL);
    assert(rng.draw() == 10829226592693777752UL);
    assert(rng.draw() == 4337668493995821511UL);
    assert(rng.draw() == 13619766792622649930UL);
}

// Call the "base" RNG functions, just to be sure they compile.
unittest
{
    import std.datetime;

    auto rng = KnuthLCG(1234);

    rng.uniform(0.0, 1.0).assertBetween(0.0, 1.0);
    rng.uniform(1, 6).assertBetween(1, 6);
    assert(rng.bernoulli(1.0));
    rng.exponential(1.2);
    rng.normal(0.0, 1.3);
    rng.drawFromEnum!DayOfWeek();
}
