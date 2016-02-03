/**
 * Polar and spherical coordinates.
 *
 * License: MIT License, see the `LICENSE` file.
 *
 * Authors: Leandro Motta Barros. Greatest inspiration here was "3D Math Primer
 *     for Graphics and Game Development, Second Edition", by Fletcher Dunn and
 *     Ian Parberry.
 */

module sbxs.math.polar;

import std.math;
import std.traits;
import sbxs.math.vector;


/**
 * Coordinates in 2D using a polar notation.
 *
 * This structure provides two members: `r`, representing the vector length
 * (also known as "radius") and `theta`, representing the angle.
 * Default-constructed `Polar`s have zero in both members.
 *
 * A `Polar` with `theta == 0 && r > 0` points directly to the positive
 * $(I x) axis. As `theta` grows, the vector turns in the counter-clockwise
 * direction.
 *
 * `Polar`s have a canonical form, which is like this:
 *
 * $(OL
 *     $(LI `r` must be non-negative;)
 *     $(LI `theta` must be in the (-π, π] interval;)
 *     $(LI If `r` is zero, `theta` must also be zero.)
 * )
 *
 * For performance reasons, `Polar`s are never transformed to the canonical
 * form automatically. Users can easily transform them to the canonical form
 * whenever necessary by using functions `canonicalize()` and `canonical()`.
 */
public struct Polar(T)
{
    // -------------------------------------------------------------------------
    // Things which are not @safe and nothrow and pure and @nogc
    // -------------------------------------------------------------------------

    /**
     * Returns a string version of this `Polar`.
     *
     * Notice that, unlike almost everything else in this module, this method is
     * $(I not) `@nogc` nor `@safe`.
     */
    public nothrow @property string toString() const
    {
        import std.string;
        import std.exception;

        return assumeWontThrow(format("[%s ∠ %s]", r, theta));
    }

    ///
    unittest
    {
        auto p = Polar(1.1, 2.2);
        assert(p.toString == "[1.1 ∠ 2.2]");
    }

    // All methods below this point are @safe, nothrow, pure and @nogc
    @safe: nothrow: pure: @nogc:

    /**
     * Constructs polar coordinates.
     *
     * Parameters:
     *     r = The "length", or "radius".
     *     theta = The angular component, in radians.
     */
    public this(T r, T theta)
    {
        this.r = r;
        this.theta = theta;
    }

    /// The "length", or "radius".
    public T r = 0.0;

    /// The angular component, in radians.
    public T theta = 0.0;
}


/**
 * Coordinates in 3D using a spherical notation.
 *
 * While this is conceptually just an extension into 3D of a `Polar`, the
 * exact way in which things are defined here may bring one or two surprises for
 * those who already know `Polar`. Also, `Spherical` is defined in a way
 * to make it handier for use in typical game and simulation tasks, which
 * differs a bit on the traditional definition used by, say, mathematicians. So,
 * keep reading.
 *
 * This structure provides three members, all of which are zero in a
 * default-initialized `Spherical`: `r`, representing the vector length
 * (also known as "radius"), `heading`, representing the angle measured "on
 * the ground" and `pitch`, representing the angle of ascension or
 * declination.
 *
 * When `heading == 0 && r > 0`, the vector (or rather, its projection on the
 * ground) points directly to the positive $(I y) axis (which normally
 * represents the north). As `heading` grows, the vector turns in the
 * counter-clockwise direction, considering that we are looking from above (in
 * other words, it turns toward west, or the negative $(I x) axis).
 *
 * If `pitch == 0 && r > 0`, then the vector is perfectly horizontal, that
 * is, it lays on the $(I xy) plane. As `pitch` grows, the vector turns "up",
 * in the direction of the positive $(I z) axis.
 *
 * `Spherical`s have a canonical form, which is like this:
 *
 * $(OL
 *     $(LI `r` must be non-negative;)
 *     $(LI `heading` must be in the (-π, π] interval;)
 *     $(LI `pitch` must be in the [-π/2, π/2] interval;)
 *     $(LI If `r` is zero, then `heading` and `pitch` must also be
 *       zero.)
 *     $(LI If `abs(pitch) == π/2`, then `heading` must be also zero.)
 * )
 *
 * For performance reasons, `Spherical`s are never transformed to the
 * canonical form automatically. Users can easily transform them to the
 * canonical form whenever necessary by using functions `canonicalize()` and
 * `canonical()`.
 */
public struct Spherical(T)
{
    // -------------------------------------------------------------------------
    // Things which are not @safe and nothrow and pure and @nogc
    // -------------------------------------------------------------------------

    /**
     * Returns a string version of this `Polar`.
     *
     * Notice that, unlike almost everything else in this module, this method is
     * $(I not) `@nogc` nor `@safe`.
     */
    public nothrow @property string toString() const
    {
        import std.string;
        import std.exception;

        return assumeWontThrow(format("[%s ∠ %s ∠ %s]", r, heading, pitch));
    }

    ///
    unittest
    {
        auto s = Spherical(1.1, 2.2, 3.3);
        assert(s.toString == "[1.1 ∠ 2.2 ∠ 3.3]");
    }

