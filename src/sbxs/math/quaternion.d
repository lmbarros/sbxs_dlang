/**
 * Quaternions.
 *
 * License: MIT License, see the `LICENSE` file.
 *
 * Authors: Leandro Motta Barros.
 */

module sbxs.math.quaternion;

import std.math;
import std.traits;
import sbxs.math.euler_angles;
import sbxs.math.orientation_matrix;
import sbxs.math.vector;


/**
 * A quaternion.
 *
 * More than a complex number, less than an octonion. Or something like this.
 *
 * Anyway, useful for representing orientations and, especially, interpolating
 * between them.
 *
 * The quaternion can be seen as composed of a scalar component and a vector
 * component. In this implementation, the scalar component is represented by
 * `w`, while the vector component is represented by `x`, `y` and `z`.
 *
 * Default constructed quaternions have `w`, `x`, `y` and `z` equals to,
 * respectively, 1, 0, 0 and 0 -- which happens to be an identity quaternion.
 */
public struct Quaternion(T)
{
    // -------------------------------------------------------------------------
    // Things which are not @safe and nothrow and pure and @nogc
    // -------------------------------------------------------------------------

    /**
     * Returns a string version of this quaternion.
     *
     * Notice that, unlike almost everything else in this module, this method is
     * $(I not) `@nogc` nor `@safe`.
     */
    public nothrow @property string toString() const
    {
        import std.format: format;
        import std.exception: assumeWontThrow;

        return assumeWontThrow(format("[%s (%s, %s, %s)]", w, x, y, z));
    }

    ///
    unittest
    {
       auto q = Quatf(1.1, 2.2, 3.3, 4.4);
       assert(q.toString == "[1.1 (2.2, 3.3, 4.4)]");
    }

    // All methods below this point are @safe, nothrow, pure and @nogc
    @safe: nothrow: pure: @nogc:

    /**
     * Constructs the quaternion directly from its components.
     *
     * Parameters:
     *     w = The $(I w) component of the quaternion, which is its scalar
     *         component.
     *     x = The $(I x) component of the quaternion, which is the first
     *         component of its vector component.
     *     y = The $(I y) component of the quaternion, which is the second
     *         component of its vector component.
     *     z = The $(I z) component of the quaternion, which is the third
     *         component of its vector component.
     */
    public this(T w, T x, T y, T z)
    {
        this.w = w;
        this.x = x;
        this.y = y;
        this.z = z;
    }

    /**
     * Constructs the quaternion from an axis and an angle.
     *
     * This will construct a unit quaternion that represents a rotation of
     * `theta` radians around `axis`, in the counterclockwise direction (when
     * looking into the `axis` vector -- which must be a unit vector, by the
     * way).
     */
    public this(U,V)(const auto ref Vector!(U, 3) axis, V theta)
       if (is (U : T) && is (V : T))
    in
    {
        import sbxs.util.test;
        assert(isClose(axis.squaredLength, 1.0, 1e-5));
    }
    body
    {
        const ht = theta/2.0;
        const sht = -sin(ht);
        this.w = cos(ht);
        this.x = sht * axis.x;
        this.y = sht * axis.y;
        this.z = sht * axis.z;
    }

    /// Quaternion negation and the useless-but-symmetric "unary plus".
    public Quaternion!T opUnary(string op)() const
        if (op == "+" || op == "-")
    {
        Quaternion!T res = void;

        mixin("res.w = " ~ op ~ "this.w;");
        mixin("res.x = " ~ op ~ "this.x;");
        mixin("res.y = " ~ op ~ "this.y;");
        mixin("res.z = " ~ op ~ "this.z;");

        return res;
    }

