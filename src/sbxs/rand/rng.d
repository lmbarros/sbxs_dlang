/**
 * Base definitions for random number generators.
 *
 * This was not made to be compatible with Phobos' random number generators.
 *
 * License: MIT License, see the `LICENSE` file.
 *
 * Authors: Leandro Motta Barros.
 */

module sbxs.rand.rng;

import std.traits;

version(unittest)
{
   import sbxs.math.stats;
   import sbxs.util.test;
}


/**
 * Checks if something is a random number generator.
 *
 * In addition to what is tested here, a typical implementation will also
 * provide a `seed()` method, but this is actually not a requirement (think of
 * real random number generators).
 */
public enum isRNG(T) =
   // RNGs must provide a `maxValue` property which is an unsigned number and
   // represents the maximum value the generator can possibly generate. It is
   // assumed that the minimum is zero.
   isUnsigned!(typeof(T.maxValue))

   // RNGs must provide a `draw()` method, which generates a (pseudo) number as
   // some unsigned value.
   && isUnsigned!(typeof(T.draw()));


/**
 * Uses `rng` to generate a floating point number between `a`
 * and `b` (interval closed at both ends); returns this number.
 *
 * `a` cannot be larger than `b`.
 */
public T uniform(T, RNG)(ref RNG rng, T a, T b)
    if (isRNG!RNG && isFloatingPoint!T)
in
{
    assert(a <= b);
}
body
{
    return (T(rng.draw()) / T(rng.maxValue)) * (b - a) + a;
}

// Tests `uniform()` for floating point values
unittest
{
    TestRNG rng;
    rng.seed(12345);

    enum n = 1000;

    // Helper to test non degenerate intervals. Doesn't really guarantee anything
    // -- and doesn't even try to test if the distribution is uniform. But at
    // least ensures no number will be out of the requested range.
    void testInterval(T)(T a, T b)
        if (isFloatingPoint!T)
    in
    {
        assert(a < b);
    }
    body
    {
        foreach (i; 0..n)
        {
            const r = rng.uniform(a, b);
            r.assertBetween(a, b);
        }
    }

    // Test some interesting intervals
    testInterval(  0.0,  1.0);
    testInterval(  1.0,  3.3);
    testInterval(-10.0, -2.0);
    testInterval( -2.20, 4.3);
    testInterval( -1.50, 0.0);

    // Test two degenerate (but still valid) intervals: a == b, with
    // float and double
    foreach (i; 0..n)
    {
        const r = rng.uniform(5.0, 5.0);
        assert(r == 5.0);
    }

    foreach (i; 0..n)
    {
        const r = rng.uniform(-3.0f, -3.0f);
        assert(r == -3.0f);
    }
}


/**
 * Uses `rng` to generate an integer number between `a` and `b` (interval
 * closed at both ends); returns this number.
 *
 * `a` cannot be larger than `b`.
 *
 * This uses a simple logic, based on the modulus operator. This has at least
 * two consequences:
 *
 * $(OL
 *    $(LI It will only produce a reasonably uniform distribution if
 *         `abs(b - a)` is much smaller than `rng.maxValue`. In other words,
 *          this is OK to simulate rolls of dice, but will generate skewed
 *          distributions if used to generate random numbers in a large
 *          interval like, perhaps, 0 to 1_000_000.)
 *
 *    $(LI The quality of the random number generator -- especially of
 *      the lower-order bits -- is very important to guarantee a good
 *      uniformity in the generated distribution.)
 * )
 *
 * TODO: Implement a version that works for large intervals. See
 *     http://stackoverflow.com/a/6852396, for example.
 */
public T uniform(T, RNG)(ref RNG rng, T a, T b)
    if (isRNG!RNG && isIntegral!T)
in
{
    assert(a <= b);
}
body
{
    const base = cast(ulong)(rng.draw()) % cast(ulong)(b - a + 1);
    return cast(T)(base + a);
}

// Tests `uniform` for integer values
unittest
{
    TestRNG rng;
    rng.seed(-9876);

    enum n = 1000;

    // Helper to test non degenerate intervals. Please use intervals much smaller
    // than `n`, so that the `wasGenerated` logic has a good chance to work.
    void testInterval(T)(T a, T b)
        if (isIntegral!T)
    in
    {
        assert(a < b);
    }
    body
    {
        bool[T] wasGenerated;

        foreach(T i; a..b+1)
            wasGenerated[i] = false;

        // Try the interval passed in
        foreach (i; 0..n)
        {
            const r = rng.uniform(a, b);
            r.assertBetween(a, b);
            wasGenerated[r] = true;
        }

        // Check if all numbers in the range were generated
        foreach (T i; a..b+1)
            assert(wasGenerated[i]);
    }

    // Test some interesting intervals
    testInterval(1, 6);
    testInterval(0, 4);
    testInterval(-10, -2);
    testInterval(-2, 4);
    testInterval(-4, 0);

    // Try with some different integer types, too
    testInterval(ushort(4), ushort(7));
    testInterval(byte(4), byte(12));
}