    // All methods below this point are @safe, nothrow, pure and @nogc
    @safe: nothrow: pure: @nogc:

    /**
     * Constructs spherical coordinates.
     *
     * Parameters:
     *     r = The "length", or "radius".
     *     heading = The "horizontal angular component", in radians.
     *     pitch = The ascension or declination angle, in radians.
     */
    public this(T r, T heading, T pitch)
    {
        this.r = r;
        this.heading = heading;
        this.pitch = pitch;
    }

    /// The "length", or "radius".
    public T r = 0.0;

    /// The azimuth (horizontal angular component), in radians.
    public T heading = 0.0;

    /**
     * The polar angle (vertical angular component, sometimes called "zenith"),
     * in radians.
     *
     * Notice that a `pitch` equals to zero indicates that the vector is
     * perfectly horizontal (er, as long as `r > 0`).
     */
    public T pitch = 0.0;
}


// -----------------------------------------------------------------------------
// Assorted non-members (UFCS is always there, anyway)
// -----------------------------------------------------------------------------

/// Checks whether a given `Polar` is in canonical form.
public @property @safe nothrow pure @nogc bool isCanonical(T)
    (const auto ref Polar!T p)
{
    enum pi = cast(T)(PI); // cast to avoid precision errors
    return (p.r == 0 && p.theta == 0)
        || (p.r > 0 && p.theta > -pi && p.theta <= pi);
}

/// Checks whether a given `Spherical` is in canonical form.
public @property @safe nothrow pure @nogc bool isCanonical(T)
    (const auto ref Spherical!T s)
{
    enum pi = cast(T)(PI); // cast to avoid precision errors

    return (s.r == 0 && s.heading == 0 && s.pitch == 0)
        || (s.r > 0 && abs(s.pitch) == pi/2 && s.heading == 0)
        || (s.r > 0 && s.pitch > -pi/2 && s.pitch < pi/2
            && s.heading > -pi && s.heading <= pi);
}

/**
 * Canonicalizes a given `Polar`.
 *
 * Parameters:
 *     p = The polar to be canonicalized.
 *
 * Returns:
 *     `p`, for convenience.
 */
public @safe nothrow pure @nogc ref Polar!T canonicalize(T)(auto ref Polar!T p)
{
    enum twoPi = 2*PI;

    // The r = 0.0 case
    if (p.r == 0.0)
    {
        p.theta = 0.0;
        return p;
    }

    // Handle the r < 0.0 case
    if (p.r < 0.0)
    {
        p.r = -p.r;
        p.theta += PI;
    }

    // Ensure theta is in the -PI..PI range
    if (abs(p.theta) > PI)
    {
        p.theta += PI;
        p.theta -= floor(p.theta / twoPi) * twoPi; // 0..twoPI
        p.theta -= PI; // back to -PI..PI
    }

    return p;
}

/**
 * Canonicalizes a given `Spherical`.
 *
 * Parameters:
 *     s = The `Spherical` to be canonicalized.
 *
 * Returns:
 *     `s`, for convenience.
 */
public @safe nothrow pure @nogc ref Spherical!T canonicalize(T)
    (auto ref Spherical!T s)
{
    enum twoPi = 2*PI;
    enum halfPi = PI/2;

    // The r = 0.0 case
    if (s.r == 0.0)
    {
        s.heading = 0.0;
        s.pitch = 0.0;
        return s;
    }

    // Handle the r < 0 case
    if (s.r < 0.0)
    {
        s.r = -s.r;
        s.heading += PI;
        s.pitch = -s.pitch;
    }

    // Adjust pitch
    if (abs(s.pitch) > halfPi)
    {
        s.pitch += halfPi;
        s.pitch -= floor(s.pitch / twoPi) * twoPi;
        if (s.pitch > PI)
        {
            s.heading += PI;
            s.pitch = 3*PI/2 - s.pitch;
        }
        else
        {
            s.pitch -= halfPi;
        }
    }

    // Gimbal lock?
    enum limit = halfPi * (1.0 - 2 * T.epsilon);
    if (s.pitch >= limit)
    {
        s.pitch = halfPi;
        s.heading = 0;
        return s;
    }

    if (s.pitch <= -limit)
    {
        s.pitch = -halfPi;
        s.heading = 0;
        return s;
    }

    // Adjust heading
    if (abs(s.heading) > PI)
    {
        s.heading += PI;
        s.heading -= floor(s.heading / twoPi) * twoPi; // 0..twoPi
        s.heading -= PI; // back to -PI..PI
    }

    return s;
}

/// Returns a copy of a given `Polar`, in canonical format.
public @property @safe nothrow pure @nogc Polar!T canonical(T)
    (const auto ref Polar!T p)
{
    Polar!T pp = p;
    return pp.canonicalize();
}

/// Returns a copy of a given `Spherical`, in canonical format.
public @property @safe nothrow pure @nogc Spherical!T canonical(T)
    (const auto ref Spherical!T s)
{
    Spherical!T ss = s;
    return ss.canonicalize();
}

/**
 * Converts a given `Polar` to a 2D `Vector`, in Cartesian coordinates.
 *
 * Parameters:
 *     p = The polar coordinates.
 *
 * Returns: `p` converted to Cartesian coordinates, as a `Vector`.
 */
