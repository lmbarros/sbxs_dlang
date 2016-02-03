/**
 * An orientation represented as Euler angles.
 *
 * License: MIT License, see the `LICENSE` file.
 *
 * Authors: Leandro Motta Barros.
 */

module sbxs.math.euler_angles;

import std.math;
import std.traits;
import sbxs.math.orientation_matrix;
import sbxs.math.quaternion;


/**
 * An orientation represented as Euler angles.
 *
 * Rotations are performed in this order: heading ($(I z)), pitch ($(I x)) and
 * bank ($(I y)). In each case, the rotation is always performed in the object
 * space, with the axes already transformed by the previous rotations.
 *
 * Positive angles indicate rotations in the counter-clockwise direction (when
 * looking into the positive axis).
 *
 * `EulerAngles`s have a canonical form, which is like this:
 *
 * $(OL
 *     $(LI `heading` must be in the (-π, π] interval;)
 *     $(LI `pitch` must be in the [-π/2, π/2] interval;)
 *     $(LI `bank` must be in the (-π, π] interval;)
 *     $(LI If `pitch` is ±π/2, `bank` must be zero.)
 * )
 *
 * For performance reasons, `EulerAngles`s are never transformed to the
 * canonical form automatically. Users can easily transform them to the
 * canonical form whenever necessary by using functions
 * `canonicalize()` and `canonical()`.
 *
 * Euler angles (especially when limited to the canonical form) are the most
 * intuitive representation of orientations for regular human beings.
 */
public struct EulerAngles(T)
    if (isFloatingPoint!T)
{
    @nogc: nothrow: @safe:

    /// Constructs the $(D EulerAngles).
    public this(U)(U heading, U pitch, U bank)
        if (is (U : T))
    {
        _heading = heading;
        _pitch = pitch;
        _bank= bank;
    }

    /// The rotation around the $(I z) (up) axis, in radians.
    public @property ref inout(T) heading() inout
    {
        return _heading;
    }

    /// Ditto
    private T _heading = 0.0;

    /// The rotation around the $(I x) axis.
    public @property ref inout(T) pitch() inout
    {
        return _pitch;
    }

    /// Ditto
    private T _pitch = 0.0;

    /// The rotation around the $(I y) axis.
    public @property ref inout(T) bank() inout
    {
        return _bank;
    }

    /// Ditto
    private T _bank = 0.0;
}


// -----------------------------------------------------------------------------
// Assorted non-members (UFCS is always there, anyway)
// -----------------------------------------------------------------------------

/// Checks whether a given `EulerAngles` is in canonical form.
public @property @safe nothrow pure @nogc bool isCanonical(T)
    (const auto ref EulerAngles!T e)
{
    enum pi = cast(T)(PI); // cast to avoid precision errors
    const absPitch = abs(e.pitch);

    return e.heading > -pi && e.heading <= pi
        && e.pitch >= -pi/2 && e.pitch <= pi/2
        && ((absPitch == pi/2 && e.bank == 0.0)
            || (absPitch != pi/2 && e.bank > -pi && e.bank <= pi));
}

/**
 * Canonicalizes a given `EulerAngles`.
 *
 * Parameters:
 *     e = The `EulerAngles` to be canonicalized.
 *
 * Returns:
 *     `e`, for convenience.
 */
public ref EulerAngles!T canonicalize(T)
    (auto ref EulerAngles!T e) @safe nothrow pure @nogc
{
    enum twoPi = cast(T)(2*PI);
    enum halfPi = cast(T)(PI/2);

    // Adjust pitch
    if (abs(e.pitch) > halfPi)
    {
        e.pitch += halfPi;
        e.pitch -= floor(e.pitch / twoPi) * twoPi; // 0..twoPI (w/ PI/2 in excess)

        if (e.pitch > PI)
        {
            e.heading += PI;
            e.bank += PI;
            e.pitch = 3*halfPi - e.pitch;
        }
        else
        {
            e.pitch -= halfPi;
        }
    }

    // Adjust heading
    if (abs(e.heading) > PI)
    {
        e.heading += PI;
        e.heading -= floor(e.heading / twoPi) * twoPi; // 0..twoPi
        e.heading -= PI; // back to -PI..PI

        if (abs(e.heading + PI) < 2 * T.epsilon)
            e.heading = PI;
    }

    // Adjust bank
    enum limit = halfPi * (1.0 - 2 * T.epsilon);
    if (abs(e.pitch) >= limit)
    {
        e.bank = 0.0;
    }
    else
    {
        e.bank += PI;
        e.bank -= floor(e.bank / twoPi) * twoPi; // 0..twoPi
        e.bank -= PI; // back to -PI..PI

        if (abs(e.bank + PI) < 2 * T.epsilon)
            e.bank = PI;
    }

    return e;
}