/**
 * Uses `rng` to generate a Boolean random value, which has a probability `p` of
 * being `true` (a Bernoulli distribution).
 *
 * For `p <= 0`, `false` is always returned. For `p >= 1`,
 * `true` is always returned.
 */
public bool bernoulli(T, RNG)(ref RNG rng, T p)
    if (isRNG!RNG && isFloatingPoint!T)
{
    return cast(T)(rng.draw()) < cast(T)(rng.maxValue) * p;
}

// Tests `bernoulli()`
unittest
{
    TestRNG rng;
    rng.seed(ushort(365));

    enum n = 5000;
    enum epsilon = 0.05; // for `assertClose()`; cannot be too strict for such
                         // small `n`

    // Helper to test with arbitrary p
    void testWithP(double p, float expectedP)
    {
        auto numTrues = 0;
        foreach(i; 0..n)
        {
            if (rng.bernoulli(p))
                ++numTrues;
       }
       assertClose(cast(double)(numTrues) / n, expectedP, epsilon);
    }

    // Test with some values of p
    testWithP(0.5, 0.5);
    testWithP(0.0, 0.0);
    testWithP(0.2, 0.2);
    testWithP(0.7, 0.7);
    testWithP(1.0, 1.0);

    testWithP(-1.1, 0.0);
    testWithP(-100.0, 0.0);
    testWithP(1.1, 1.0);
    testWithP(100.0, 1.0);
}


/**
 * Uses `rng` to generate a floating point random value from an exponential
 * distribution with mean `mean`.
 */
public T exponential(T, RNG)(ref RNG rng, T mean)
    if (isRNG!RNG && isFloatingPoint!T)
{
    import std.math: log;

    const r01 = cast(T)(rng.draw()) / cast(T)(rng.maxValue);
    return -mean * log(r01);
}

// Tests `exponential()` -- er, kinda. I don't make any effort to ensure that
// the numbers are really drawn from an exponential distribution
unittest
{
    TestRNG rng;
    rng.seed(11111111);

    enum n = 5000;
    enum epsilon = 0.05; // for such a small `n`, a relatively large `epsilon`

    double[n] vals;

    // Helper to test `exponential` with a given mean
    void testWithMean(double m)
    {
        foreach (i; 0..n)
            vals[i] = rng.exponential(m);

        assertClose(vals[].mean(), m, epsilon);
    }

    // Test some mean values
    testWithMean(1.0);
    testWithMean(2.0);
    testWithMean(33.3);
    testWithMean(-1.0);
    testWithMean(-0.1);
    testWithMean(0.0);
}

/**
 * Uses `rng` to generate a floating point random value from a normal (Gaussian)
 * distribution with mean `mean`and standard deviation `stdDev`.
 *
 * `stdDev` must be non negative.
 *
 * This implements an algorithm by Peter John Acklam for computing an
 * approximation of the inverse normal cumulative distribution function. It seems
 * to be pretty accurate, but be warned that it is an approximation and may not
 * good enough for your needs.
 *
 * See_also: http://home.online.no/~pjacklam/notes/invnorm/
 */
public double normal(T, U, RNG)(ref RNG rng, T mean, U stdDev)
    if (isRNG!RNG && isNumeric!T && isNumeric!U)