public @property @safe nothrow pure @nogc Vector!(T, 2) cartesian(T)
    (const auto ref Polar!T p)
    if (isFloatingPoint!T)
{
    return Vector!(T, 2)(p.r * cos(p.theta), p.r * sin(p.theta));
}

/**
 * Converts a given `Spherical` to a 3D `Vector`, in Cartesian
 * coordinates.
 *
 * Parameters:
 *     s = The spherical coordinates.
 *
 * Returns: `s` converted to Cartesian coordinates, as a `Vector`.
 */
public @property @safe nothrow pure @nogc Vector!(T, 3) cartesian(T)
    (const auto ref Spherical!T s)
    if (isFloatingPoint!T)
{
    const sinHeading = sin(s.heading);
    const cosHeading = cos(s.heading);
    const sinPitch = sin(s.pitch);
    const cosPitch = cos(s.pitch);

    return Vector!(T, 3)(-s.r * cosPitch * sinHeading,
                          s.r * cosPitch * cosHeading,
                          s.r * sinPitch);
}

/**
 * Converts a given 2D `Vector` (that is, Cartesian coordinates) to polar
 * coordinates.
 *
 * Parameters:
 *     c = The Cartesian coordinates.
 *
 * Returns: `c` converted to polar coordinates. This is guaranteed to be in
 *     canonical format.
 */
public @property @safe nothrow pure @nogc Polar!(T) polar(T)
    (const auto ref Vector!(T, 2) c)
    if (isFloatingPoint!T)
{
    return Polar!(T)(sqrt(c.x*c.x + c.y*c.y), atan2(c.y, c.x));
}

/**
 * Converts a given 3D `Vector` (that is, Cartesian coordinates) to spherical
 * coordinates.
 *
 * Parameters:
 *     c = The Cartesian coordinates.
 *
 * Returns: `c` converted to spherical coordinates. This is guaranteed to be
 *     in canonical format.
 */
public @property @safe nothrow pure @nogc Spherical!(T) spherical(T)
    (const auto ref Vector!(T, 3) c)
    if (isFloatingPoint!T)
{
    const r = sqrt(c.x*c.x + c.y*c.y + c.z*c.z);

    if (r == 0.0)
        return Spherical!(T)(0.0, 0.0, 0.0);

    const pitch = asin(c.z/r);
    if (abs(pitch) > PI/2 * (1.0 - 2 * T.epsilon))
    {
        return Spherical!(T)(r, 0.0, pitch);
    }
    else
    {
        auto heading = atan2(-c.x, c.y);
        if (heading < -PI + 2 * T.epsilon)
            heading = PI;
        return Spherical!(T)(r, heading, pitch);
    }
}


// -----------------------------------------------------------------------------
// Handy aliases
// -----------------------------------------------------------------------------

/// Bunch of aliases for commonly used polar types.
public alias Polarf = Polar!(float);
public alias Polard = Polar!(double); /// Ditto
public alias Polarr = Polar!(real); /// Ditto
public alias Sphericalf = Spherical!(float); /// Ditto
public alias Sphericald = Spherical!(double); /// Ditto
public alias Sphericalr = Spherical!(real); /// Ditto


// -----------------------------------------------------------------------------
// Unit tests
// -----------------------------------------------------------------------------

// Polar constructor
unittest
{
    import sbxs.util.test;
    enum epsilon = 1e-7;

    // Default constructor
    Polarf p0;
    assert(p0.r == 0.0);
    assert(p0.theta == 0.0);

    // Constructor taking parameters
    auto p1 = Polarf(1.2, PI/2);
    assertClose(p1.r, 1.2, epsilon);
    assertClose(p1.theta, PI/2, epsilon);

    const p2 = Polard(1.8, -PI/2);
    assertClose(p2.r, 1.8, epsilon);
    assertClose(p2.theta, -PI/2, epsilon);

    immutable p3 = Polarr(-0.3, 0.0);
    assertClose(p3.r, -0.3, epsilon);
    assertClose(p3.theta, 0.0, epsilon);
}


// Spherical constructor
unittest
{
    import sbxs.util.test;
    enum epsilon = 1e-7;

    // Default constructor
    Sphericalf s0;
    assert(s0.r == 0.0);
    assert(s0.heading == 0.0);
    assert(s0.pitch == 0.0);

    // Constructor taking parameters
    auto s1 = Sphericalf(1.2, PI/2, PI/3);
    assertClose(s1.r, 1.2, epsilon);
    assertClose(s1.heading, PI/2, epsilon);
    assertClose(s1.pitch, PI/3, epsilon);

    const s2 = Sphericald(1.8, -PI/2, -PI/5);
    assertClose(s2.r, 1.8, epsilon);
    assertClose(s2.heading, -PI/2, epsilon);
    assertClose(s2.pitch, -PI/5, epsilon);

    immutable s3 = Sphericalr(-0.3, 0.0, 0.0);
    assertClose(s3.r, -0.3, epsilon);
    assertClose(s3.heading, 0.0, epsilon);
    assertClose(s3.pitch, 0.0, epsilon);
}


