/**
 * Assorted mathematical utilities for dealing with angles.
 *
 * Authors: Leandro Motta Barros.
 */

module sbxs.math.angles;

import std.math;
import std.traits;


/// Converts a given angle from degrees to radians.
public @safe nothrow pure @nogc auto degToRad(T)(T angleDeg)
    if (isNumeric!T)
{
    enum r = (2 * PI) / 360.0;

    static if (isFloatingPoint!T)
        return angleDeg * r;
    else
        return cast(real)angleDeg * r;
}

/// Converts a given angle from radians to degrees.
public @safe nothrow pure @nogc auto radToDeg(T)(T angleRad)
    if (isNumeric!T)
{
    enum r = 360.0 / (2 * PI);

    static if (isFloatingPoint!T)
        return angleRad * r;
    else
        return cast(real)angleRad * r;
}

/**
 * Returns an angle equivalent to a given one, but restricted to the [-π, +π]
 * interval.
 *
 * Yeah, -π and +π refer to the same angle, so there is some overlapping in the
 * output range. But this shouldn't be a problem in practical usage -- certainly
 * not one justifying the extra checks necessary to make the function work in a
 * half-open interval.
 *
 * Parameters:
 *     theta = An angle, in radians.
 *
 * Returns:
 *     An angle equivalent to `theta`, but in the [-π, +π] interval.
 *
 * Authors: Leandro Motta Barros, adapted from "3D Math Primer for Graphics and
 *     Game Development, Second Edition", by Fletcher Dunn and Ian Parberry.
 */
public @safe nothrow pure @nogc T wrapPi(T)(T theta)
    if (isFloatingPoint!T)
{
    enum twoPi = 2 * PI;

    if (abs(theta) > PI)
    {
        const revolutions = floor((theta + PI) * (1.0 / twoPi));
        theta -= revolutions * twoPi;
    }
    return theta;
}



// -----------------------------------------------------------------------------
// Unit tests
// -----------------------------------------------------------------------------

// Degrees to radians
unittest
{
    import sbxs.util.test;
    enum epsilon = 1e-7;

    // Cardinal directions
    assertClose(degToRad(0), 0.0, epsilon);
    assertClose(degToRad(0.0), 0.0, epsilon);

    assertClose(degToRad(90), PI/2, epsilon);
    assertClose(degToRad(90.0), PI/2, epsilon);

    assertClose(degToRad(180), PI, epsilon);
    assertClose(degToRad(180.0), PI, epsilon);

    assertClose(degToRad(270), 3*PI/2, epsilon);
    assertClose(degToRad(270.0), 3*PI/2, epsilon);

    assertClose(degToRad(360), 2*PI, epsilon);
    assertClose(degToRad(360.0), 2*PI, epsilon);

    // Some directions between the cardinal ones
    assertClose(degToRad(45), 0.785398163, epsilon);
    assertClose(degToRad(45.0), 0.785398163, epsilon);
    assertClose(degToRad(33.2), 0.579449312, epsilon);
    assertClose(degToRad(117.3), 2.04727121, epsilon);
    assertClose(degToRad(250.6), 4.37379511, epsilon);
    assertClose(degToRad(350.4), 6.1156337, epsilon);

    // Negative angles and angles greater than 360 degrees
    assertClose(degToRad(-77.7), -1.35612083, epsilon);
    assertClose(degToRad(-188.8), -3.29518163, epsilon);
    assertClose(degToRad(-357.5), -6.23955208, epsilon);
    assertClose(degToRad(-587.1), -10.246828, epsilon);
    assertClose(degToRad(-2345.6), -40.9384429, epsilon);

    assertClose(degToRad(411.3), 7.17853921, epsilon);
    assertClose(degToRad(679.4), 11.8577669, epsilon);
    assertClose(degToRad(5432.1), 94.8080303, epsilon);

    // Ensure this works in compile-time also
    enum a = degToRad(180);
    assertClose(a, PI, epsilon);

    enum b = degToRad(-23.4);
    assertClose(b, -0.408407045, epsilon);
}


// Radians to degrees
unittest
{
    import sbxs.util.test;
    enum epsilon = 1e-7;

    // Cardinal directions
    assertClose(radToDeg(0), 0.0, epsilon);
    assertClose(radToDeg(0.0), 0.0, epsilon);
    assertClose(radToDeg(PI/2), 90, epsilon);
    assertClose(radToDeg(PI), 180, epsilon);
    assertClose(radToDeg(3*PI/2), 270, epsilon);
    assertClose(radToDeg(2*PI), 360, epsilon);

    // Some directions between the cardinal ones
    assertClose(radToDeg(0.785398163), 45.0, epsilon);
    assertClose(radToDeg(0.579449312), 33.2, epsilon);
    assertClose(radToDeg(2.04727121), 117.3, epsilon);
    assertClose(radToDeg(4.37379511), 250.6, epsilon);
    assertClose(radToDeg(6.1156337), 350.4, epsilon);

    // Negative angles and angles greater than 360 degrees
    assertClose(radToDeg(-1.35612083), -77.7, epsilon);
    assertClose(radToDeg(-3.29518163), -188.8, epsilon);
    assertClose(radToDeg(-6.23955208), -357.5, epsilon);
    assertClose(radToDeg(-10.246828), -587.1, epsilon);
    assertClose(radToDeg(-40.9384429), -2345.6, epsilon);

    assertClose(radToDeg(7.17853921), 411.3, epsilon);
    assertClose(radToDeg(11.8577669), 679.4, epsilon);
    assertClose(radToDeg(94.8080303), 5432.1, epsilon);

    // Ensure this works in compile-time also
    enum a = radToDeg(PI);
    assertClose(a, 180, epsilon);

    enum b = radToDeg(-0.408407045);
    assertClose(b, -23.4, epsilon);
}


// Consistency between degToRad() and radToDeg()
unittest
{
    import sbxs.util.test;
    enum epsilon = 1e-7;

    double theta = -2000.0;
    while (theta < 2000.0)
    {
        assertClose(radToDeg(degToRad(theta)), theta, epsilon);
        theta += 2.3;
    }
}


// wrapPi()
unittest
{
    import sbxs.util.test;
    enum epsilon = 1e-7;

    // Some easy cases
    assertClose(wrapPi(0.0), 0.0, epsilon);
    assertClose(wrapPi(1.234), 1.234, epsilon);
    assertClose(wrapPi(-1.234), -1.234, epsilon);

    // Corner cases: values near π and -π
    assertClose(abs(wrapPi(PI)), PI, epsilon);
    assertClose(abs(wrapPi(-PI)), PI, epsilon);
    assertClose(wrapPi(-PI+2*double.epsilon), -PI, epsilon);
    assertClose(wrapPi(2*PI + -PI), PI, epsilon);

    // The expected use-cases: values well off the [-π, +π] interval
    assertSmall(wrapPi(8*PI), epsilon);
    assertSmall(wrapPi(-10*PI), epsilon);

    assertClose(wrapPi(1.23 + 14*PI), 1.23, epsilon);
    assertClose(wrapPi(0.2 + 4*PI), 0.2, epsilon);
    assertClose(wrapPi(3.1 + 6*PI), 3.1, epsilon);

    assertClose(wrapPi(-1.2 - 14*PI), -1.2, epsilon);
    assertClose(wrapPi(-2.8 - 12*PI), -2.8, epsilon);
    assertClose(wrapPi(-3.1 - 2*PI), -3.1, epsilon);
}