in
{
    assert(stdDev >= 0);
}
body
{
    import std.math: sqrt, log;

    enum
    {
        // Coefficients in rational approximations
        a1 = -3.969683028665376e+01,
        a2 =  2.209460984245205e+02,
        a3 = -2.759285104469687e+02,
        a4 =  1.383577518672690e+02,
        a5 = -3.066479806614716e+01,
        a6 =  2.506628277459239e+00,

        b1 = -5.447609879822406e+01,
        b2 =  1.615858368580409e+02,
        b3 = -1.556989798598866e+02,
        b4 =  6.680131188771972e+01,
        b5 = -1.328068155288572e+01,

        c1 = -7.784894002430293e-03,
        c2 = -3.223964580411365e-01,
        c3 = -2.400758277161838e+00,
        c4 = -2.549732539343734e+00,
        c5 =  4.374664141464968e+00,
        c6 =  2.938163982698783e+00,

        d1 =  7.784695709041462e-03,
        d2 =  3.224671290700398e-01,
        d3 =  2.445134137142996e+00,
        d4 =  3.754408661907416e+00,

        // Break-points
        pLow  = 0.02425,
        pHigh = 1 - pLow,
    }

    // Input and output variables
    auto p = 0.0;
    while (p <= 0.0 || p >= 1.0)
        p = cast(double)(rng.draw()) / cast(double)(rng.maxValue);

    assert(p > 0.0 && p < 1.0, "`p` must be in the open interval (0, 1)");

    double x;

    // Rational approximation for lower region
    if (p < pLow)
    {
        const q = sqrt(-2 * log(p));
        x = (((((c1 * q + c2) * q + c3) * q + c4) * q + c5) * q + c6) /
            ((((d1 * q + d2) * q + d3) * q + d4) * q + 1);
    }

    // Rational approximation for central region
    else if (p <= pHigh)
    {
       const q = p - 0.5;
       const r = q * q;
       x = (((((a1 * r + a2) * r + a3) * r + a4) * r + a5) * r + a6) * q /
           (((((b1 * r + b2) * r + b3) * r + b4) * r + b5) * r + 1);
    }

    //  Rational approximation for upper region
    else
    {
        assert(p > pHigh);
        const q = sqrt(-2 * log(1-p));
        x = -(((((c1 * q + c2) * q + c3) * q + c4) * q + c5) * q + c6) /
            ((((d1 * q + d2) * q + d3) * q + d4) * q + 1);
    }

    // There we are
    return x * stdDev + mean;
}


// Tests `normal` -- again, I don't make any effort to ensure that the
// numbers are really drawn from a normal distribution.
unittest
{
    TestRNG rng;
    rng.seed(-500001);

    enum n = 2000;
    enum epsilon = 0.05; // for such a small `n`, a relatively large `epsilon`

    double[n] vals;

    // Helper to test with given parameters
    void testWithParams(double mean, double stdDev)
    {
        foreach (i; 0..n)
            vals[i] = rng.normal(mean, stdDev);

        auto actualMean = vals[].mean();
        assertClose(actualMean, mean, epsilon);
        assertClose(vals[].standardDeviation(actualMean), stdDev, epsilon);
    }

    // Test with some parameters
    testWithParams(0.1, 1.0);
    testWithParams(1.0, 0.1);
    testWithParams(10.0, 3.0);
    testWithParams(-5.0, 3.0);
}


/**
 * Uses `self` to draw one of the possible values in enumeration `E`.
 *
 * This doesn't work with enumerations with holes.
 */
public E drawFromEnum(E, RNG)(ref RNG rng)
    if (isRNG!RNG && is (E == enum))
{
     const r = rng.uniform(E.min, E.max);
     return cast(E)(r);
}

// Tests `draw()` (from enumeration)
unittest
{
    TestRNG rng;
    rng.seed(657483);

    enum n = 1000;

    enum firstEnum { feA, feB, feC }
    enum secondEnum { seA = 171, seB, seC, seD, seE }

    bool[firstEnum] firstArray = [
        firstEnum.feA: false,
        firstEnum.feB: false,
        firstEnum.feC: false ];

    bool[secondEnum] secondArray = [
        secondEnum.seA: false,
        secondEnum.seB: false,
        secondEnum.seC: false,
        secondEnum.seD: false,
        secondEnum.seD: false ];

    // First enumeration
    foreach (i; 0..n)
    {
        const r = rng.drawFromEnum!firstEnum();
        firstArray[r] = true;
    }

    foreach (i; EnumMembers!firstEnum)
        assert(firstArray[i]);

    // Second enumeration
    foreach (i; 0..n)
    {
        const r = rng.drawFromEnum!secondEnum();
        secondArray[r] = true;
    }

    foreach (i; EnumMembers!secondEnum)
        assert(secondArray[i]);
}


// -----------------------------------------------------------------------------
// Unit test helpers
// -----------------------------------------------------------------------------

version (unittest)
{
    // This is a minimal implementation of a compliant RNG, just for the sake of
    // testing. If you are looking for a linear congruential generator, look at
    // the `knuth_lcg` module, which has a presumably better implementation than
    // this one -- well, it has "Knuth" in the name, so it must be good, right?
    private struct TestRNG
    {
        private uint _state;

        public enum maxValue = uint.max;

        public uint draw()
        {
            _state = 1103515245u * _state + 12345u;
            return _state;
        }

        public void seed(T)(T s)
        {
            _state = cast(uint)s;
        }
    }

    static assert(isRNG!TestRNG);
}
