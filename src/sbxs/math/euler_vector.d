/**
 * A rotation represented as an Euler vector.
 *
 * License: MIT License, see the `LICENSE` file.
 *
 * Authors: Leandro Motta Barros.
 */

module sbxs.math.euler_vector;

import std.traits;
import sbxs.math.vector;
import sbxs.util.test;


/**
 * An rotation represented as an Euler vector.
 *
 * Euler vector is the representation sometimes called exponential map. It is
 * like the axis-angle representation, but uses just a vector instead of the
 * vector and a scalar angle.
 *
 * The vector direction indicates the axis of rotation. The vector magnitude
 * indicates the rotation angle, in radians. As usual (for left-handed
 * coordinate systems like the one used in SBXS), a positive angle indicates a
 * rotation in the counter-clockwise direction (when looking into the axis'
 * positive end).
 *
 * A default-constructed `EulerVector` has a zero rotation.
 *
 * An `EulerVector` is usually the ideal representation to store angular
 * velocities, since it can store rotations larger than a "full spin".
 */
public struct EulerVector(T)
    if (isFloatingPoint!T)
{
    @nogc: nothrow: @safe:

    /**
     * Constructs the `EulerVector`.
     *
     * Parameters:
     *     axis = The axis around which the rotation is performed.
     *     angle = The rotation angle, in radians. Must be an unit vector.
     */
    public this(U, V)(Vector!(V, 3) axis, U angle)
        if (is (U : T) && is (V : T))
    in
    {
        assert(isClose(axis.squaredLength, 1.0, 1e-5));
    }
    body
    {
        _vector = axis * angle;
    }

    /**
     * The rotation axis.
     *
     * This is a unit vector, unless the angle is zero (in which case this is a
     * zero vector).
     */
    public @property Vector!(T, 3) axis() const
    {
        if (_vector.length() > 2 * T.epsilon)
            return _vector.normalized;
        else
            return Vector!(T, 3)(0.0, 0.0, 0.0);
    }

    /// Ditto
    public @property void axis(U)(Vector!(U, 3) axis)
        if (is (U : T))
    in
    {
        assert(isClose(axis.length, 1.0, 1e-5));
    }
    body
    {
        const angle = _vector.length;
        _vector = axis * angle;
    }

    /// The rotation angle, in radians.
    public @property T angle() const
    {
        return _vector.length;
    }

    /// Ditto
    public @property void angle(T angle)
    {
        if (_vector.length() > 2 * T.epsilon)
        {
            _vector.normalize;
            _vector *= angle;
        }
    }

    /// The Euler vector itself
    private Vector!(T, 3) _vector = Vector!(T, 3)(0.0, 0.0, 0.0);
}


// -----------------------------------------------------------------------------
// Handy aliases
// -----------------------------------------------------------------------------

/// Bunch of aliases for commonly used Euler vector types.
public alias EulerVectorf = EulerVector!(float);
public alias EulerVectord = EulerVector!(double); /// Ditto
public alias EulerVectorr = EulerVector!(real); /// Ditto


// -----------------------------------------------------------------------------
// Unit tests
// -----------------------------------------------------------------------------

// Construction
unittest
{
    import sbxs.util.test;
    enum epsilon = 1e-7;

    // Default constructor
    EulerVectorf ev1;
    assert(ev1.axis == Vec3f(0.0, 0.0, 0.0));
    assert(ev1.angle == 0.0);

    // Parameterful constructor
    const ev2 = EulerVectord(Vec3r(1.0, 0.0, 0.0), 2.0f);
    const axis2 = ev2.axis;
    assert(axis2.x == 1.0);
    assert(axis2.y == 0.0);
    assert(axis2.z == 0.0);
    assert(ev2.angle == 2.0);
}


// Getters and setters
unittest
{
    import sbxs.util.test;
    enum epsilon = 1e-7;

    auto ev1 = EulerVectorr(Vec3r(0.0, 1.0, 0.0), 2.0);

    // Set axis
    ev1.axis = Vec3d(0.0, 0.0, 1.0);
    assert(ev1.axis.x == 0.0);
    assert(ev1.axis.y == 0.0);
    assert(ev1.axis.z == 1.0);
    assert(ev1.angle == 2.0);

    // Set angle
    ev1.angle = 3.0;
    assert(ev1.angle == 3.0);
    assert(ev1.axis.x == 0.0);
    assert(ev1.axis.y == 0.0);
    assert(ev1.axis.z == 1.0);
}