// Check for canonical form of Polars
unittest
{
    assert(Polarf(0.0, 0.0).isCanonical);
    assert(isCanonical(Polarr(1.0, 0.0)));
    assert(isCanonical(Polarr(1.2, -PI/1.001)));
    assert(isCanonical(Polarr(10.2, PI/3)));

    // If length is zero, angle must be zero
    assert(!Polarf(0.0, 0.1).isCanonical);
    assert(!Polard(0.0, -0.1).isCanonical);
    assert(!Polard(0.0, 20*PI).isCanonical);
    assert(!Polard(0.0, -32*PI).isCanonical);

    // Angles must be in interval (PI, PI]
    assert(Polarf(1.0, PI).isCanonical);
    assert(Polard(1.0, PI).isCanonical);
    assert(!Polarf(1.0, -PI).isCanonical);
    assert(!Polarr(1.0, 1.01*PI).isCanonical);
    assert(!Polarf(2.1, 1234*PI).isCanonical);
    assert(!Polard(5.1, -32.2*PI).isCanonical);

    // Lengths cannot be negative
    assert(!isCanonical(Polarf(-0.01, PI/2)));
    assert(!isCanonical(Polard(-2.0, PI/3)));
    assert(isCanonical(Polard(2.0, PI/3)));
    assert(!isCanonical(Polard(-1e-7, PI/2)));

    // Assorted aberrations
    assert(!isCanonical(Polarf(-0.01, 3*PI)));
    assert(!isCanonical(Polard(-111, -3*PI)));
    assert(!isCanonical(Polard(-111, 0.0)));
}


// Check for canonical form of Sphericals
unittest
{
    assert(Sphericalf(0.0, 0.0, 0.0).isCanonical);
    assert(isCanonical(Sphericalr(1.0, 0.0, 0.0)));
    assert(isCanonical(Sphericald(1.2, -PI/1.001, PI/5)));
    assert(isCanonical(Sphericalr(10.2, PI/3, -PI/3)));

    // If length is zero, both angles must be zero
    assert(!Sphericalf(0.0, 0.1, 0.0).isCanonical);
    assert(!Sphericalf(0.0, 0.0, 0.1).isCanonical);
    assert(!Sphericald(0.0, -0.1, 0.0).isCanonical);
    assert(!Sphericald(0.0, 0.0, -0.1).isCanonical);
    assert(!Sphericalr(0.0, 20*PI, -PI).isCanonical);
    assert(!Sphericalr(0.0, -32*PI, -12*PI).isCanonical);

    // Heading must be in interval (PI, PI]
    assert(Sphericalf(1.0, PI, 0.0).isCanonical);
    assert(Sphericald(5.7, PI, 0.0).isCanonical);
    assert(!Sphericalf(1.0, -PI, 0.0).isCanonical);
    assert(!Sphericalr(1.4, 1.01*PI, 0.0).isCanonical);
    assert(!Sphericalf(2.1, 1234*PI, 0.0).isCanonical);
    assert(!Sphericald(5.1, -32.2*PI, 0.0).isCanonical);

    // Pitch must be in interval [-PI/2, PI/2]
    assert(Sphericalf(1.0, 0.0, -PI/2).isCanonical);
    assert(Sphericalf(1.2, 0.0, PI/2).isCanonical);
    assert(Sphericald(1.0, 0.0, -PI/2).isCanonical);
    assert(Sphericald(1.0, 0.0, PI/2).isCanonical);

    assert(!Sphericalr(1.0, 0.0, 1.001*PI/2).isCanonical);
    assert(!Sphericalr(1.0, 0.0, -1.001*PI/2).isCanonical);
    assert(!Sphericalf(2.1, 0.0, 1234*PI).isCanonical);
    assert(!Sphericald(5.1, 0.0, -32.2*PI).isCanonical);

    // If pitch is -PI/2 or PI/2, heading must be zero
    assert(Sphericald(1.0, 0.0, -PI/2).isCanonical);
    assert(!Sphericalf(1.0, 0.0001, -PI/2).isCanonical);
    assert(Sphericald(4.0, 0.0, PI/2).isCanonical);
    assert(!Sphericalr(4.0, -0.0001, PI/2).isCanonical);

    // Lengths cannot be negative
    assert(!isCanonical(Sphericalf(-0.01, PI/2, -PI/3)));
    assert(!isCanonical(Sphericald(-2.0, PI/3, PI/3)));
    assert(isCanonical(Sphericald(2.0, PI/3, PI/5)));
    assert(!isCanonical(Sphericald(-1e-7, PI/2, -PI/7)));

    // Assorted aberrations
    assert(!isCanonical(Sphericalf(-0.01, 3*PI, -5*PI)));
    assert(!isCanonical(Sphericald(-111, -3*PI, 7*PI)));
    assert(!isCanonical(Sphericald(-111, 0.0, 0.0)));
}


