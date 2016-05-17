/**
 * The Xoroshiro128+ random number generator.
 *
 * This should be another good first choice of algorithm for most applications
 * which don't depend critically on random numbers and will not get people
 * killed or broken if something fails. It is astonishingly fast, uses only 16
 * bytes of state and has a decent (if not astronomical) period of 2^128 - 1.
 * It also passes lots of hard randomness tests.
 *
 * If you are curious (I was), "xoroshiro" stands for
 * "XOr/ROtate/SHIft/ROtate".
 *
 * License: MIT License, see the `LICENSE` file.
 *
 * Authors: Leandro Motta Barros (actually, just a translation to D of the
 *     $(LINK2 http://xoroshiro.di.unimi.it/xoroshiro128plus.c, public domain C code)
 *     by David Blackman and Sebastiano Vigna).
 */

module sbxs.rand.xoroshiro128plus;

import sbxs.rand.rng;

version (unittest)
{
    import sbxs.util.test;
}


/// A Xoroshiro128+ (pseudo) random number generator.
public struct Xoroshiro128plus
{
    /// Constructs the generator from a given seed or seeds.
    public this(uint seed1, uint seed2)
    {
        this.seed(seed1, seed2);
    }

    /// Ditto
    public this(ulong seed)
    {
        this.seed(seed);
    }

    /// The maximum value this RNG will ever return.
    public enum maxValue = ulong.max;

    /// Returns a (pseudo) random number between 0 and `maxValue`.
    public ulong draw() @nogc nothrow pure
    {
        const s0 = _state[0];
        auto s1 = _state[1];
        const result = s0 + s1;

        s1 ^= s0;
        _state[0] = rotl(s0, 55) ^ s1 ^ (s1 << 14);
        _state[1] = rotl(s1, 36);

        return result;
    }

    /// Seeds (initializes) this generator with two given seed values.
    public void seed(ulong seed1, ulong seed2)
    {
        _state[0] = seed1;
        _state[1] = seed2;
    }

    /// Seeds (initializes) this generator with a given seed value.
    public void seed(ulong theSeed)
    {
        // Use a SplitMix64 to generate the seeds
        import sbxs.rand.splitmix64;

        auto sm = SplitMix64(theSeed);
        seed(sm.draw(), sm.draw());
    }

    /// Rotate `x` left by `k` bits.
    private ulong rotl(ulong x, int k) @nogc nothrow pure
    {
        return (x << k) | (x >> (64 - k));
    }

    /// The RNG state.
    private ulong[2] _state;
}



// -----------------------------------------------------------------------------
// Unit tests
// -----------------------------------------------------------------------------

// Make sure this is a random number generator, according to my own criteria
static assert(isRNG!Xoroshiro128plus);

// Test `draw()`, comparing obtained results with those from the reference
// C implementation
unittest
{
    auto rng = Xoroshiro128plus(521288629, 362436069);

    foreach (i; 0..1000)
        rng.draw().assertBetween(0, rng.maxValue);

    assert(rng.draw() == 14087298434708121260UL);
    assert(rng.draw() == 11055104410211319733UL);
    assert(rng.draw() == 4010580528061639590UL);
    assert(rng.draw() == 2807442956520957059UL);
    assert(rng.draw() == 12737219591460154268UL);
}

// Same as above, but using the single-parameter constructor.
unittest
{
    auto rng = Xoroshiro128plus(13579);

    foreach (i; 0..1000)
        rng.draw().assertBetween(0, rng.maxValue);

    assert(rng.draw() == 5883773771842788424UL);
    assert(rng.draw() == 9989605189133216712UL);
    assert(rng.draw() == 7811117801491353185UL);
    assert(rng.draw() == 4706773927854861091UL);
    assert(rng.draw() == 17379387784680010921UL);
}

// Call the "base" RNG functions, just to be sure they compile.
unittest
{
    import std.datetime;

    auto rng = Xoroshiro128plus(1234);

    rng.uniform(0.0, 1.0).assertBetween(0.0, 1.0);
    rng.uniform(1, 6).assertBetween(1, 6);
    assert(rng.bernoulli(1.0));
    rng.exponential(1.2);
    rng.normal(0.0, 1.3);
    rng.drawFromEnum!DayOfWeek();
}