/// Returns a copy of a given `EulerAngles`, in canonical format.
public @property EulerAngles!T canonical(T)
    (const auto ref EulerAngles!T e) @safe nothrow pure @nogc
{
    EulerAngles!T ee = e;
    return ee.canonicalize();
}

/// Converts the `EulerAngles` to an `OrientationMatrix`.
public OrientationMatrix!T toMatrix(T)
    (const ref EulerAngles!T e) @safe nothrow pure @nogc
    if (isFloatingPoint!T)
{
    const ch = cos(e.heading);
    const cb = cos(e.bank);
    const cp = cos(e.pitch);
    const sh = sin(e.heading);
    const sb = sin(e.bank);
    const sp = sin(e.pitch);

    return OrientationMatrix!T( ch*cb + sh*sp*sb, -ch*sb + sh*sp*cb,  sh*cp,
                                sb*cp,             cb*cp,            -sp,
                               -sh*cb + ch*sp*sb,  sb*sh + ch*sp*cb,  ch*cp);
}

/// Converts the `EulerAngles` to a `Quaternion`.
public Quaternion!T toQuaternion(T)
    (const ref EulerAngles!T) @safe nothrow pure @nogc
    if (isFloatingPoint!T)
{
    assert(true, "TODO: Not implemented!");
    return Quaternion!T();
}


// -----------------------------------------------------------------------------
// Handy aliases
// -----------------------------------------------------------------------------

/// Bunch of aliases for commonly used Euler angles types.
public alias EulerAnglesf = EulerAngles!(float);
public alias EulerAnglesd = EulerAngles!(double); /// Ditto
public alias EulerAnglesr = EulerAngles!(real); /// Ditto


// -----------------------------------------------------------------------------
// Unit tests
// -----------------------------------------------------------------------------

// Construction
unittest
{
    import sbxs.util.test;
    enum epsilon = 1e-7;

    // Default constructor
    EulerAnglesf ea1;

    assert(ea1.heading == 0.0);
    assert(ea1.pitch == 0.0);
    assert(ea1.bank == 0.0);

    // Parameterful constructor
    const ea2 = EulerAnglesd(3.0f, -0.6f, 0.1f);
    assertClose(ea2.heading, 3.0, epsilon);
    assertClose(ea2.pitch, -0.6, epsilon);
    assertClose(ea2.bank, 0.1, epsilon);
}


// Getters and setters
unittest
{
    import sbxs.util.test;
    enum epsilon = 1e-7;

    auto ea = EulerAnglesr(1.0, 2.0, 3.0);
    assertClose(ea.heading, 1.0, epsilon);
    assertClose(ea.pitch, 2.0, epsilon);
    assertClose(ea.bank, 3.0, epsilon);

    ea.heading = 1.1;
    ea.pitch = 2.2;
    ea.bank = 3.3;

    assertClose(ea.heading, 1.1, epsilon);
    assertClose(ea.pitch, 2.2, epsilon);
    assertClose(ea.bank, 3.3, epsilon);

    ea.heading += 0.4;
    ea.pitch += 0.3;
    ea.bank -= 0.3;

    assertClose(ea.heading, 1.5, epsilon);
    assertClose(ea.pitch, 2.5, epsilon);
    assertClose(ea.bank, 3.0, epsilon);
}


// Check for canonical EulerAngles
unittest
{
    // Simple cases
    assert(isCanonical(EulerAnglesf(0.0, 0.0, 0.0)));
    assert(isCanonical(EulerAnglesr(3.0, -1.0, 2.2)));
    assert(isCanonical(EulerAnglesf(-3.0, 1.0, -2.2)));
    assert(!isCanonical(EulerAnglesf(3.8, 0.0, 0.0)));
    assert(!isCanonical(EulerAnglesd(3.0, 2.0, 0.0)));

    // Corner cases
    enum de = 2 * double.epsilon;

    assert(!isCanonical(EulerAnglesd(-PI, 0.0, 0.0)));
    assert(isCanonical(EulerAnglesd(-PI + de, 0.0, 0.0)));
    assert(isCanonical(EulerAnglesd(PI, 0.0, 0.0)));
    assert(!isCanonical(EulerAnglesd(PI + de, 0.0, 0.0)));

    assert(isCanonical(EulerAnglesd(0.0, PI/2, 0.0)));
    assert(isCanonical(EulerAnglesd(0.0, -PI/2, 0.0)));
    assert(!isCanonical(EulerAnglesd(0.0, PI/2 + de, 0.0)));
    assert(!isCanonical(EulerAnglesd(0.0, -PI/2 - de, 0.0)));

    assert(!isCanonical(EulerAnglesd(0.0, 0.0, -PI)));
    assert(isCanonical(EulerAnglesd(0.0, 0.0, -PI + de)));
    assert(isCanonical(EulerAnglesd(0.0, 0.0, PI)));
    assert(!isCanonical(EulerAnglesd(0.0, 0.0, PI + de)));

    assert(!isCanonical(EulerAnglesd(0.0, PI/2, 0.1)));
    assert(isCanonical(EulerAnglesd(0.0, PI/2, 0.0)));
    assert(!isCanonical(EulerAnglesd(0.0, -PI/2, -1.0)));
    assert(isCanonical(EulerAnglesd(0.0, -PI/2, 0.0)));
}