// Canonicalize polar coordinates, in place
unittest
{
    import sbxs.util.test;
    enum epsilon = 1e-5;

    auto p1 = Polarf(2.2, 1.1 + 12.0*PI);
    p1.canonicalize();
    assertClose(p1.r, 2.2, epsilon);
    assertClose(p1.theta, 1.1, epsilon);
    assert(p1.isCanonical);

    auto p2 = Polard(-1.2, 0.1 + PI);
    p2.canonicalize();
    assertClose(p2.r, 1.2, epsilon);
    assertClose(p2.theta, 0.1, epsilon);
    assert(p2.isCanonical);

    auto p3 = Polarf(-4.1, 0.2 + PI + 8*PI);
    p3.canonicalize();
    assertClose(p3.r, 4.1, epsilon);
    assertClose(p3.theta, 0.2, epsilon);
    assert(p3.isCanonical);

    auto p4 = Polarr(0.3, -0.3 - 4*PI);
    p4.canonicalize();
    assertClose(p4.r, 0.3, epsilon);
    assertClose(p4.theta, -0.3, epsilon);
    assert(p4.isCanonical);

    auto p5 = Polarr(0.0, PI/2);
    p5.canonicalize();
    assert(p5.r == 0.0);
    assert(p5.theta == 0.0);
    assert(p5.isCanonical);
}


// Canonicalize spherical coordinates, in place
unittest
{
    import sbxs.util.test;
    enum epsilon = 1e-5;

    auto s1 = Sphericalf(2.2, 1.1 + 12.0*PI, 0.5);
    s1.canonicalize();
    assertClose(s1.r, 2.2, epsilon);
    assertClose(s1.heading, 1.1, epsilon);
    assertClose(s1.pitch, 0.5, epsilon);
    assert(s1.isCanonical);

    auto s2 = Sphericald(-1.2, 0.1 + PI, -0.2);
    s2.canonicalize();
    assertClose(s2.r, 1.2, epsilon);
    assertClose(s2.heading, 0.1, epsilon);
    assertClose(s2.pitch, 0.2, epsilon);
    assert(s2.isCanonical);

    auto s3 = Sphericalf(-4.1, 0.2 + PI + 8*PI, PI/3);
    s3.canonicalize();
    assertClose(s3.r, 4.1, epsilon);
    assertClose(s3.heading, 0.2, epsilon);
    assertClose(s3.pitch, -PI/3, epsilon);
    assert(s3.isCanonical);

    auto s4 = Sphericalr(0.3, -0.3 - 4*PI, -PI/4);
    s4.canonicalize();
    assertClose(s4.r, 0.3, epsilon);
    assertClose(s4.heading, -0.3, epsilon);
    assertClose(s4.pitch, -PI/4, epsilon);
    assert(s4.isCanonical);

    auto s5 = Sphericalr(0.0, PI/2, PI);
    s5.canonicalize();
    assert(s5.r == 0.0);
    assert(s5.heading == 0.0);
    assert(s5.pitch == 0.0);
    assert(s5.isCanonical);

    auto s6 = Sphericald(2.2, PI/5, 4*PI + PI/7);
    s6.canonicalize();
    assertClose(s6.r, 2.2, epsilon);
    assertClose(s6.heading, PI/5, epsilon);
    assertClose(s6.pitch, PI/7, epsilon);
    assert(s6.isCanonical);

    auto s7 = Sphericald(3.6, PI/2, 3*PI/4);
    s7.canonicalize();
    assertClose(s7.r, 3.6, epsilon);
    assertClose(s7.heading, -PI/2, epsilon);
    assertClose(s7.pitch, PI/4, epsilon);
    assert(s7.isCanonical);

    auto s8 = Sphericald(2.3, PI/2, PI/2 - double.epsilon);
    s8.canonicalize();
    assertClose(s8.r, 2.3, epsilon);
    assertClose(s8.heading, 0.0, epsilon);
    assertClose(s8.pitch, PI/2, epsilon);
    assert(s8.isCanonical);

    auto s9 = Sphericalf(1.2, -0.3, -PI/2 + float.epsilon);
    s9.canonicalize();
    assertClose(s9.r, 1.2, epsilon);
    assertClose(s9.heading, 0.0, epsilon);
    assertClose(s9.pitch, -PI/2, epsilon);
    assert(s9.isCanonical);
}


// Canonicalize polar coordinates, as a copy
unittest
{
    import sbxs.util.test;
    enum epsilon = 1e-5;

    const p1 = Polarf(2.2, 1.1 + 12.0*PI);
    auto cp1 = p1.canonical;
    assertClose(cp1.r, 2.2, epsilon);
    assertClose(cp1.theta, 1.1, epsilon);
    assert(cp1.isCanonical);

    immutable p2 = Polard(-1.2, 0.1 + PI);
    const cp2 = p2.canonical;
    assertClose(cp2.r, 1.2, epsilon);
    assertClose(cp2.theta, 0.1, epsilon);
    assert(cp2.isCanonical);

    auto p3 = Polarf(-4.1, 0.2 + PI + 8*PI);
    auto cp3 = p3.canonical;
    assertClose(cp3.r, 4.1, epsilon);
    assertClose(cp3.theta, 0.2, epsilon);
    assert(cp3.isCanonical);

    const p4 = Polarr(0.3, -0.3 - 4*PI);
    const cp4 = p4.canonical;
    assertClose(cp4.r, 0.3, epsilon);
    assertClose(cp4.theta, -0.3, epsilon);
    assert(cp4.isCanonical);

    auto p5 = Polarr(0.0, PI/2);
    const cp5 = p5.canonical;
    assert(cp5.r == 0.0);
    assert(cp5.theta == 0.0);
    assert(cp5.isCanonical);
}


