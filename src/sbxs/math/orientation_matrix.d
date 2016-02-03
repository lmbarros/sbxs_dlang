/**
 * A matrix used to represent an orientation.
 *
 * License: MIT License, see the `LICENSE` file.
 *
 * Authors: Leandro Motta Barros.
 */

module sbxs.math.orientation_matrix;

import std.traits;
import sbxs.math.euler_angles;
import sbxs.math.matrix;
import sbxs.math.quaternion;
import sbxs.math.vector;


/**
 * A 4x4 matrix used to represent an orientation.
 *
 * Why not simply using a `Matrix` instead? Because using a dedicated type
 * for orientations leads to clear code. Basically, I am following the advice
 * given by Fletcher Dunn and Ian Parberry in their "3D Math Primer for Graphics
 * and Game Development" book.
 *
 * The "upright space" seen in this class is the coordinate space in which the
 * object is in an un-rotated orientation.
 */
public struct OrientationMatrix(T)
{
    @nogc: nothrow: @safe:

    /**
     * Creates the orientation matrix from an axis-angle representation.
     *
     * Parameters:
     *     n = The rotation axis; must be a unit-length vector.
     *     theta = The desired rotation angle, in radians. A positive angle
     *         rotates in the counter-clockwise direction (when looking into the
     *         positive axis).
     */
   public this(U, V)(Vector!(U, 3) n, V theta)
        if (isNumeric!U && isFloatingPoint!V)
    {
        _matrix = _matrix.rotation(n, theta);
    }

    /**
     * Constructs the orientation matrix directly from the given matrix
     * elements.
     */
    package this(U)(U m00, U m01, U m02,
                    U m10, U m11, U m12,
                    U m20, U m21, U m22)
        if (is(U: T))
    {
        _matrix = Matrix!(T, 4, 4)(m00, m01, m02, 0,
                                   m10, m11, m12, 0,
                                   m20, m21, m22, 0,
                                     0,   0,   0, 1 );
    }


    /// Transforms a vector in the upright to the object space.
    public Vector!(U, 4) uprightToObject(U)(const auto ref Vector!(U, 4) v)
        if (isFloatingPoint!U)
    {
        return v * _matrix;
    }

    /**
     * Transforms a vector in the object space to the upright space.
     *
     * TODO: I guess this can be optimized, by manually writing the code that
     * multiplies by the transposed matrix in a single step. This doesn't have to
     * be less efficient than `uprightToObject()`.
     */
    public Vector!(U, 4) objectToUpright(U)(const auto ref Vector!(U, 4) v)
        if (isFloatingPoint!U)
    {
        return v * _matrix.transposed;
    }

    /**
     * The matrix effectively storing the orientation.
     *
     * This matrix is used to transform from the upright space to the object
     * space.
     */
    private Matrix!(T, 4, 4) _matrix;
}


// -----------------------------------------------------------------------------
// Handy aliases
// -----------------------------------------------------------------------------

/// Bunch of aliases for commonly used matrix types.
public alias OrientationMatrixf = OrientationMatrix!(float);
public alias OrientationMatrixd = OrientationMatrix!(double); /// Ditto
public alias OrientationMatrixr = OrientationMatrix!(real); /// Ditto


// -----------------------------------------------------------------------------
// Assorted non-members (UFCS is always there, anyway)
// -----------------------------------------------------------------------------

/// Converts the `OrientationMatrix` to an `EulerAngles`.
public EulerAngles!T toEulerAngles(T)
   (const ref OrientationMatrix!T) @safe nothrow pure @nogc
   if (isFloatingPoint!T)
{
    assert(true, "TODO: Not implemented!");
    return EulerAngles!T();
}


/// Converts the `OrientationMatrix` to a `Quaternion`.
public Quaternion!T toQuaternion(T)
    (const ref OrientationMatrix!T) @safe nothrow pure @nogc
    if (isFloatingPoint!T)
{
    assert(true, "TODO: Not implemented!");
    return Quaternion!T();
}


// -----------------------------------------------------------------------------
// Unit tests
// -----------------------------------------------------------------------------

// uprightToObject() and objectToUpright()
unittest
{
    import sbxs.util.test;
    enum epsilon = 1e-5;

    const axis = Vec3f(-2.2, -1.6, 0.8).normalized;
    const theta = 4.56;

    auto mat = OrientationMatrixf(axis, theta);

    const v1 = mat.uprightToObject(Vec4d(0.3, -0.1, 0.4, 1.0));
    assertClose(v1.x,  0.206399, epsilon);
    assertClose(v1.y, -0.333978, epsilon);
    assertClose(v1.z, -0.325359, epsilon);
    assertClose(v1.w,  1.0, epsilon);

    auto v2 = mat.objectToUpright(v1);
    assertClose(v2.x,  0.3, epsilon);
    assertClose(v2.y, -0.1, epsilon);
    assertClose(v2.z,  0.4, epsilon);
    assertClose(v2.w,  1.0, epsilon);
}


// Convert to Euler angles
unittest
{
    const om = OrientationMatrixf(Vec3f(1.0, 0.0, 0.0), 1.5);
    auto ea = om.toEulerAngles();
    assert(true, "TODO: Not implemented!");
}


// Convert to quaternion
unittest
{
    const om = OrientationMatrixd(Vec3f(1.0, 0.0, 0.0), 1.5);
    auto q = om.toQuaternion();
    assert(true, "TODO: Not implemented!");
}
