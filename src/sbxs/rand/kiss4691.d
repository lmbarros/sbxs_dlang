/**
* George Marsaglia's $(LINK2 http://mathforum.org/kb/message.jspa?messageID=7135312, KISS4691)
* pseudo random number generator.
*
* This one should be a good first choice of algorithm for most applications (at
* least those which don't depend critically on random numbers, and will not get
* people killed or broken if something fails). KISS4691 passes lots of hard
* randomness tests, is simple, very fast and doesn't use too much space (just
* under 16KB).
*
* License: MIT License, see the `LICENSE` file.
*
* Authors: Leandro Motta Barros (but this is actually just an adaptation of
*     Marsaglia's code).
*/

module sbxs.rand.kiss4691;

import sbxs.rand.rng;

version (unittest)
{
    import sbxs.util.test;
}


/// A KISS4691 (pseudo) random number generator.
public struct KISS4691
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
    public enum maxValue = uint.max;

    /// Returns a (pseudo) random number between 0 and `maxValue`.
    public uint draw()
    {
        return mwc() + lcg() + xs();
    }

    /// Seeds (initializes) this generator with two given seed values.
    public void seed(uint seed1, uint seed2)
    {
        _xss = seed1;
        _lcgs = seed2;
        _c = 0;
        _j = _qSize;

        foreach (i; 0.._qSize)
            _q[i] = lcg() + xs();
    }


    /// Seeds (initializes) this generator with a given `seed` value.
    public void seed(ulong seed)
    {
        uint seed1 = seed & 0xFFFF_FFFF;
        uint seed2 = seed >> 32;
        this.seed(seed1, seed2);
    }

    /// The multiply-with-carry component of KISS.
    private uint mwc()
    {
        _j = _j < (_qSize - 1) ? _j + 1 : 0;
        const x = _q[_j];
        const t = (x << 13) + _c + x;
        _c = (t < x ? 1 : 0) + (x >> 19);
        _q[_j] = t;

        return t;
    }

    /// The linear congruential component of KISS.
    private uint lcg()
    {
        _lcgs = 69069 * _lcgs + 123;
        return _lcgs;
    }

    /// The xor-shift component of KISS.
    private uint xs()
    {
        _xss = _xss ^ (_xss << 13);
        _xss = _xss ^ (_xss >> 17);
        _xss = _xss ^ (_xss << 5);
        return _xss;
    }

    /// Xor-shift state.
    private uint _xss;

    /// Linear congruential state.
    private uint _lcgs;

    /// Multiply-with-carry state.
    private uint[_qSize] _q;

    /// Ditto
    private uint _c;

    /// Ditto
    private uint _j;

    /// Constant for multiply-with-carry state aray.
    private enum _qSize = 4691;
}



// -----------------------------------------------------------------------------
// Unit tests
// -----------------------------------------------------------------------------

// Make sure this is a random number generator, according to my own criteria
static assert(isRNG!KISS4691);


// Test `draw()`, comparing obtained results with those from the reference C
// implementation by George Marsaglia.
unittest
{
    auto rng = KISS4691(521288629, 362436069);

    foreach (i; 0..1000)
        rng.draw().assertBetween(0, rng.maxValue);

    assert(rng.draw() == 3364474229);
    assert(rng.draw() == 1115729069);
    assert(rng.draw() == 3399743299);
    assert(rng.draw() == 2505783051);
    assert(rng.draw() == 4238293872);
}

// Same as above, but using the single-parameter constructor.
unittest
{
    auto rng = KISS4691(521288629UL | (362436069UL << 32));

    foreach (i; 0..1000)
        rng.draw().assertBetween(0, rng.maxValue);

    assert(rng.draw() == 3364474229);
    assert(rng.draw() == 1115729069);
    assert(rng.draw() == 3399743299);
    assert(rng.draw() == 2505783051);
    assert(rng.draw() == 4238293872);
}

// Call the "base" RNG functions, just to be sure they compile.
unittest
{
    import std.datetime;

    KISS4691 rng;

    rng.uniform(0.0, 1.0).assertBetween(0.0, 1.0);
    rng.uniform(1, 6).assertBetween(1, 6);
    assert(rng.bernoulli(1.0));
    rng.exponential(1.2);
    rng.normal(0.0, 1.3);
    rng.drawFromEnum!DayOfWeek();
}