// Canonicalize spherical coordinates, as a copy
unittest
{
    import sbxs.util.test;
    enum epsilon = 1e-5;

    const s1 = Sphericalf(2.2, 1.1 + 12.0*PI, 0.5);
    auto cs1 = s1.canonical;
    assertClose(cs1.r, 2.2, epsilon);
    assertClose(cs1.heading, 1.1, epsilon);
    assertClose(cs1.pitch, 0.5, epsilon);
    assert(cs1.isCanonical);

    immutable s2 = Sphericald(-1.2, 0.1 + PI, -0.2);
    auto cs2 = s2.canonical;
    assertClose(cs2.r, 1.2, epsilon);
    assertClose(cs2.heading, 0.1, epsilon);
    assertClose(cs2.pitch, 0.2, epsilon);
    assert(cs2.isCanonical);

    auto s3 = Sphericalf(-4.1, 0.2 + PI + 8*PI, PI/3);
    auto cs3 = s3.canonical;
    assertClose(cs3.r, 4.1, epsilon);
    assertClose(cs3.heading, 0.2, epsilon);
    assertClose(cs3.pitch, -PI/3, epsilon);
    assert(cs3.isCanonical);

    const s4 = Sphericalr(0.3, -0.3 - 4*PI, -PI/4);
    const cs4 = s4.canonical;
    assertClose(cs4.r, 0.3, epsilon);
    assertClose(cs4.heading, -0.3, epsilon);
    assertClose(cs4.pitch, -PI/4, epsilon);
    assert(cs4.isCanonical);

    auto s5 = Sphericalr(0.0, PI/2, PI);
    const cs5 = s5.canonical;
    assert(cs5.r == 0.0);
    assert(cs5.heading == 0.0);
    assert(cs5.pitch == 0.0);
    assert(cs5.isCanonical);

    const s6 = Sphericald(2.2, PI/5, 4*PI + PI/7);
    immutable cs6 = s6.canonical;
    assertClose(cs6.r, 2.2, epsilon);
    assertClose(cs6.heading, PI/5, epsilon);
    assertClose(cs6.pitch, PI/7, epsilon);
    assert(cs6.isCanonical);

    const s7 = Sphericald(3.6, PI/2, 3*PI/4);
    const cs7 = s7.canonical;
    assertClose(cs7.r, 3.6, epsilon);
    assertClose(cs7.heading, -PI/2, epsilon);
    assertClose(cs7.pitch, PI/4, epsilon);
    assert(cs7.isCanonical);

    const s8 = Sphericald(2.3, PI/2, PI/2 - double.epsilon);
    const cs8 = s8.canonical;
    assertClose(cs8.r, 2.3, epsilon);
    assertClose(cs8.heading, 0.0, epsilon);
    assertClose(cs8.pitch, PI/2, epsilon);
    assert(cs8.isCanonical);

    auto s9 = Sphericalf(1.2, -0.3, -PI/2 + float.epsilon);
    const cs9 = s9.canonical;
    assertClose(cs9.r, 1.2, epsilon);
    assertClose(cs9.heading, 0.0, epsilon);
    assertClose(cs9.pitch, -PI/2, epsilon);
    assert(cs9.isCanonical);
}


// Polar to Cartesian conversion
unittest
{
    import sbxs.util.test;
    enum epsilon = 1e-6;

    // Zero
    const c0 = Polarf(0.0, 0.0).cartesian;
    assert(c0.x == 0.0);
    assert(c0.y == 0.0);

    // Coordinate axes
    auto c1 = Polarf(1.2, 0.0).cartesian;
    assertClose(c1.x, 1.2, epsilon);
    assertSmall(c1.y, epsilon);

    immutable c2 = Polarr(1.4, PI/2).cartesian;
    assertSmall(c2.x, epsilon);
    assertClose(c2.y, 1.4, epsilon);

    const c3 = Polard(0.5, PI).cartesian;
    assertClose(c3.x, -0.5, epsilon);
    assertSmall(c3.y, epsilon);

    const c4 = Polarf(5.2, 3*PI/2).cartesian;
    assertSmall(c4.x, epsilon);
    assertClose(c4.y, -5.2, epsilon);

    // Each quadrant
    const c5 = Polarf(0.9486832, 1.2490457).cartesian;
    assertClose(c5.x, 0.3, epsilon);
    assertClose(c5.y, 0.9, epsilon);

    immutable c6 = Polarf(3.4132096, 2.12629006).cartesian;
    assertClose(c6.x, -1.8, epsilon);
    assertClose(c6.y,  2.9, epsilon);

    const c7 = Polard(1.252996409, -2.642245932).cartesian;
    assertClose(c7.x, -1.1, epsilon);
    assertClose(c7.y, -0.6, epsilon);

    const c8 = Polarf(2.284731932, -0.4048917863).cartesian;
    assertClose(c8.x,  2.1, epsilon);
    assertClose(c8.y, -0.9, epsilon);

    // Same as above, non-canonical forms
    const c9 = Polard(1.252996409, 3.640939375179).cartesian;
    assertClose(c9.x, -1.1, epsilon);
    assertClose(c9.y, -0.6, epsilon);

    const c10 = Polarf(2.284731932, 5.878293520879).cartesian;
    assertClose(c10.x,  2.1, epsilon);
    assertClose(c10.y, -0.9, epsilon);

    const c11 = Polard(1.252996409, -6*PI+3.640939375179).cartesian;
    assertClose(c11.x, -1.1, epsilon);
    assertClose(c11.y, -0.6, epsilon);

    const c12 = Polard(2.284731932, -4*PI+5.878293520879).cartesian;
    assertClose(c12.x,  2.1, epsilon);
    assertClose(c12.y, -0.9, epsilon);
}