    /**
     * Quaternion multiplication (AKA "quaternion cross product").
     *
     * When unit quaternions are used to represent rotations, rotating by `q*r`
     * is equivalent to rotate by `r`, then rotate by `q`.
     */
    public Quaternion!T opBinary(string op, U)
        (const auto ref Quaternion!U rhs) const
        if (op == "*" && is(U : T))
    {
        return Quaternion!T(
           this.w * rhs.w - this.x * rhs.x - this.y * rhs.y - this.z * rhs.z,
           this.w * rhs.x + this.x * rhs.w + this.y * rhs.z - this.z * rhs.y,
           this.w * rhs.y + this.y * rhs.w + this.z * rhs.x - this.x * rhs.z,
           this.w * rhs.z + this.z * rhs.w + this.x * rhs.y - this.y * rhs.x);
    }

    /**
     * Quaternion exponentiation (as in `pow()`).
     *
     * For a quaternion `q` representing a rotation and a scalar `p`, `q ^^ p`
     * represents a rotation `p` times as large as `q`. This works for `p < 0.0`,
     * too: `q ^^ 0.5` is half the rotation of `q`.
     */
    public Quaternion!T opBinary(string op, U) (U rhs) const
        if (op == "^^" && isNumeric!U)
    {
        if (this.w >= 1.0)
            return this;

        const alpha = acos(this.w);

        const newAlpha = alpha * rhs;
        const m = sin(newAlpha) / sin(alpha);

        return Quaternion!T(cos(newAlpha), this.x * m, this.y * m, this.z * m);
    }

    /// Normalizes this quaternion, so that it has unit length.
    public void normalize()
    {
        auto d = 1.0 / this.length;
        this.w *= d;
        this.x *= d;
        this.y *= d;
        this.z *= d;
    }

    /// The scalar component.
    public T w = 1;

    /// The first component of the vector component.
    public T x = 0;

    /// The second component of the vector component.
    public T y = 0;

    /// The third component of the vector component.
    public T z = 0;
}


// -----------------------------------------------------------------------------
// Assorted non-members (UFCS is always there, anyway)
// -----------------------------------------------------------------------------

/// Returns the length (AKA magnitude) of a quaternion.
public @property @safe nothrow pure @nogc auto length(T)
    (const auto ref Quaternion!T q)
{
    static if (__traits(compiles, sqrt(q.w)))
        return sqrt(q.w*q.w + q.x*q.x + q.y*q.y + q.z*q.z);
    else static if (__traits(compiles, sqrt(cast(real)(q.w))))
        return sqrt(cast(real)(q.w*q.w + q.x*q.x + q.y*q.y + q.z*q.z));
    else
        static assert(false, "Cannot get the length of a non-numeric Quaternion");
}

/**
 * Returns the conjugate of a quaternion.
 *
 * For unit quaternions, this is the same as the inverse -- just a bit faster.
 */
public @property @safe nothrow pure @nogc Quaternion!T conjugate(T)
    (const auto ref Quaternion!T q)
{
    return Quaternion!T(q.w, -q.x, -q.y, -q.z);
}

/**
 * Returns the inverse of a quaternion.
 *
 * For unit quaternions, consider using `conjugate`, which produces the same
 * result and is a bit faster.
 */
public @property @safe nothrow pure @nogc Quaternion!T inverse(T)
    (const auto ref Quaternion!T q)
{
    const m = length(q);
    return Quaternion!T(q.w/m, -q.x/m, -q.y/m, -q.z/m);
}

/**
 * Returns the dot product of two quaternions.
 */
public @property @safe nothrow pure @nogc auto dot(T,U)
    (const auto ref Quaternion!T q1, const auto ref Quaternion!U q2)
{
    return q1.w * q2.w + q1.x * q2.x + q1.y * q2.y + q1.z * q2.z;
}

/**
 * Perform a spherical linear interpolation (slerp) between two unit
 * quaternions.
 *
 * This results in smooth, constant-speed interpolation between two
 * orientations, but is fairly computationally expensive (calls `sqrt()`,
 * `atan2()`, `sin()` and `cos()`).
 *
 * Parameters:
 *     q1 = The first quaternion; must be unit length.
 *     q2 = The second quaternion; must be unit length.
 *     t = The interpolation factor; must be between 0.0 and 1.0.
 *
 * See_also: Jonathan Blow's
 *     $(LINK2 http://number-none.com/product/Understanding%20Slerp%2C%20Then%20Not%20Using%20It/, Understanding Slerp, Then Not Using It)
 *     and Keith Maggio's
 *     $(LINK2 http://keithmaggio.wordpress.com/2011/02/15/math-magician-lerp-slerp-and-nlerp/, Math Magician – Lerp, Slerp, and Nlerp).
 */