// Canonicalize EulerAngles, in place
unittest
{
    import sbxs.util.test;
    enum epsilon = 1e-5;

    // Just heading needing adjustment
    auto ea1 = EulerAnglesf(5*PI + 0.2, PI/5, -PI/3);
    ea1.canonicalize();

    assertClose(ea1.heading, -PI + 0.2, epsilon);
    assertClose(ea1.pitch, PI/5, epsilon);
    assertClose(ea1.bank, -PI/3, epsilon);

    // Just bank needing adjustment
    auto ea2 = EulerAnglesf(2*PI/3 + 0.3, PI/5, -3*PI);
    ea2.canonicalize();

    assertClose(ea2.heading, 2*PI/3 + 0.3, epsilon);
    assertClose(ea2.pitch, PI/5, epsilon);
    assertClose(ea2.bank, PI, epsilon);

    // A case in which the angles are already normalized
    auto ea3 = EulerAnglesf(2*PI/3 - 0.3, PI/6 - 0.1, -PI/2.2);
    ea3.canonicalize();

    assertClose(ea3.heading, 2*PI/3 - 0.3, epsilon);
    assertClose(ea3.pitch, PI/6 - 0.1, epsilon);
    assertClose(ea3.bank, -PI/2.2, epsilon);

    // A fairly complicated case, involving out-of-range pitch
    auto ea4 = EulerAnglesf(PI + 0.2, PI/2 + 1.1, -PI - 0.6);
    ea4.canonicalize();

    assertClose(ea4.heading, 0.2, epsilon);
    assertClose(ea4.pitch, PI/2 - 1.1, epsilon);
    assertClose(ea4.bank, -0.6, epsilon);

    // Another one, with negative pitch
    auto ea5 = EulerAnglesf(6*PI + 0.3, -PI/2 - 0.3, 2*PI + PI/4);
    ea5.canonicalize();

    assertClose(ea5.heading, -PI + 0.3, epsilon);
    assertClose(ea5.pitch, -PI/2 + 0.3, epsilon);
    assertClose(ea5.bank, -PI + PI/4, epsilon);

    // A case in which the pitch adjustment will not affect heading and bank
    auto ea6 = EulerAnglesf(2.2, 8*PI+0.1, -PI/2);
    ea6.canonicalize();

    assertClose(ea6.heading, 2.2, epsilon);
    assertClose(ea6.pitch, 0.1, epsilon);
    assertClose(ea6.bank, -PI/2, epsilon);

    // A case in which the pitch requires the bank to be zero
    auto ea7 = EulerAnglesf(2.2, PI/2, -PI/2);
    ea7.canonicalize();

    assertClose(ea7.heading, 2.2, epsilon);
    assertClose(ea7.pitch, PI/2, epsilon);
    assertClose(ea7.bank, 0.0, epsilon);

    // Just like the previous one, but with a negative pitch
    auto ea8 = EulerAnglesf(2.2, -PI/2, -PI/2);
    ea8.canonicalize();

    assertClose(ea8.heading, 2.2, epsilon);
    assertClose(ea8.pitch, -PI/2, epsilon);
    assertClose(ea8.bank, 0.0, epsilon);
}


// Canonicalize EulerAngles, as a copy
unittest
{
    import sbxs.util.test;
    enum epsilon = 1e-6;

    // Corner case: -PI heading, must become PI
    const ea1 = EulerAnglesf(-PI, 0.5, PI + 4*PI);
    immutable cea1 = ea1.canonical();

    assertClose(cea1.heading, PI, epsilon);
    assertClose(cea1.pitch, 0.5, epsilon);
    assertClose(cea1.bank, PI, epsilon);

    // Kinda of similar to the previous one
    const ea2 = EulerAnglesf(-3*PI, -0.5, PI + 6*PI);
    immutable cea2 = ea2.canonical();

    assertClose(cea2.heading, PI, epsilon);
    assertClose(cea2.pitch, -0.5, epsilon);
    assertClose(cea2.bank, PI, epsilon);
}


// Convert to matrix
unittest
{
    const ea = EulerAnglesf(-PI, 0.5, PI + 4*PI);
    auto m = ea.toMatrix();
    assert(true, "TODO: Not implemented!");
}


// Convert to quaternion
unittest
{
    const ea = EulerAnglesf(-PI, 0.5, PI + 4*PI);
    auto q = ea.toQuaternion();
    assert(true, "TODO: Not implemented!");
}