// Spherical to Cartesian conversion
unittest
{
    import sbxs.util.test;
    enum epsilon = 1e-5;

    // Zero
    const c0 = Sphericalf(0.0, 0.0, 0.0).cartesian;
    assert(c0.x == 0.0);
    assert(c0.y == 0.0);
    assert(c0.z == 0.0);

    // Coordinate axes (on heading)
    auto c1 = Sphericalf(1.23693, 0.0, 0.244977904).cartesian; // +y, north
    assertSmall(c1.x, epsilon);
    assertClose(c1.y, 1.2, epsilon);
    assertClose(c1.z, 0.3, epsilon);

    immutable c2 = Sphericalr(1.42127, PI/2, -0.885073913).cartesian; // -x, west
    assertClose(c2.x, -0.9, epsilon);
    assertSmall(c2.y, epsilon);
    assertClose(c2.z, -1.1, epsilon);

    const c3 = Sphericald(0.5, PI, 0.0).cartesian; // -y, south
    assertSmall(c3.x, epsilon);
    assertClose(c3.y, -0.5, epsilon);
    assertSmall(c3.z, epsilon);

    const c4 = Sphericalf(5.26118, -PI/2, 0.152649289).cartesian; // +x, east
    assertClose(c4.x, 5.2, epsilon);
    assertSmall(c4.y, epsilon);
    assertClose(c4.z, 0.8, epsilon);

    // Each quadrant of heading
    const c5 = Sphericalf(0.994987, 0.3217505543, 0.3062775080).cartesian; // nw
    assertClose(c5.x, -0.3, epsilon);
    assertClose(c5.y,  0.9, epsilon);
    assertClose(c5.z,  0.3, epsilon);

    immutable c6 = Sphericalf(3.4132096, 2.5860989183243, 0.0).cartesian; // sw
    assertClose(c6.x, -1.8, epsilon);
    assertClose(c6.y, -2.9, epsilon);
    assertClose(c6.z,  0.0, epsilon);

    const c7 = Sphericald(1.34907, -2.0701430484, -0.3796825975).cartesian; // se
    assertClose(c7.x,  1.1, epsilon);
    assertClose(c7.y, -0.6, epsilon);
    assertClose(c7.z, -0.5, epsilon);

    const c8 = Sphericalf(4.51996, -1.1659045405, 1.0408604677).cartesian; // ne
    assertClose(c8.x,  2.1, epsilon);
    assertClose(c8.y,  0.9, epsilon);
    assertClose(c8.z,  3.9, epsilon);

    // Same as above, non-canonical forms
    const c9 = Sphericalf(0.994987, 0.3217505543+4*PI, 0.3062775080).cartesian;
    assertClose(c9.x, -0.3, epsilon);
    assertClose(c9.y,  0.9, epsilon);
    assertClose(c9.z,  0.3, epsilon);

    immutable c10 = Sphericalf(3.4132096, 2.5860989183243, 0.0-6*PI).cartesian;
    assertClose(c10.x, -1.8, epsilon);
    assertClose(c10.y, -2.9, epsilon);
    assertSmall(c10.z, epsilon);

    const c11 = Sphericald(-1.34907, -2.0701430484+PI, 0.3796825975).cartesian;
    assertClose(c11.x,  1.1, epsilon);
    assertClose(c11.y, -0.6, epsilon);
    assertClose(c11.z, -0.5, epsilon);

    const c12 = Sphericalf(4.51996, -1.1659045405+4*PI, 1.0408604677+6*PI).cartesian;
    assertClose(c12.x, 2.1, epsilon);
    assertClose(c12.y, 0.9, epsilon);
    assertClose(c12.z, 3.9, epsilon);

    // Vectors pointing directly upwards or downwards
    const c13 = Sphericalf(2.3, 0.0, PI/2).cartesian;
    assertSmall(c13.x, epsilon);
    assertSmall(c13.y, epsilon);
    assertClose(c13.z, 2.3, epsilon);

    const c14 = Sphericald(2.2, 0.0, -PI/2).cartesian;
    assertSmall(c14.x, epsilon);
    assertSmall(c14.y, epsilon);
    assertClose(c14.z, -2.2, epsilon);

    const c15 = Sphericalf(-2.3, 3.3, PI/2).cartesian;
    assertSmall(c15.x, epsilon);
    assertSmall(c15.y, epsilon);
    assertClose(c15.z, -2.3, epsilon);

    const c16 = Sphericalr(1.2, 0.0, -PI/2).cartesian;
    assertSmall(c16.x, epsilon);
    assertSmall(c16.y, epsilon);
    assertClose(c16.z, -1.2, epsilon);
}