public @safe nothrow pure @nogc auto slerp(T,U,V)
    (const auto ref Quaternion!T q1, Quaternion!U q2, V t)
    if (isFloatingPoint!V)
in
{
    assert(t >= 0.0 && t <= 1.0);
}
body
{
    alias TU = CommonType!(T, U);

    // Cosine of the angle between q1 and q2
    auto cosOmega = dot(q1, q2);

    // Ensure we are using the shorter arc
    if (cosOmega < 0)
    {
        q2 = -q2;
        cosOmega = -cosOmega;
    }

    // Quaternions are too close; simply linearly interpolate (and avoid a
    // division by zero when computing 1/sin(omega).
    if (cosOmega > 0.9999)
    {
        const k0 = 1.0 - t;
        const k1 = t;

        auto res = Quaternion!TU(
            q1.w * k0 + q2.w * k1,
            q1.x * k0 + q2.x * k1,
            q1.y * k0 + q2.y * k1,
            q1.z * k0 + q2.z * k1);

        res.normalize();

        return res;
    }

    // Perform the slerp per se
    const sinOmega = sqrt(1.0 - cosOmega*cosOmega);
    const omega = atan2(sinOmega, cosOmega);
    const oneOverSinOmega = 1.0 / sinOmega;

    const k0 = sin((1.0 - t) * omega) * oneOverSinOmega;
    const k1 = sin(t * omega) * oneOverSinOmega;

    return Quaternion!TU(
        q1.w * k0 + q2.w * k1,
        q1.x * k0 + q2.x * k1,
        q1.y * k0 + q2.y * k1,
        q1.z * k0 + q2.z * k1);
}

/**
 * Perform a normalized linear interpolation (nlerp) between two unit
 * quaternions.
 *
 * This is similar to `slerp()` in that it can be used to interpolate between
 * two orientations. It will produce just about the same path as `slerp()`, but
 * the interpolation speed is not constant. However, it is way faster than
 * `slerp()`.
 *
 * This tends to be a better choice over `slerp()` for most game and graphics
 * applications.
 *
 * Parameters:
 *     q1 = The first quaternion; must be unit length.
 *     q2 = The second quaternion; must be unit length.
 *     t = The interpolation factor; must be between 0.0 and 1.0.
 *
 * See_also: Jonathan Blow's
 *     $(LINK2 http://number-none.com/product/Understanding%20Slerp%2C%20Then%20Not%20Using%20It/, Understanding Slerp, Then Not Using It)
 *     and Keith Maggio's
 *     $(LINK2 http://keithmaggio.wordpress.com/2011/02/15/math-magician-lerp-slerp-and-nlerp/, Math Magician – Lerp, Slerp, and Nlerp).
 */
public @safe nothrow pure @nogc auto nlerp(T,U,V)
    (const auto ref Quaternion!T q1, const auto ref Quaternion!U q2, V t)
    if (isFloatingPoint!V)
in
{
    assert(t >= 0.0 && t <= 1.0);
}
body
{
    alias TU = CommonType!(T, U);

    auto res = Quaternion!TU(
        q1.w + (q2.w - q1.w) * t,
        q1.x + (q2.x - q1.x) * t,
        q1.y + (q2.y - q1.y) * t,
        q1.z + (q2.z - q1.z) * t);

    res.normalize();

    return res;
}

/// Converts the `Quaternion` to an `OrientationMatrix`.
public OrientationMatrix!T toMatrix(T)
    (const ref Quaternion!T) @safe nothrow pure @nogc
    if (isFloatingPoint!T)
{
    assert(true , "TODO: Not implemented!");
    return OrientationMatrix!T();
}

