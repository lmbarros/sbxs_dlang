/**
 * Provides ways to combine several layers of noise in order to create
 * fractal-like noise.
 *
 * I have seen this technique being called
 * $(LINK2 https://code.google.com/p/fractalterraingeneration/wiki/Fractional_Brownian_Motion, fractional Brownian motion),
 * but I am not math literate enough to understand how this would relate to the
 * $(LINK2 https://en.wikipedia.org/wiki/Fractional_Brownian_motion, general concept)
 * of fractional Brownian motion.
 *
 * License: MIT License, see the `LICENSE` file.
 *
 * Authors: Leandro Motta Barros.
 *
 * See_Also:
 *     https://code.google.com/p/fractalterraingeneration/wiki/Fractional_Brownian_Motion
 */

module deever.noise.fractal_noise;

import std.traits;


/// A 1D noise function.
public alias noiseFunc1D(T) = T delegate(T);

/// A 2D noise function.
public alias noiseFunc2D(T) = T delegate(T, T);

/// A 3D noise function.
public alias noiseFunc3D(T) = T delegate(T, T, T);

/// A 4D noise function.
public alias noiseFunc4D(T) = T delegate(T, T, T, T);


/**
 * Creates and returns a function that will generate fractal noise in 1D, 2D, 3D
 * or 4D.
 *
 * The returned function, when called, will sample a given noise function a
 * number of times and combine the results to generate the final noise value.
 *
 * Parameters:
 *     noiseFunc = The function that will be used to generate the noise.
 *     octaves = The number of layers of noise to combine.
 *     lacunarity = For each octave, the frequency is multiplied by this
 *         amount.
 *     gain = For each octave, the amplitude is multiplied by this amount.
 *     frequency = The multiplier to use when sampling the noise function for
 *         the first octave. For each subsequent octave, this value is
 *         multiplied by lacunarity.
 *     amplitude = The multiplier to use for the noise value of the first
 *         octave. For each subsequent octave, this value is multiplied by gain.
 */
public noiseFunc1D!T makeFractalNoiseFunc(T)(
    noiseFunc1D!T noiseFunc, uint octaves, T lacunarity = 2.0, T gain = 0.5,
    T frequency = 1.0, T amplitude = 1.0)
    if (isFloatingPoint!T)
{
    return delegate(T x)
    {
        T sum = 0.0;
        T freq = frequency;
        T amp = amplitude;

        foreach(i; 0..octaves)
        {
            sum += noiseFunc(x * freq) * amp;
            freq *= lacunarity;
            amp *= gain;
        }

        return sum;
    };
}


/// Ditto
public noiseFunc2D!T makeFractalNoiseFunc(T)(
    noiseFunc2D!T noiseFunc, uint octaves, T lacunarity = 2.0, T gain = 0.5,
    T frequency = 1.0, T amplitude = 1.0)
    if (isFloatingPoint!T)
{
    return delegate(T x, T y)
    {
        T sum = 0.0;
        T freq = frequency;
        T amp = amplitude;

        foreach(i; 0..octaves)
        {
            sum += noiseFunc(x * freq, y * freq) * amp;
            freq *= lacunarity;
            amp *= gain;
        }

        return sum;
    };
}


/// Ditto
public noiseFunc3D!T makeFractalNoiseFunc(T)(
    noiseFunc3D!T noiseFunc, uint octaves, T lacunarity = 2.0, T gain = 0.5,
    T frequency = 1.0, T amplitude = 1.0)
    if (isFloatingPoint!T)
{
    return delegate(T x, T y, T z)
    {
        T sum = 0.0;
        T freq = frequency;
        T amp = amplitude;

        foreach(i; 0..octaves)
        {
            sum += noiseFunc(x * freq, y * freq, z * freq) * amp;
            freq *= lacunarity;
            amp *= gain;
        }

        return sum;
    };
}


/// Ditto
public noiseFunc4D!T makeFractalNoiseFunc(T)(
    noiseFunc4D!T noiseFunc, uint octaves, T lacunarity = 2.0, T gain = 0.5,
    T frequency = 1.0, T amplitude = 1.0)
    if (isFloatingPoint!T)
{
    return delegate(T x, T y, T z, T w)
    {
        T sum = 0.0;
        T freq = frequency;
        T amp = amplitude;

        foreach(i; 0..octaves)
        {
            sum += noiseFunc(x * freq, y * freq, z * freq, w * freq) * amp;
            freq *= lacunarity;
            amp *= gain;
        }

        return sum;
    };
}



// -----------------------------------------------------------------------------
// Unit tests
// -----------------------------------------------------------------------------

// Generate fractal noise from a fake noise source, which generates a
// constant value. This doesn't test the fractal noise generation thoroughly,
// but is better than nothing.
unittest
{
    import sbxs.util.test;
    import sbxs.noise.open_simplex_noise;

    enum epsilon = 1e-7;

    // 1D, default gain of 0.5
    auto fracNoise1D = makeFractalNoiseFunc!double((x) => 1.0, 2);
    auto noise = fracNoise1D(0.1);
    assertClose(noise, 1.5, epsilon);

    // 2D, default gain of 0.5
    auto fracNoise2D = makeFractalNoiseFunc!double((x, y) => 1.0, 5);
    noise = fracNoise2D(0.1, 0.2);
    assertClose(noise, 1.9375, epsilon);

    // 3D, gain = 0.8
    auto fracNoise3D = makeFractalNoiseFunc!float((x, y, z) => 1.0, 4, 2.0, 0.8);
    noise = fracNoise3D(2.0, 1.0, -0.3);
    assertClose(noise, 2.952, epsilon);

    // 4D, gain = 0.1
    auto fracNoise4D = makeFractalNoiseFunc!real((x, y, z, w) => 1.0, 3, 2.0, 0.1);
    noise = fracNoise4D(-1.2, 1.1, -10.3, -0.2);
    assertClose(noise, 1.11, epsilon);
}

// This is just to have more real example compiled during tests. I am
// not checking for any value here, I am just calling stuff to be sure
// that it compiles properly and doesn't crash.
unittest
{
    import sbxs.util.test;
    import sbxs.noise.open_simplex_noise;

    // Allocate one noise generator on the heap and one on the stack,
    // just for the sake of it
    auto heapNG = new OpenSimplexNoiseGenerator!double(123);
    auto stackNG = OpenSimplexNoiseGenerator!real(321);

    auto fracNoise2d = makeFractalNoiseFunc!double((x, y) => heapNG.noise(x, y), 5);
    auto noise = fracNoise2d(0.1, 0.2);

    auto fracNoise3d = makeFractalNoiseFunc!real((x, y, z) => stackNG.noise(x, y, z), 4);
    noise = fracNoise3d(0.1, 0.2, 0.3);

    auto fracNoise4d = makeFractalNoiseFunc!real((x, y, z, w) => stackNG.noise(x, y, z, w), 6);
    noise = fracNoise4d(0.1, 0.2, 0.3, 0.4);
}