// Cartesian to Polar conversion
unittest
{
    import sbxs.util.test;
    enum epsilon = 1e-7;

    // Zero
    const p0 = Vec2f(0.0, 0.0).polar;
    assert(p0.r == 0.0);
    assert(p0.theta == 0.0);

    // Coordinate axes
    auto p1 = Vec2f(1.2, 0.0).polar;
    assertClose(p1.r, 1.2, epsilon);
    assertClose(p1.theta, 0.0, epsilon);

    immutable p2 = Vec2r(0.0, 1.4).polar;
    assertClose(p2.r, 1.4, epsilon);
    assertClose(p2.theta, PI/2, epsilon);

    const p3 = Vec2d(-0.5, 0.0).polar;
    assertClose(p3.r, 0.5, epsilon);
    assertClose(p3.theta, PI, epsilon);

    const p4 = Vec2f(0.0, -5.2).polar;
    assertClose(p4.r, 5.2, epsilon);
    assertClose(p4.theta, -PI/2, epsilon);

    // Each quadrant
    const p5 = Vec2f(0.3, 0.9).polar;
    assertClose(p5.r, 0.9486832, epsilon);
    assertClose(p5.theta, 1.2490457, epsilon);

    const p6 = Vec2f(-1.8, 2.9).polar;
    assertClose(p6.r, 3.4132096, epsilon);
    assertClose(p6.theta, 2.12629006, epsilon);

    const p7 = Vec2d(-1.1, -0.6).polar;
    assertClose(p7.r, 1.252996409, epsilon);
    assertClose(p7.theta, -2.642245932, epsilon);

    const p8 = Vec2f(2.1, -0.9).polar;
    assertClose(p8.r, 2.284731932, epsilon);
    assertClose(p8.theta, -0.4048917863, epsilon);
}


// Cartesian to Spherical conversion
unittest
{
    import sbxs.util.test;
    enum epsilon = 1e-5;

    // Zero
    const p0 = Vec3f(0.0, 0.0, 0.0).spherical;
    assert(p0.r == 0.0);
    assert(p0.heading == 0.0);
    assert(p0.pitch == 0.0);

    // Coordinate axes (on heading)
    auto s1 = Vec3f(0.0, 1.2, 0.3).spherical;
    assertClose(s1.r, 1.23693, epsilon);
    assertClose(s1.heading, 0.0, epsilon);
    assertClose(s1.pitch, 0.244977904, epsilon);

    immutable s2 = Vec3r(-0.9, 0.0, -1.1).spherical;
    assertClose(s2.r, 1.42127, epsilon);
    assertClose(s2.heading, PI/2, epsilon);
    assertClose(s2.pitch, -0.885073913, epsilon);

    const s3 = Vec3d(0.0, -0.5, 0.0).spherical;
    assertClose(s3.r, 0.5, epsilon);
    assertClose(s3.heading, PI, epsilon);
    assertSmall(s3.pitch, epsilon);

    const s4 = Vec3f(5.2, 0.0, 0.8).spherical;
    assertClose(s4.r, 5.26118, epsilon);
    assertClose(s4.heading, -PI/2, epsilon);
    assertClose(s4.pitch, 0.152649289, epsilon);

    // Each quadrant of heading
    const s5 = Vec3f(-0.3, 0.9, 0.3).spherical;
    assertClose(s5.r, 0.994987, epsilon);
    assertClose(s5.heading, 0.3217505543, epsilon);
    assertClose(s5.pitch, 0.3062775080, epsilon);

    immutable s6 = Vec3f(-1.8, -2.9, 0.0).spherical;
    assertClose(s6.r, 3.4132096, epsilon);
    assertClose(s6.heading, 2.5860989183243, epsilon);
    assertSmall(s6.pitch, epsilon);

    const s7 = Vec3d(1.1, -0.6, -0.5).spherical;
    assertClose(s7.r, 1.34907, epsilon);
    assertClose(s7.heading, -2.0701430484, epsilon);
    assertClose(s7.pitch, -0.3796825975, epsilon);

    const s8 = Vec3f(2.1, 0.9, 3.9).spherical;
    assertClose(s8.r, 4.51996, epsilon);
    assertClose(s8.heading, -1.1659045405, epsilon);
    assertClose(s8.pitch, 1.0408604677, epsilon);

    const s9 = Vec3f(0.0, 0.0, 2.3).spherical;
    assertClose(s9.r, 2.3, epsilon);
    assertSmall(s9.heading, epsilon);
    assertClose(s9.pitch, PI/2, epsilon);

    const s10 = Vec3d(0.0, 0.0, -2.2).spherical;
    assertClose(s10.r, 2.2, epsilon);
    assertSmall(s10.heading, epsilon);
    assertClose(s10.pitch, -PI/2, epsilon);
}