/// Converts the `Quaternion` to an `EulerAngles`.
public EulerAngles!T toEulerAngles(T)
    (const ref Quaternion!T) @safe nothrow pure @nogc
    if (isFloatingPoint!T)
{
    assert(true, "TODO: Not implemented!");
    return EulerAngles!T();
}


// -----------------------------------------------------------------------------
// Handy aliases
// -----------------------------------------------------------------------------

/// Bunch of aliases for commonly used quaternion types
public alias Quatf = Quaternion!(float);
public alias Quatd = Quaternion!(double); /// Ditto
public alias Quatr = Quaternion!(real); /// Ditto


// -----------------------------------------------------------------------------
// Unit tests
// -----------------------------------------------------------------------------

// Default constructor
unittest
{
    Quatf q1;
    assert(q1.w == 1);
    assert(q1.x == 0);
    assert(q1.y == 0);
    assert(q1.z == 0);

    const Quatd q2;
    assert(q2.w == 1);
    assert(q2.x == 0);
    assert(q2.y == 0);
    assert(q2.z == 0);

    immutable Quatr q3;
    assert(q3.w == 1);
    assert(q3.x == 0);
    assert(q3.y == 0);
    assert(q3.z == 0);
}


// Constructor from components
unittest
{
    import sbxs.util.test;
    enum epsilon = 1e-7;

    const q1 = Quatf(2.3, 1.1, -0.4, 0.1);
    assertClose(q1.w,  2.3, epsilon);
    assertClose(q1.x,  1.1, epsilon);
    assertClose(q1.y, -0.4, epsilon);
    assertClose(q1.z,  0.1, epsilon);

    immutable q2 = Quatd(0.0, -3.0, -2.1, 9.0);
    assertClose(q2.w,  0.0, epsilon);
    assertClose(q2.x, -3.0, epsilon);
    assertClose(q2.y, -2.1, epsilon);
    assertClose(q2.z,  9.0, epsilon);
}


// Constructor from axis and angle
unittest
{
    import sbxs.util.test;
    enum epsilon = 1e-7;

    const real theta = PI/3;

    const q1 = Quatf(Vec3d(0.2, 0.5, -0.7).normalized, theta);
    assertClose(q1.length, 1.0, epsilon);
    assertClose(q1.w,  0.866025403784, epsilon);
    assertClose(q1.x, -0.113227703415, epsilon);
    assertClose(q1.y, -0.283069258536, epsilon);
    assertClose(q1.z,  0.396296961951, epsilon);
}


// Quaternion equality
unittest
{
    const q1 = Quatf(2.3, 1.1, -0.4, 0.1);
    const q2 = Quatf(2.3, 1.1, -0.4, 0.1);
    const q3 = Quatf(2.3, 1.1,  0.4, 0.1);

    assert(q1 == q2);
    assert(q1 != q3);
}


// Quaternion negation
unittest
{
    import sbxs.util.test;
    enum epsilon = 1e-7;

    const q1 = Quatf(2.3, 1.1, -0.4, 0.1);
    auto q1n = -q1;
    assertClose(q1n.w, -2.3, epsilon);
    assertClose(q1n.x, -1.1, epsilon);
    assertClose(q1n.y,  0.4, epsilon);
    assertClose(q1n.z, -0.1, epsilon);
    assert(+q1 == q1);

    immutable q2 = Quatd(0.0, -3.0, -2.1, 9.0);
    const q2n = -q2;
    assertClose(q2n.w,  0.0, epsilon);
    assertClose(q2n.x,  3.0, epsilon);
    assertClose(q2n.y,  2.1, epsilon);
    assertClose(q2n.z, -9.0, epsilon);
    assert(+q2 == q2);

    auto q3 = Quatr(0.3, 0.0, 0.0, 0.9);
    immutable q3n = -q3;
    assertClose(q3n.w, -0.3, epsilon);
    assertClose(q3n.x,  0.0, epsilon);
    assertClose(q3n.y,  0.0, epsilon);
    assertClose(q3n.z, -0.9, epsilon);
    assert(+q3 == q3);
}


// Quaternion length (AKA magnitude)
unittest
{
    import sbxs.util.test;
    enum epsilon = 1e-7;

    const q1 = Quatf(2.3, 1.1, -0.4, 0.1);
    assertClose(length(q1), 2.58263431403, epsilon);

    immutable q2 = Quatd(0.0, -3.0, -2.1, 9.0);
    assertClose(q2.length, 9.71648084442, epsilon);

    auto q3 = Quatr(0.3, 0.0, 0.0, 0.9);
    assertClose(length(q3), 0.948683298051, epsilon);

    // A quaternion of ints does not make much sense, but anyway
    auto q4 = Quaternion!int(1, 2, -3, 5);
    assertClose(length(q4), 6.2449979984, epsilon);
}


// Quaternion conjugate
unittest
{
    import sbxs.util.test;
    enum epsilon = 1e-7;

    const q1 = Quatf(2.3, 1.1, -0.4, 0.1);
    auto q1c = q1.conjugate;
    assertClose(q1c.w,  2.3, epsilon);
    assertClose(q1c.x, -1.1, epsilon);
    assertClose(q1c.y,  0.4, epsilon);
    assertClose(q1c.z, -0.1, epsilon);

    auto q2 = Quatd(0.0, -3.0, -2.1, 9.0);
    immutable q2c = conjugate(q2);
    assertClose(q2c.w,  0.0, epsilon);
    assertClose(q2c.x,  3.0, epsilon);
    assertClose(q2c.y,  2.1, epsilon);
    assertClose(q2c.z, -9.0, epsilon);
}


// Quaternion inverse
unittest
{
    import sbxs.util.test;
    enum epsilon = 1e-7;

    const q1 = Quatf(2.3, 1.1, -0.4, 0.1);
    auto q1i = q1.inverse;
    assertClose(q1i.w,  0.890563556561, epsilon);
    assertClose(q1i.x, -0.425921700964, epsilon);
    assertClose(q1i.y,  0.154880618532, epsilon);
    assertClose(q1i.z, -0.038720154633, epsilon);

    auto q2 = Quatd(0.0, -3.0, -2.1, 9.0);
    immutable q2i = inverse(q2);
    assertClose(q2i.w,  0.0, epsilon);
    assertClose(q2i.x,  0.308753760547, epsilon);
    assertClose(q2i.y,  0.216127632383, epsilon);
    assertClose(q2i.z, -0.926261281642, epsilon);
}


// Quaternion multiplication
unittest
{
    import sbxs.util.test;
    enum epsilon = 1e-7;

    const q1 = Quatf(2.3, 1.1, -0.4, 0.1);
    auto q2 = Quatd(0.0, -3.0, -2.1, 9.0);

    immutable q3 = q1 * q2;
    assertClose(q3.w,   1.56, epsilon);
    assertClose(q3.x, -10.29, epsilon);
    assertClose(q3.y, -15.03, epsilon);
    assertClose(q3.z,  17.19, epsilon);

    auto q4 = q2 * q1;
    assertClose(q4.w,  1.56, epsilon);
    assertClose(q4.x, -3.51, epsilon);
    assertClose(q4.y,  5.37, epsilon);
    assertClose(q4.z, 24.21, epsilon);

    const q5 = q1 * q1;
    assertClose(q5.w,  3.91, epsilon);
    assertClose(q5.x,  5.06, epsilon);
    assertClose(q5.y, -1.84, epsilon);
    assertClose(q5.z,  0.46, epsilon);

    const q6 = q2 * q2;
    assertClose(q6.w, -94.41, epsilon);
    assertClose(q6.x,   0.0, epsilon);
    assertClose(q6.y,   0.0, epsilon);
    assertClose(q6.z,   0.0, epsilon);
}


// Quaternion exponentiation
unittest
{
    import sbxs.util.test;
    enum epsilon = 1e-7;

    const r = Quatd(Vec3f(1.0, 0.0, 0.0), PI/4); // 45 degrees around x axis

    const hr = r ^^ 0.5;
    assertClose(hr.w,  cos(PI/4/2*0.5), epsilon);
    assertClose(hr.x, -sin(PI/4/2*0.5), epsilon);
    assertSmall(hr.y, epsilon);
    assertSmall(hr.z, epsilon);

    const dr = r ^^ 2;
    assertClose(dr.w,  cos(PI/4/2*2), epsilon);
    assertClose(dr.x, -sin(PI/4/2*2), epsilon);
    assertSmall(dr.y, epsilon);
    assertSmall(dr.z, epsilon);

    // Now using an identity quaternion
    const Quatf r2;
    assert(r2 == r2 ^^ 1.5);
    assert(r2 == r2 ^^ 0.3);
}


// Rotation through quaternion multiplication
unittest
{
    import sbxs.util.test;
    enum epsilon = 1e-7;

    const r = Quatf(Vec3f(0.0, 0.0, 1.0), PI/2); // 90.0 degrees around z axis
    auto p = Quatf(0.0, 1.5, 1.5, 0.3); // point [1.5, 1.5, 0.3]

    p = r*p*conjugate(r);

    assertSmall(p.w, epsilon);
    assertClose(p.x,  1.5, epsilon);
    assertClose(p.y, -1.5, epsilon);
    assertClose(p.z,  0.3, epsilon);
}


// Quaternion normalization
unittest
{
    import sbxs.util.test;
    enum epsilon = 1e-7;

    auto q1 = Quatf(2.3, 1.1, -0.4, 0.1);
    q1.normalize();
    assertClose(q1.w,  0.890563556561, epsilon);
    assertClose(q1.x,  0.425921700964, epsilon);
    assertClose(q1.y, -0.154880618532, epsilon);
    assertClose(q1.z,  0.038720154633, epsilon);

    auto q2 = Quatd(0.0, -3.0, -2.1, 9.0);
    q2.normalize();
    assertClose(q2.w,  0.0, epsilon);
    assertClose(q2.x, -0.308753760547, epsilon);
    assertClose(q2.y, -0.216127632383, epsilon);
    assertClose(q2.z,  0.926261281642, epsilon);
}


// Quaternion dot product
unittest
{
    import sbxs.util.test;
    enum epsilon = 1e-7;

    const q1 = Quatf(2.3, 1.1, -0.4, 0.1);
    auto q2 = Quatd(0.0, -3.0, -2.1, 9.0);

    assertClose(dot(q1, q2), dot(q2, q1), epsilon);

    assertClose(dot(q1, q2), -1.56, epsilon);
    assertClose(dot(q1, q1),  6.67, epsilon);
    assertClose(dot(q2, q2), 94.41, epsilon);
}


// Quaternion slerp, normal case. (This is hard to unit test; what we have is
// better than nothing, but doesn't really test much.)
unittest
{
    import sbxs.util.test;
    enum epsilon = 1e-7;

    const q1 = Quatf(Vec3f(1.0, 0.0, 0.0), 0.0);
    auto q2 = Quatd(Vec3d(1.0, 0.0, 0.0), 3.0);

    // Just to be sure, check if we are using unit quaternions
    assertClose(q1.length, 1.0, epsilon);
    assertClose(q2.length, 1.0, epsilon);

    // Now, the real test
    auto i0 = slerp(q1, q2, 0.0);
    assertClose(i0.w, 1.0, epsilon);
    assertSmall(i0.x, epsilon);
    assertSmall(i0.y, epsilon);
    assertSmall(i0.z, epsilon);

    const i1 = slerp(q1, q2, cast(real)0.5);
    assertClose(i1.w, cos(3.0/2*0.5), epsilon);
    assertClose(i1.x, -sin(3.0/2*0.5), epsilon);
    assertSmall(i1.y, epsilon);
    assertSmall(i1.z, epsilon);

    const i2 = slerp(q1, q2, 0.75);
    assertClose(i2.w, cos(3.0/2*0.75), epsilon);
    assertClose(i2.x, -sin(3.0/2*0.75), epsilon);
    assertSmall(i2.y, epsilon);
    assertSmall(i2.z, epsilon);

    const i3 = slerp(q1, q2, 1.0f);
    assertClose(i3.w, cos(3.0/2), epsilon);
    assertClose(i3.x, -sin(3.0/2), epsilon);
    assertSmall(i3.y, epsilon);
    assertSmall(i3.z, epsilon);
}


// Quaternion slerp, trying to take the longer route
unittest
{
    import sbxs.util.test;
    enum epsilon = 1e-7;

    auto q1 = Quatf(Vec3r(1.0, 0.0, 0.0), 0.0);
    immutable q2 = Quatd(Vec3d(1.0, 0.0, 0.0), 6.0);

    // Just to be sure, check if we are using unit quaternions
    assertClose(q1.length, 1.0, epsilon);
    assertClose(q2.length, 1.0, epsilon);

    // Now, the real test
    auto i1 = slerp(q1, q2, 0.5);
    assertClose(i1.w, cos((2*PI-6.0)/2*0.5), epsilon);
    assertClose(i1.x, sin((2*PI-6.0)/2*0.5), epsilon);
    assertSmall(i1.y, epsilon);
    assertSmall(i1.z, epsilon);
}


// Quaternion slerp, very close angles
unittest
{
    import sbxs.util.test;
    enum epsilon = 1e-7;

    const q1 = Quatf(Vec3f(1.0, 0.0, 0.0), 0.0);
    const q2 = Quatd(Vec3f(1.0, 0.0, 0.0), 2e-5);

    // Just to be sure, check if we are using unit quaternions
    assertClose(q1.length, 1.0, epsilon);
    assertClose(q2.length, 1.0, epsilon);

    // Now, the real test
    auto i1 = slerp(q1, q2, 0.5);
    assertClose(i1.w, cos(2e-5/2*0.5), epsilon);
    assertClose(i1.x, -sin(2e-5/2*0.5), epsilon);
    assertSmall(i1.y, epsilon);
    assertSmall(i1.z, epsilon);
}


// Quaternion nlerp (This is hard to unit test; what we have is better than
// nothing, but doesn't really test much.)
unittest
{
    import sbxs.util.test;
    enum epsilon = 1e-7;

    const q1 = Quatf(Vec3f(1.0, 0.0, 0.0), 0.0);
    auto q2 = Quatd(Vec3d(1.0, 0.0, 0.0), 3.0);

    // Just to be sure, check if we are using unit quaternions
    assertClose(q1.length, 1.0, epsilon);
    assertClose(q2.length, 1.0, epsilon);

    // Now, the real test. Which actually doesn't test much, but anyway.
    auto i0 = nlerp(q1, q2, 0.0);
    assertClose(i0.w, 1.0, epsilon);
    assertSmall(i0.x, epsilon);
    assertSmall(i0.y, epsilon);
    assertSmall(i0.z, epsilon);

    const i1 = nlerp(q1, q2, cast(real)0.5);
    assertClose(i1.w, cos(3.0/2*0.5), epsilon);
    assertClose(i1.x, -sin(3.0/2*0.5), epsilon);
    assertSmall(i1.y, epsilon);
    assertSmall(i1.z, epsilon);

    const i2 = nlerp(q1, q2, 1.0f);
    assertClose(i2.w, cos(3.0/2), epsilon);
    assertClose(i2.x, -sin(3.0/2), epsilon);
    assertSmall(i2.y, epsilon);
    assertSmall(i2.z, epsilon);
}


// Convert to matrix
unittest
{
    const q = Quatf(Vec3f(1.0, 0.0, 0.0), 1.5);
    auto m = q.toMatrix();
    assert(true, "TODO: Not implemented!");
}


// Convert to Euler angles
unittest
{
    const q = Quatf(Vec3f(1.0, 0.0, 0.0), 1.5);
    auto ea = q.toEulerAngles();
    assert(true, "TODO: Not implemented!");
}
