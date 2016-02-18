/**
 * Matrices in sizes from 2x2 to 4x4.
 *
 * License: MIT License, see the `LICENSE` file.
 *
 * Authors: Leandro Motta Barros (though almost everything here, to some
 * extent, is derived from public domain code from
 * $(LINK2 https://github.com/d-gamedev-team/gfm, GFM)).
 */

module sbxs.math.matrix;

import std.traits;
import std.typetuple;
import sbxs.math.vector;
import sbxs.util.test: isClose;


/**
 * Matrix template structure, for matrices in sizes from 2x2 to 4x4.
 *
 * Why limiting to these dimensions only? Because these are the ones that
 * interest me right now.
 *
 * Parameters:
 *     T = The type of the matrix elements.
 *     R = The number of rows; must be between 2 and 4, inclusive.
 *     C = The number of columns; must be between 2 and 4, inclusive.
 */
struct Matrix(T, size_t R, size_t C)
    if (R >= 2 && R <= 4 && C >= 2 && C <= 4)
{
    // -------------------------------------------------------------------------
    // Things which are not @safe and nothrow and pure and @nogc
    // -------------------------------------------------------------------------

    /**
     * Returns a string version of this matrix.
     *
     * Notice that, unlike almost everything else in this module, this method
     * is $(I not) `@nogc` nor `@safe`.
     */
    public nothrow @property string toString() const
    {
        import std.format: format;
        import std.exception: assumeWontThrow;

        string res = assumeWontThrow(format("[%s", Vector!(T, C)(_data[0..C])));

        for (auto i = 1; i < R; ++i)
        {
            res ~= assumeWontThrow(
                format(", %s", Vector!(T, C)(_data[i*C..i*C+C])));
        }

        res ~= "]";
        return res;
    }

    ///
    unittest
    {
        auto m1 = Mat2x4f(1.1, 2.2, 3.3, 4.4,
                        5.5, 6.6, 7.7, 8.8);
        assert(m1.toString == "[[1.1, 2.2, 3.3, 4.4], [5.5, 6.6, 7.7, 8.8]]");

        auto m2 = Mat4x3ui( 1,  2,  3,
                            4,  5,  6,
                            7,  8,  9,
                           10, 11, 12);
        assert(m2.toString == "[[1, 2, 3], [4, 5, 6], [7, 8, 9], [10, 11, 12]]");
    }


    // All methods below this point are @safe, nothrow, pure and @nogc
    @safe: nothrow: pure: @nogc:

    // -------------------------------------------------------------------------
    // Constructors and constructor-like static methods
    // -------------------------------------------------------------------------

    /// Constructs a `Matrix` with all elements equal to a given value.
    public this(U)(U value)
        if (is (U : T))
    {
        _data[] = value;
    }

    /**
     * Constructs a `Matrix` from set of values.
     *
     * Must pass one parameter per matrix element, which are assigned in a
     * row-major fashion.
     */
    public this(U...)(U values)
        if ((U.length == R*C) && allSatisfy!(isTConvertible, U))
    {
        foreach (i, x; values)
            _data[i] = x;
    }

    /// Constructs an identity matrix.
    public static @property Matrix identity()()
        if (isSquare)
    {
        Matrix!(T, R, C) res;

        for (auto i = 0; i < C; ++i) for (auto j = 0; j < R; ++j)
            res[i,j] = (i == j) ? 1 : 0;

        return res;
    }


    // -------------------------------------------------------------------------
    // Access to elements
    // -------------------------------------------------------------------------

    /**
     * Provides read and write access to elements through indexing.
     *
     * Use `m[i,j]` to access the element of `m` at the `i`-th row and `j`-th
     * column.
     */
    public ref inout(T) opIndex(size_t i, size_t j) inout
    in
    {
        assert(i < R && j < C, "Out of bounds Matrix indexing");
    }
    body
    {
        return _data[i * C + j];
    }

    /// Returns a pointer to the matrix data.
    public @property inout(T*) ptr() inout
    {
        return _data.ptr;
    }


    // -------------------------------------------------------------------------
    // Other operators
    // -------------------------------------------------------------------------

    /// Matrix equality
    public bool opEquals(U)(auto ref const Matrix!(U, R, C) other) const
        if (is(T : U))
    {
        for (auto i = 0; i < R*C; ++i)
        {
            if (_data[i] != other._data[i])
                return false;
        }

        return true;
    }

    /// Matrix negation and the useless-but-symmetric "unary plus".
    public Matrix opUnary(string op)() const
        if (op == "+" || op == "-")
    {
        Matrix res = void;
        for (auto i = 0; i < R*C; ++i)
            mixin("res._data[i] = " ~ op ~ "_data[i];");

        return res;
    }

    /// Multiply or divide all matrix elements by a scalar.
    public Matrix opBinary(string op, U)(U rhs) const
        if (isNumeric!U && (op == "*" || op == "/"))
    {
        Matrix res = this;
        mixin("res " ~ op ~ "= rhs;");
        return res;
    }

    /// Ditto
    public Matrix opBinaryRight(string op, U)(U lhs) const
        if (isNumeric!U && op == "*")
    {
        mixin("return this " ~ op ~ "lhs;");
    }

    /// Ditto
    public ref Matrix opOpAssign(string op, U)(U rhs)
        if (isNumeric!U && (op == "*" || op == "/"))
    {
        mixin("_data[] " ~ op ~ "= rhs;");
        return this;
    }

    /// Multiplies two matrices.
    public auto opBinary(string op, U, size_t R2, size_t C2)
        (auto ref const Matrix!(U, R2, C2) rhs) const
        if (op == "*" && C == R2)
    {
        alias V = CommonType!(T, U);

        Matrix!(V, R, C2) res = void;

        for (auto i = 0; i < R; ++i) for (auto j = 0; j < C2; ++j)
        {
            V sum = 0;

            for (auto k = 0; k < C; ++k)
                sum += this[i,k] * rhs[k,j];

            res[i,j] = sum;
        }

        return res;
    }

    /**
     * Multiplies a given vector (assumed to be a row vector) by this matrix.
     *
     * At this moment, the library doesn't provide any handy means to perform
     * matrix-vector multiplications using column vectors.
     */
    public auto opBinaryRight(string op, U)
        (auto ref const Vector!(U, R) lhs) const
        if (isNumeric!U && op == "*")
    {
        alias V = CommonType!(T, U);

        auto res = Vector!(V, R)(0);

        for (auto i = 0; i < R; ++i) for (auto j = 0; j < R; ++j)
            res[i] += lhs[j] * this[j,i];

        return res;
    }


    // -------------------------------------------------------------------------
    // Other matrix operations
    // -------------------------------------------------------------------------

    static if (isSquare)
    {
        /**
         * Transposes this matrix in place.
         *
         * Works only with square matrices, because non-square matrices would
         * change dimensions and matrices of different dimensions have different
         * types in this design.
         */
        public void transpose()
        {
            import std.algorithm;

            for (auto i = 0; i < R-1; ++i) for (auto j = i+1; j < C; ++j)
                swap(this[i,j], this[j,i]);
        }
    }


    // -------------------------------------------------------------------------
    // Helpers and utilities
    // -------------------------------------------------------------------------

    /// Can type `U` be converted to type `T`?
    private enum isTConvertible(U) = is(U : T);

    /// Is this a square matrix?
    public enum bool isSquare = (R == C);

    ///
    unittest
    {
        Mat3x3f m1;
        const m2 = Mat4x4s(cast(short)0);
        Mat2x4r m3;
        immutable m4 = Mat3x2i(3);

        assert(m1.isSquare);
        assert(m2.isSquare);
        assert(!m3.isSquare);
        assert(!m4.isSquare);
    }


    // -------------------------------------------------------------------------
    // Transforms
    // -------------------------------------------------------------------------

    static if (R == 2 && C == 2)
    {
        /**
         * Creates a matrix that performs a rotation around the origin in 2D.
         *
         * Parameters:
         *    theta = The desired rotation angle, in radians. A positive angle
         *       rotates in the counter-clockwise direction.
         *
         * Returns: The rotation matrix.
         */
        public static Matrix rotation(U)(U theta)
            if (isFloatingPoint!U)
        {
            import std.math;
            const c = cos(theta);
            const s = sin(theta);

            return Matrix!(T, 2, 2)( c, s,
                                    -s, c);
        }

        /**
         * Creates a matrix that performs a scaling along the coordinate axes in
         * 2D.
         *
         * Parameters:
         *     sx = Scaling factor along the $(I x) axis.
         *     sy = Scaling factor along the $(I y) axis.
         *
         * Returns: The scaling matrix.
         */
        public static Matrix scaling(U, V)(U sx, V sy)
            if (isNumeric!U && isNumeric!V)
        {
            return Matrix!(T, 2, 2)( sx, 0,
                                     0,  sy);
        }

        /**
         * Creates a matrix that performs a scaling along the coordinate axes in
         * 2D.
         *
         * Parameters:
         *     s = A 2D Vector with the scaling factors.
         *
         * Returns: The scaling matrix.
         */
        public static Matrix scaling(U)(auto ref const Vector!(U, 2) s)
            if (isNumeric!U)
        {
            return scaling(s.x, s.y);
        }

        /**
         * Creates a matrix that performs a scaling along an arbitrary axis in 2D.
         *
         * Parameters:
         *     n = A unit vector representing the axis along which the scaling will
         *         be performed.
         *     s = The desired scaling factor along `n`.
         *
         * Returns: The scaling matrix.
         */
        public static Matrix scaling(U, V)(auto ref const Vector!(U, 2) n, V s)
            if (isNumeric!U && isNumeric!V)
        in
        {
            assert(isClose(n.squaredLength, 1.0, 1e-5));
        }
        body
        {
            const ss = s - 1;
            const ssnxny = ss * n.x * n.y;
            return Matrix!(T, 2, 2)(1 + ss * n.x*n.x, ssnxny,
                                    ssnxny,           1 + ss * n.y*n.y);
        }

        /**
         * Creates a matrix that performs a 2D orthographic projection onto the
         * $(I x) axis.
         *
         * Returns: The projection matrix.
         */
        public static @property Matrix orthoProjX()()
        {
            return Matrix!(T, 2, 2)(1, 0,
                                    0, 0);
        }

        /**
         * Creates a matrix that performs a 2D orthographic projection onto the
         * $(I y) axis.
         *
         * Returns: The projection matrix.
         */
        public static @property Matrix orthoProjY()()
        {
            return Matrix!(T, 2, 2)(0, 0,
                                    0, 1);
        }

        /**
         * Creates a matrix that performs a 2D orthographic projection onto an
         * axis perpendicular to a given vector.
         *
         * Parameters:
         *     n = A unit vector perpendicular to the desired projection axis.
         *
         * Returns: The projection matrix.
         */
        public static Matrix orthoProj(U)(auto ref const Vector!(U, 2) n)
            if (isNumeric!U)
        in
        {
            assert(isClose(n.squaredLength, 1.0, 1e-5));
        }
        body
        {
            const mnxny = -n.x*n.y;
            return Matrix!(T, 2, 2)(1 - n.x*n.x, mnxny,
                                    mnxny,       1 - n.y*n.y);
        }

        /**
         * Creates a matrix that performs a 2D shearing (skewing) in the direction
         * of the $(I x) axis.
         *
         * Parameters:
         *     s = The "amount" to skew. To skew by `theta` radians, pass
         *         `atan(theta)` here.
         *
         * Returns: The shearing matrix.
         */
        public static Matrix shearingX(U)(U s)
            if (isNumeric!U)
        {
            return Matrix!(T, 2, 2)(1, 0,
                                    s, 1);
        }

        /**
         * Creates a matrix that performs a 2D shearing (skewing) in the direction
         * of the $(I y) axis.
         *
         * Parameters:
         *     s = The "amount" to skew. To skew by `theta` radians, pass
         *         `atan(theta)` here.
         *
         * Returns: The shearing matrix.
         */
        public static Matrix shearingY(U)(U s)
            if (isNumeric!U)
        {
            return Matrix!(T, 2, 2)(1, s,
                                    0, 1);
        }
    }

    static if (R == 3 && C == 3)
    {
        /**
         * Creates a 3x3 matrix that performs a rotation around the $(I x) axis
         * in 3D.
         *
         * Parameters:
         *     theta = The desired rotation angle, in radians. A positive angle
         *         rotates in the counter-clockwise direction (when looking into
         *         the positive $(I x) axis).
         *
         * Returns: The rotation matrix.
         */
        public static Matrix rotationX(U)(U theta)
            if (isFloatingPoint!U)
        {
            import std.math;
            const c = cos(theta);
            const s = sin(theta);

            return Matrix!(T, 3, 3)(1,  0, 0,
                                    0,  c, s,
                                    0, -s, c);
        }

        /**
         * Creates a 3x3 matrix that performs a rotation around the $(I y) axis
         * in 3D.
         *
         * Parameters:
         *     theta = The desired rotation angle, in radians. A positive angle
         *         rotates in the counter-clockwise direction (when looking into
         *         the positive $(I y) axis).
         *
         * Returns: The rotation matrix.
         */
        public static Matrix rotationY(U)(U theta)
            if (isFloatingPoint!U)
        {
            import std.math;
            const c = cos(theta);
            const s = sin(theta);

            return Matrix!(T, 3, 3)(c, 0, -s,
                                    0, 1,  0,
                                    s, 0,  c);
        }

        /**
         * Creates a 3x3 matrix that performs a rotation around the $(I z) axis
         * in 3D.
         *
         * Parameters:
         *     theta = The desired rotation angle, in radians. A positive angle
         *         rotates in the counter-clockwise direction (when looking into
         *         the positive $(I z) axis).
         *
         * Returns: The rotation matrix.
         */
        public static Matrix rotationZ(U)(U theta)
            if (isFloatingPoint!U)
        {
            import std.math;
            const c = cos(theta);
            const s = sin(theta);

            return Matrix!(T, 3, 3)( c, s, 0,
                                    -s, c, 0,
                                     0, 0, 1);
        }

        /**
         * Creates a 3x3 matrix that performs a rotation around an arbitrary axis
         * in 3D.
         *
         * Parameters:
         *     n = The rotation axis; must be a unit-length vector.
         *     theta = The desired rotation angle, in radians. A positive angle
         *         rotates in the counter-clockwise direction (when looking into
         *         the positive axis).
         *
         * Returns: The rotation matrix.
         */
        public static Matrix rotation(U, V)(Vector!(U, 3) n, V theta)
            if (isNumeric!U && isFloatingPoint!V)
        {
            import std.math;
            const c = cos(theta);
            const cc = 1.0 - c;
            const s = sin(theta);

            return Matrix!(T, 3, 3)
                (n.x*n.x*cc + c,     n.x*n.y*cc + n.z*s, n.x*n.z*cc - n.y*s,
                 n.x*n.y*cc - n.z*s, n.y*n.y*cc + c,     n.y*n.z*cc + n.x*s,
                 n.x*n.z*cc + n.y*s, n.y*n.z*cc - n.x*s, n.z*n.z*cc + c);
        }

        /**
         * Creates a 3x3 matrix that performs a scaling along the coordinate axes
         * in 3D.
         *
         * Parameters:
         *     sx = Scaling factor along the $(I x) axis.
         *     sy = Scaling factor along the $(I y) axis.
         *     sz = Scaling factor along the $(I z) axis.
         *
         * Returns: The rotation matrix.
         */
        public static Matrix scaling(U, V, W)(U sx, V sy, W sz)
            if (isNumeric!U && isNumeric!V && isNumeric!W)
        {
            return Matrix!(T, 3, 3)(sx, 0,  0,
                                    0,  sy, 0,
                                    0,  0,  sz);
        }

        /**
         * Creates 3x3 a matrix that performs a scaling along the coordinate axes
         * in 3D.
         *
         * Parameters:
         *     s = A 3D Vector with the scaling factors.
         *
         * Returns: The rotation matrix.
         */
        public static Matrix scaling(U)(auto ref const Vector!(U, 3) s)
            if (isNumeric!U)
        {
            return scaling(s.x, s.y, s.z);
        }

        /**
         * Creates a 3x3 matrix that performs a scaling along an arbitrary axis
         * in 3D.
         *
         * Parameters:
         *     n = A unit vector representing the axis along which the scaling
         *         will be performed.
         *     s = The desired scaling factor along `n`.
         *
         * Returns: The scaling matrix.
         */
        public static Matrix scaling(U, V)(auto ref const Vector!(U, 3) n, V s)
            if (isNumeric!U && isNumeric!V)
        in
        {
            assert(isClose(n.squaredLength, 1.0, 1e-5));
        }
        body
        {
            const ss = s - 1;
            return Matrix!(T, 3, 3)
                (1 + ss * n.x*n.x, ss * n.x*n.y,     ss * n.x*n.z,
                 ss * n.x*n.y,     1 + ss * n.y*n.y, ss * n.y*n.z,
                 ss * n.x*n.z,     ss * n.y*n.z,     1 + ss * n.z*n.z);
        }

        /**
         * Creates a matrix that performs a 3D orthographic projection onto the
         * $(I xy) plane.
         *
         * Returns: The projection matrix.
         */
        public static @property Matrix orthoProjXY()()
        {
            return Matrix!(T, 3, 3)(1, 0, 0,
                                    0, 1, 0,
                                    0, 0, 0);
        }

        /**
         * Creates a matrix that performs a 3D orthographic projection onto the
         * $(I xz) plane.
         *
         * Returns: The projection matrix.
         */
        public static @property Matrix orthoProjXZ()()
        {
            return Matrix!(T, 3, 3)(1, 0, 0,
                                    0, 0, 0,
                                    0, 0, 1);
        }

        /**
         * Creates a matrix that performs a 3D orthographic projection onto the
         * $(I yz) plane.
         *
         * Returns: The projection matrix.
         */
        public static @property Matrix orthoProjYZ()()
        {
            return Matrix!(T, 3, 3)(0, 0, 0,
                                    0, 1, 0,
                                    0, 0, 1);
        }

        /**
         * Creates a 3x3 matrix that performs a 3D orthographic projection onto a
         * plane perpendicular to a given vector.
         *
         * Parameters:
         *     n = A unit vector perpendicular to the desired projection plane.
         *
         * Returns: The projection matrix.
         */
        public static Matrix orthoProj(U)(auto ref const Vector!(U, 3) n)
        in
        {
            assert(isClose(n.length, 1.0, 1e-5));
        }
        body
        {
            const mnxny = -n.x*n.y;
            return Matrix!(T, 3, 3)(1 - n.x*n.x, -n.x*n.y,    -n.x*n.z,
                                    -n.x*n.y,    1 - n.y*n.y, -n.y*n.z,
                                    -n.x*n.z,    -n.y*n.z,    1-n.z*n.z);
        }

        /**
         * Creates a 3x3 matrix that performs a 3D shearing (skewing) in the
         * direction of the $(I x) and $(I y) axes.
         *
         * Parameters:
         *     s = The "amount" to skew in the $(I x) direction. To skew by
         *         `theta` radians, pass `atan(theta)` here.
         *     t = The "amount" to skew in the $(I y) direction. To skew by
         *         `theta` radians, pass `atan(theta)` here.
         *
         * Returns: The shearing matrix.
         */
        public static Matrix shearingXY(U, V)(U s, V t)
            if (isNumeric!U && isNumeric!V)
        {
            return Matrix!(T, 3, 3)(1, 0, 0,
                                    0, 1, 0,
                                    s, t, 1);
        }

        /**
         * Creates a 3x3 matrix that performs a 3D shearing (skewing) in the
         * direction of the $(I x) and $(I z) axes.
         *
         * Parameters:
         *     s = The "amount" to skew in the $(I x) direction. To skew by
         *         `theta` radians, pass `atan(theta)` here.
         *     t = The "amount" to skew in the $(I z) direction. To skew by
         *         `theta` radians, pass `atan(theta)` here.
         *
         * Returns: The shearing matrix.
         */
        public static Matrix shearingXZ(U, V)(U s, V t)
            if (isNumeric!U && isNumeric!V)
        {
            return Matrix!(T, 3, 3)(1, 0, 0,
                                    s, 1, t,
                                    0, 0, 1);
        }

        /**
         * Creates a 3x3 matrix that performs a 3D shearing (skewing) in the
         * direction of the $(I y) and $(I z) axes.
         *
         * Parameters:
         *     s = The "amount" to skew in the $(I y) direction. To skew by
         *         `theta` radians, pass `atan(theta)` here.
         *     t = The "amount" to skew in the $(I z) direction. To skew by
         *         `theta` radians, pass `atan(theta)` here.
         *
         * Returns: The shearing matrix.
         */
        public static Matrix shearingYZ(U, V)(U s, V t)
            if (isNumeric!U && isNumeric!V)
        {
            return Matrix!(T, 3, 3)(1, s, t,
                                    0, 1, 0,
                                    0, 0, 1);
        }
    }

    static if (R == 4 && C == 4)
    {
        /**
         * Creates a 4x4 matrix that performs a translation in 3D.
         *
         * Parameters:
         *     t = The desired translation, as a 3D vector containing the
         *         desired displacements along each axis.
         *
         * Returns: The translation matrix.
         */
        public static Matrix translation(U)(U tx, U ty, U tz)
            if (isNumeric!U)
        {
            return Matrix!(T, 4, 4)(1,  0,  0,  0,
                                    0,  1,  0,  0,
                                    0,  0,  1,  0,
                                    tx, ty, tz, 1);
        }

        /**
         * Creates a 4x4 matrix that performs a translation in 3D.
         *
         * Parameters:
         *     t = The desired translation, as a 3D vector containing the
         *         desired displacements along each axis.
         *
         * Returns: The translation matrix.
         */
        public static Matrix translation(U)(const auto ref Vector!(U, 3) t)
            if (isNumeric!U)
        {
            return translation(t.x, t.y, t.z);
        }

        /**
         * Creates a 4x4 matrix that performs a rotation around the $(I x) axis
         * in 3D.
         *
         * Parameters:
         *     theta = The desired rotation angle, in radians. A positive angle
         *         rotates in the counter-clockwise direction (when looking into
         *         the positive $(I x) axis).
         *
         * Returns: The rotation matrix.
         */
        public static Matrix rotationX(U)(U theta)
            if (isFloatingPoint!U)
        {
            import std.math;
            const c = cos(theta);
            const s = sin(theta);

            return Matrix!(T, 4, 4)(1,  0, 0, 0,
                                    0,  c, s, 0,
                                    0, -s, c, 0,
                                    0,  0, 0, 1);
        }

        /**
         * Creates a 4x4 matrix that performs a rotation around the $(I y) axis
         * in 3D.
         *
         * Parameters:
         *     theta = The desired rotation angle, in radians. A positive angle
         *         rotates in the counter-clockwise direction (when looking into
         *         the positive $(I y) axis).
         *
         * Returns: The rotation matrix.
         */
        public static Matrix rotationY(U)(U theta)
            if (isFloatingPoint!U)
        {
            import std.math;
            const c = cos(theta);
            const s = sin(theta);

            return Matrix!(T, 4, 4)(c, 0, -s, 0,
                                    0, 1,  0, 0,
                                    s, 0,  c, 0,
                                    0, 0,  0, 1);
        }

        /**
         * Creates a 4x4 matrix that performs a rotation around the $(I z) axis
         * in 3D.
         *
         * Parameters:
         *     theta = The desired rotation angle, in radians. A positive angle
         *         rotates in the counter-clockwise direction (when looking into
         *         the positive $(I z) axis).
         *
         * Returns: The rotation matrix.
         */
        public static Matrix rotationZ(U)(U theta)
            if (isFloatingPoint!U)
        {
            import std.math;
            const c = cos(theta);
            const s = sin(theta);

            return Matrix!(T, 4, 4)( c, s, 0, 0,
                                    -s, c, 0, 0,
                                     0, 0, 1, 0,
                                     0, 0, 0, 1);
        }

        /**
         * Creates a 4x4 matrix that performs a rotation around an arbitrary axis
         * in 3D.
         *
         * Parameters:
         *     n = The rotation axis; must be a unit-length vector.
         *     theta = The desired rotation angle, in radians. A positive angle
         *         rotates in the counter-clockwise direction (when looking into
         *         the positive axis).
         *
         * Returns: The rotation matrix.
         */
        public static Matrix rotation(U, V)(Vector!(U, 3) n, V theta)
            if (isNumeric!U && isFloatingPoint!V)
        {
            import std.math;
            const c = cos(theta);
            const cc = 1.0 - c;
            const s = sin(theta);

            return Matrix!(T, 4, 4)
                (n.x*n.x*cc + c,     n.x*n.y*cc + n.z*s, n.x*n.z*cc - n.y*s, 0,
                 n.x*n.y*cc - n.z*s, n.y*n.y*cc + c,     n.y*n.z*cc + n.x*s, 0,
                 n.x*n.z*cc + n.y*s, n.y*n.z*cc - n.x*s, n.z*n.z*cc + c,     0,
                 0,                  0,                  0,                  1);
        }

        /**
         * Creates a 4x4 matrix that performs a scaling along the coordinate axes
         * in 3D.
         *
         * Parameters:
         *     sx = Scaling factor along the $(I x) axis.
         *     sy = Scaling factor along the $(I y) axis.
         *     sz = Scaling factor along the $(I z) axis.
         *
         * Returns: The rotation matrix.
         */
        public static Matrix scaling(U, V, W)(U sx, V sy, W sz)
            if (isNumeric!U && isNumeric!V && isNumeric!W)
        {
            return Matrix!(T, 4, 4)(sx, 0,  0,  0,
                                    0,  sy, 0,  0,
                                    0,  0,  sz, 0,
                                    0,  0,  0,  1);
        }

        /**
         * Creates 4x4 a matrix that performs a scaling along the coordinate axes
         * in 3D.
         *
         * Parameters:
         *     s = A 3D Vector with the scaling factors.
         *
         * Returns: The rotation matrix.
         */
        public static Matrix scaling(U)(auto ref const Vector!(U, 3) s)
            if (isNumeric!U)
        {
            return scaling(s.x, s.y, s.z);
        }

        /**
         * Creates a 4x4 matrix that performs a scaling along an arbitrary axis
         * in 3D.
         *
         * Parameters:
         *     n = A unit vector representing the axis along which the scaling will
         *          be performed.
         *     s = The desired scaling factor along `n`.
         *
         * Returns: The scaling matrix.
         */
        public static Matrix scaling(U, V)(auto ref const Vector!(U, 3) n, V s)
            if (isNumeric!U && isNumeric!V)
        {
            const ss = s - 1;
            return Matrix!(T, 4, 4)
                (1 + ss * n.x*n.x, ss * n.x*n.y,     ss * n.x*n.z,     0,
                 ss * n.x*n.y,     1 + ss * n.y*n.y, ss * n.y*n.z,     0,
                 ss * n.x*n.z,     ss * n.y*n.z,     1 + ss * n.z*n.z, 0,
                 0,                0,                0,                1);
        }

        /**
         * Creates a 4x4 matrix that performs a 3D orthographic projection onto
         * the $(I xy) plane.
         *
         * Returns: The projection matrix.
         */
        public static @property Matrix orthoProjXY()()
        {
            return Matrix!(T, 4, 4)(1, 0, 0, 0,
                                    0, 1, 0, 0,
                                    0, 0, 0, 0,
                                    0, 0, 0, 1);
        }

        /**
         * Creates a 4x4 matrix that performs a 3D orthographic projection onto
         * the $(I xz) plane.
         *
         * Returns: The projection matrix.
         */
        public static @property Matrix orthoProjXZ()()
        {
            return Matrix!(T, 4, 4)(1, 0, 0, 0,
                                    0, 0, 0, 0,
                                    0, 0, 1, 0,
                                    0, 0, 0, 1);
        }

        /**
         * Creates a 4x4 matrix that performs a 3D orthographic projection onto
         * the $(I yz) plane.
         *
         * Returns: The projection matrix.
         */
        public static @property Matrix orthoProjYZ()()
        {
            return Matrix!(T, 4, 4)(0, 0, 0, 0,
                                    0, 1, 0, 0,
                                    0, 0, 1, 0,
                                    0, 0, 0, 1);
        }

        /**
         * Creates a 4x4 matrix that performs a 3D orthographic projection onto a
         * plane perpendicular to a given vector.
         *
         * Parameters:
         *     n = A unit vector perpendicular to the desired projection plane.
         *
         * Returns: The projection matrix.
         */
        public static Matrix orthoProj(U)(auto ref const Vector!(U, 3) n)
        {
            const mnxny = -n.x*n.y;
            return Matrix!(T, 4, 4)( 1 - n.x*n.x, -n.x*n.y,     -n.x*n.z,   0,
                                    -n.x*n.y,      1 - n.y*n.y, -n.y*n.z,   0,
                                    -n.x*n.z,     -n.y*n.z,      1-n.z*n.z, 0,
                                     0,            0,            0,         1);
        }

        /**
         * Creates a 4x4 matrix that performs a 3D shearing (skewing) in the
         * direction of the $(I x) and $(I y) axes.
         *
         * Parameters:
         *     s = The "amount" to skew in the $(I x) direction. To skew by
         *         `theta` radians, pass `atan(theta)` here.
         *     t = The "amount" to skew in the $(I y) direction. To skew by
         *         `theta` radians, pass `atan(theta)` here.
         *
         * Returns: The shearing matrix.
         */
        public static Matrix shearingXY(U, V)(U s, V t)
            if (isNumeric!U && isNumeric!V)
        {
            return Matrix!(T, 4, 4)(1, 0, 0, 0,
                                    0, 1, 0, 0,
                                    s, t, 1, 0,
                                    0, 0, 0, 1);
        }

        /**
         * Creates a 4x4 matrix that performs a 3D shearing (skewing) in the
         * direction of the $(I x) and $(I z) axes.
         *
         * Parameters:
         *     s = The "amount" to skew in the $(I x) direction. To skew by
         *         `theta` radians, pass `atan(theta)` here.
         *     t = The "amount" to skew in the $(I z) direction. To skew by
         *         `theta` radians, pass `atan(theta)` here.
         *
         * Returns: The shearing matrix.
         */
        public static Matrix shearingXZ(U, V)(U s, V t)
            if (isNumeric!U && isNumeric!V)
        {
            return Matrix!(T, 4, 4)(1, 0, 0, 0,
                                    s, 1, t, 0,
                                    0, 0, 1, 0,
                                    0, 0, 0, 1);
        }

        /**
         * Creates a 4x4 matrix that performs a 3D shearing (skewing) in the
         * direction of the $(I y) and $(I z) axes.
         *
         * Parameters:
         *     s = The "amount" to skew in the $(I y) direction. To skew by
         *         `theta` radians, pass `atan(theta)` here.
         *     t = The "amount" to skew in the $(I z) direction. To skew by
         *         `theta` radians, pass `atan(theta)` here.
         *
         * Returns: The shearing matrix.
         */
        public static Matrix shearingYZ(U, V)(U s, V t)
            if (isNumeric!U && isNumeric!V)
        {
            return Matrix!(T, 4, 4)(1, s, t, 0,
                                    0, 1, 0, 0,
                                    0, 0, 1, 0,
                                    0, 0, 0, 1);
        }
    }


    // -------------------------------------------------------------------------
    // Data members
    // -------------------------------------------------------------------------

    /// Matrix data, stored in row-major order.
    private T[R*C] _data;
}


// -----------------------------------------------------------------------------
// Stuff that looks better as non-members (UFCS is always there, anyway)
// -----------------------------------------------------------------------------

/// Returns a transposed copy of a given matrix.
public @property @safe nothrow pure @nogc
Matrix!(T, C, R) transposed(T, size_t R, size_t C)
    (auto ref const Matrix!(T, R, C) m)
{
    Matrix!(T, C, R) res;

    for (auto i = 0; i < C; ++i) for (auto j = 0; j < R; ++j)
        res[i,j] = m[j,i];

    return res;
}

/// Returns a vector with the diagonal of a given matrix.
public @property @safe nothrow pure @nogc
Vector!(T, N) diagonal(T, size_t N)(auto ref const Matrix!(T, N, N) m)
{
    Vector!(T, N) res;

    for (auto i = 0; i < N; ++i)
        res[i] = m[i,i];

    return res;
}

/**
 * Returns the determinant of a given square matrix.
 *
 * This is implemented for 2x2, 3x3 and 4x4 matrices.
 */
public @property @safe nothrow pure @nogc
T determinant(T)(auto ref const Matrix!(T, 2, 2) m)
    if (isNumeric!T)
{
    return m[0,0]*m[1,1] - m[0,1]*m[1,0];
}

/// Ditto
public @property @safe nothrow pure @nogc
T determinant(T)(auto ref const Matrix!(T, 3, 3) m)
    if (isNumeric!T)
{
    return m[0,0]*m[1,1]*m[2,2] + m[0,1]*m[1,2]*m[2,0] + m[0,2]*m[1,0]*m[2,1]
        -m[0,2]*m[1,1]*m[2,0] - m[0,1]*m[1,0]*m[2,2] - m[0,0]*m[1,2]*m[2,1];
}

/// Ditto
public @property @safe nothrow pure @nogc
T determinant(T)(auto ref const Matrix!(T, 4, 4) m)
    if (isNumeric!T)
{
    return
        + m[0,0] * (+ m[1,1] * (m[2,2]*m[3,3] - m[2,3]*m[3,2])
                    + m[1,2] * (m[2,3]*m[3,1] - m[2,1]*m[3,3])
                    + m[1,3] * (m[2,1]*m[3,2] - m[2,2]*m[3,1]))

        - m[0,1] * (+ m[1,0] * (m[2,2]*m[3,3] - m[2,3]*m[3,2])
                    + m[1,2] * (m[2,3]*m[3,0] - m[2,0]*m[3,3])
                    + m[1,3] * (m[2,0]*m[3,2] - m[2,2]*m[3,0]))

        + m[0,2] * (+ m[1,0] * (m[2,1]*m[3,3] - m[2,3]*m[3,1])
                    + m[1,1] * (m[2,3]*m[3,0] - m[2,0]*m[3,3])
                    + m[1,3] * (m[2,0]*m[3,1] - m[2,1]*m[3,0]))

        - m[0,3] * (+ m[1,0] * (m[2,1]*m[3,2] - m[2,2]*m[3,1])
                    + m[1,1] * (m[2,2]*m[3,0] - m[2,0]*m[3,2])
                    + m[1,2] * (m[2,0]*m[3,1] - m[2,1]*m[3,0]));
}

/**
 * Returns the inverse of a given square matrix.
 *
 * This is implemented for 2x2, 3x3 and 4x4 matrices. Uses the classical adjoint
 * method, which should be a good choice for matrices of this size.
 *
 * The caller is responsible for checking whether the matrix is invertible; the
 * code here will not make any test to ensure this. The usual way to test if a
 * matrix is invertible is to compute its determinant: if it is zero, then the
 * matrix is not invertible.
 *
 * Computing the inverse requires computing the determinant; since you may have
 * already computed it to ensure that the matrix is invertible, there are
 * overloads taking the determinant as parameter, so that some CPU cycles can be
 * spared.
 *
 * Parameters:
 *     m = The matrix to invert.
 *     det = The matrix determinant (see discussion above).
 *
 * Returns: The inverse of `m`.
 */
public @property @safe nothrow pure @nogc
auto inverse(T, size_t N)(auto ref const Matrix!(T, N, N) m)
    if (isFloatingPoint!T && m.isSquare && N >= 2 && N <= 4)
{
    return inverse(m, m.determinant);
}

/// Ditto
public @property @safe nothrow pure @nogc
auto inverse(T)(auto ref const Matrix!(T, 2, 2) m, T det)
    if (isFloatingPoint!T)
{
    const invDet = 1.0 / det;
    return Matrix!(T, 2, 2)( m[1,1] * invDet, -m[0,1] * invDet,
                            -m[1,0] * invDet,  m[0,0] * invDet);
}

/// Ditto
public @property @safe nothrow pure @nogc
auto inverse(T)(auto ref const Matrix!(T, 3, 3) m, T det)
   if (isFloatingPoint!T)
{
    const invDet = 1.0 / det;

    Matrix!(T, 3, 3) res = void;
    res[0,0] =  (m[1,1] * m[2,2] - m[2,1] * m[1,2]) * invDet;
    res[0,1] = -(m[0,1] * m[2,2] - m[0,2] * m[2,1]) * invDet;
    res[0,2] =  (m[0,1] * m[1,2] - m[0,2] * m[1,1]) * invDet;
    res[1,0] = -(m[1,0] * m[2,2] - m[1,2] * m[2,0]) * invDet;
    res[1,1] =  (m[0,0] * m[2,2] - m[0,2] * m[2,0]) * invDet;
    res[1,2] = -(m[0,0] * m[1,2] - m[1,0] * m[0,2]) * invDet;
    res[2,0] =  (m[1,0] * m[2,1] - m[2,0] * m[1,1]) * invDet;
    res[2,1] = -(m[0,0] * m[2,1] - m[2,0] * m[0,1]) * invDet;
    res[2,2] =  (m[0,0] * m[1,1] - m[1,0] * m[0,1]) * invDet;

    return res;
}

/// Ditto
public @property @safe nothrow pure @nogc
auto inverse(T)(auto ref const Matrix!(T, 4, 4) m, T det)
    if (isFloatingPoint!T)
{
    const invDet = 1.0 / det;

    Matrix!(T, 4, 4) res = void;

    const d2_01_01 = m[0,0] * m[1,1] - m[0,1] * m[1,0];
    const d2_01_02 = m[0,0] * m[1,2] - m[0,2] * m[1,0];
    const d2_01_03 = m[0,0] * m[1,3] - m[0,3] * m[1,0];
    const d2_01_12 = m[0,1] * m[1,2] - m[0,2] * m[1,1];
    const d2_01_13 = m[0,1] * m[1,3] - m[0,3] * m[1,1];
    const d2_01_23 = m[0,2] * m[1,3] - m[0,3] * m[1,2];

    const d2_03_01 = m[0,0] * m[3,1] - m[0,1] * m[3,0];
    const d2_03_02 = m[0,0] * m[3,2] - m[0,2] * m[3,0];
    const d2_03_03 = m[0,0] * m[3,3] - m[0,3] * m[3,0];
    const d2_03_12 = m[0,1] * m[3,2] - m[0,2] * m[3,1];
    const d2_03_13 = m[0,1] * m[3,3] - m[0,3] * m[3,1];
    const d2_03_23 = m[0,2] * m[3,3] - m[0,3] * m[3,2];
    const d2_13_01 = m[1,0] * m[3,1] - m[1,1] * m[3,0];
    const d2_13_02 = m[1,0] * m[3,2] - m[1,2] * m[3,0];
    const d2_13_03 = m[1,0] * m[3,3] - m[1,3] * m[3,0];
    const d2_13_12 = m[1,1] * m[3,2] - m[1,2] * m[3,1];
    const d2_13_13 = m[1,1] * m[3,3] - m[1,3] * m[3,1];
    const d2_13_23 = m[1,2] * m[3,3] - m[1,3] * m[3,2];

    const d3_201_012 = m[2,0] * d2_01_12 - m[2,1] * d2_01_02 + m[2,2] * d2_01_01;
    const d3_201_013 = m[2,0] * d2_01_13 - m[2,1] * d2_01_03 + m[2,3] * d2_01_01;
    const d3_201_023 = m[2,0] * d2_01_23 - m[2,2] * d2_01_03 + m[2,3] * d2_01_02;
    const d3_201_123 = m[2,1] * d2_01_23 - m[2,2] * d2_01_13 + m[2,3] * d2_01_12;

    const d3_203_012 = m[2,0] * d2_03_12 - m[2,1] * d2_03_02 + m[2,2] * d2_03_01;
    const d3_203_013 = m[2,0] * d2_03_13 - m[2,1] * d2_03_03 + m[2,3] * d2_03_01;
    const d3_203_023 = m[2,0] * d2_03_23 - m[2,2] * d2_03_03 + m[2,3] * d2_03_02;
    const d3_203_123 = m[2,1] * d2_03_23 - m[2,2] * d2_03_13 + m[2,3] * d2_03_12;

    const d3_213_012 = m[2,0] * d2_13_12 - m[2,1] * d2_13_02 + m[2,2] * d2_13_01;
    const d3_213_013 = m[2,0] * d2_13_13 - m[2,1] * d2_13_03 + m[2,3] * d2_13_01;
    const d3_213_023 = m[2,0] * d2_13_23 - m[2,2] * d2_13_03 + m[2,3] * d2_13_02;
    const d3_213_123 = m[2,1] * d2_13_23 - m[2,2] * d2_13_13 + m[2,3] * d2_13_12;

    const d3_301_012 = m[3,0] * d2_01_12 - m[3,1] * d2_01_02 + m[3,2] * d2_01_01;
    const d3_301_013 = m[3,0] * d2_01_13 - m[3,1] * d2_01_03 + m[3,3] * d2_01_01;
    const d3_301_023 = m[3,0] * d2_01_23 - m[3,2] * d2_01_03 + m[3,3] * d2_01_02;
    const d3_301_123 = m[3,1] * d2_01_23 - m[3,2] * d2_01_13 + m[3,3] * d2_01_12;

    res[0,0] = - d3_213_123 * invDet;
    res[1,0] = + d3_213_023 * invDet;
    res[2,0] = - d3_213_013 * invDet;
    res[3,0] = + d3_213_012 * invDet;

    res[0,1] = + d3_203_123 * invDet;
    res[1,1] = - d3_203_023 * invDet;
    res[2,1] = + d3_203_013 * invDet;
    res[3,1] = - d3_203_012 * invDet;

    res[0,2] = + d3_301_123 * invDet;
    res[1,2] = - d3_301_023 * invDet;
    res[2,2] = + d3_301_013 * invDet;
    res[3,2] = - d3_301_012 * invDet;

    res[0,3] = - d3_201_123 * invDet;
    res[1,3] = + d3_201_023 * invDet;
    res[2,3] = - d3_201_013 * invDet;
    res[3,3] = + d3_201_012 * invDet;

    return res;
}


/**
 * Orthonormalizes a given matrix, in-place.
 *
 * Internally, this uses `orthonormalize()` passing the matrix rows as
 * parameters. So, everything said in `orthonormalize()`'s documentation is
 * also valid here.
 *
 * Parameters:
 *     m = The matrix to orthogonalize.
 *
 * Returns: `m`, for convenience.
 *
 * TODO: Current implementation copies matrix data to temporary vectors, and
 *     then back to the matrix; this can be done $(I really) in-place, and avoid
 *     those copies.
 */
public @property @safe nothrow pure @nogc
ref Matrix!(T, 2, 2) orthonormalize(T)(ref Matrix!(T, 2, 2) m)
    if (isFloatingPoint!T)
{
    auto v1 = Vector!(T, 2)(m._data[0..2]);
    auto v2 = Vector!(T, 2)(m._data[2..4]);

    sbxs.math.vector.orthonormalize(v1, v2);

    m._data = [ v1.x, v1.y,
                v2.x, v2.y];

    return m;
}

/// Ditto
public @property @safe nothrow pure @nogc
ref Matrix!(T, 3, 3) orthonormalize(T)(ref Matrix!(T, 3, 3) m)
    if (isFloatingPoint!T)
{
    auto v1 = Vector!(T, 3)(m._data[0..3]);
    auto v2 = Vector!(T, 3)(m._data[3..6]);
    auto v3 = Vector!(T, 3)(m._data[6..9]);

    sbxs.math.vector.orthonormalize(v1, v2, v3);

    m._data = [ v1.x, v1.y, v1.z,
                v2.x, v2.y, v2.z,
                v3.x, v3.y, v3.z ];

    return m;
}

/// Ditto
public @property @safe nothrow pure @nogc
ref Matrix!(T, 4, 4) orthonormalize(T)(ref Matrix!(T, 4, 4) m)
    if (isFloatingPoint!T)
{
    auto v1 = Vector!(T, 4)(m._data[0..4]);
    auto v2 = Vector!(T, 4)(m._data[4..8]);
    auto v3 = Vector!(T, 4)(m._data[8..12]);
    auto v4 = Vector!(T, 4)(m._data[12..16]);

    sbxs.math.vector.orthonormalize(v1, v2, v3, v4);

    m._data = [ v1.x, v1.y, v1.z, v1.w,
                v2.x, v2.y, v2.z, v2.w,
                v3.x, v3.y, v3.z, v3.w,
                v4.x, v4.y, v4.z, v4.w ];

    return m;
}


// -----------------------------------------------------------------------------
// Handy aliases
// -----------------------------------------------------------------------------

/**
 * Bunch of aliases for commonly used matrix types.
 *
 * A type `Mat2x3f` represents a matrix of `float`s with 2 rows by 3 columns.
 */
public alias Mat2x2f = Matrix!(float, 2, 2);
public alias Mat2x2d = Matrix!(double, 2, 2); /// Ditto
public alias Mat2x2r = Matrix!(real, 2, 2); /// Ditto
public alias Mat2x2b = Matrix!(byte, 2, 2); /// Ditto
public alias Mat2x2ub = Matrix!(ubyte, 2, 2); /// Ditto
public alias Mat2x2s = Matrix!(short, 2, 2); /// Ditto
public alias Mat2x2us = Matrix!(ushort, 2, 2); /// Ditto
public alias Mat2x2i = Matrix!(int, 2, 2); /// Ditto
public alias Mat2x2ui = Matrix!(uint, 2, 2); /// Ditto
public alias Mat2x2l = Matrix!(long, 2, 2); /// Ditto
public alias Mat2x2ul = Matrix!(ulong, 2, 2); /// Ditto

public alias Mat2x3f = Matrix!(float, 2, 3); /// Ditto
public alias Mat2x3d = Matrix!(double, 2, 3); /// Ditto
public alias Mat2x3r = Matrix!(real, 2, 3); /// Ditto
public alias Mat2x3b = Matrix!(byte, 2, 3); /// Ditto
public alias Mat2x3ub = Matrix!(ubyte, 2, 3); /// Ditto
public alias Mat2x3s = Matrix!(short, 2, 3); /// Ditto
public alias Mat2x3us = Matrix!(ushort, 2, 3); /// Ditto
public alias Mat2x3i = Matrix!(int, 2, 3); /// Ditto
public alias Mat2x3ui = Matrix!(uint, 2, 3); /// Ditto
public alias Mat2x3l = Matrix!(long, 2, 3); /// Ditto
public alias Mat2x3ul = Matrix!(ulong, 2, 3); /// Ditto

public alias Mat2x4f = Matrix!(float, 2, 4); /// Ditto
public alias Mat2x4d = Matrix!(double, 2, 4); /// Ditto
public alias Mat2x4r = Matrix!(real, 2, 4); /// Ditto
public alias Mat2x4b = Matrix!(byte, 2, 4); /// Ditto
public alias Mat2x4ub = Matrix!(ubyte, 2, 4); /// Ditto
public alias Mat2x4s = Matrix!(short, 2, 4); /// Ditto
public alias Mat2x4us = Matrix!(ushort, 2, 4); /// Ditto
public alias Mat2x4i = Matrix!(int, 2, 4); /// Ditto
public alias Mat2x4ui = Matrix!(uint, 2, 4); /// Ditto
public alias Mat2x4l = Matrix!(long, 2, 4); /// Ditto
public alias Mat2x4ul = Matrix!(ulong, 2, 4); /// Ditto

public alias Mat3x2f = Matrix!(float, 3, 2); /// Ditto
public alias Mat3x2d = Matrix!(double, 3, 2); /// Ditto
public alias Mat3x2r = Matrix!(real, 3, 2); /// Ditto
public alias Mat3x2b = Matrix!(byte, 3, 2); /// Ditto
public alias Mat3x2ub = Matrix!(ubyte, 3, 2); /// Ditto
public alias Mat3x2s = Matrix!(short, 3, 2); /// Ditto
public alias Mat3x2us = Matrix!(ushort, 3, 2); /// Ditto
public alias Mat3x2i = Matrix!(int, 3, 2); /// Ditto
public alias Mat3x2ui = Matrix!(uint, 3, 2); /// Ditto
public alias Mat3x2l = Matrix!(long, 3, 2); /// Ditto
public alias Mat3x2ul = Matrix!(ulong, 3, 2); /// Ditto

public alias Mat3x3f = Matrix!(float, 3, 3); /// Ditto
public alias Mat3x3d = Matrix!(double, 3, 3); /// Ditto
public alias Mat3x3r = Matrix!(real, 3, 3); /// Ditto
public alias Mat3x3b = Matrix!(byte, 3, 3); /// Ditto
public alias Mat3x3ub = Matrix!(ubyte, 3, 3); /// Ditto
public alias Mat3x3s = Matrix!(short, 3, 3); /// Ditto
public alias Mat3x3us = Matrix!(ushort, 3, 3); /// Ditto
public alias Mat3x3i = Matrix!(int, 3, 3); /// Ditto
public alias Mat3x3ui = Matrix!(uint, 3, 3); /// Ditto
public alias Mat3x3l = Matrix!(long, 3, 3); /// Ditto
public alias Mat3x3ul = Matrix!(ulong, 3, 3); /// Ditto

public alias Mat3x4f = Matrix!(float, 3, 4); /// Ditto
public alias Mat3x4d = Matrix!(double, 3, 4); /// Ditto
public alias Mat3x4r = Matrix!(real, 3, 4); /// Ditto
public alias Mat3x4b = Matrix!(byte, 3, 4); /// Ditto
public alias Mat3x4ub = Matrix!(ubyte, 3, 4); /// Ditto
public alias Mat3x4s = Matrix!(short, 3, 4); /// Ditto
public alias Mat3x4us = Matrix!(ushort, 3, 4); /// Ditto
public alias Mat3x4i = Matrix!(int, 3, 4); /// Ditto
public alias Mat3x4ui = Matrix!(uint, 3, 4); /// Ditto
public alias Mat3x4l = Matrix!(long, 3, 4); /// Ditto
public alias Mat3x4ul = Matrix!(ulong, 3, 4); /// Ditto

public alias Mat4x2f = Matrix!(float, 4, 2); /// Ditto
public alias Mat4x2d = Matrix!(double, 4, 2); /// Ditto
public alias Mat4x2r = Matrix!(real, 4, 2); /// Ditto
public alias Mat4x2b = Matrix!(byte, 4, 2); /// Ditto
public alias Mat4x2ub = Matrix!(ubyte, 4, 2); /// Ditto
public alias Mat4x2s = Matrix!(short, 4, 2); /// Ditto
public alias Mat4x2us = Matrix!(ushort, 4, 2); /// Ditto
public alias Mat4x2i = Matrix!(int, 4, 2); /// Ditto
public alias Mat4x2ui = Matrix!(uint, 4, 2); /// Ditto
public alias Mat4x2l = Matrix!(long, 4, 2); /// Ditto
public alias Mat4x2ul = Matrix!(ulong, 4, 2); /// Ditto

public alias Mat4x3f = Matrix!(float, 4, 3); /// Ditto
public alias Mat4x3d = Matrix!(double, 4, 3); /// Ditto
public alias Mat4x3r = Matrix!(real, 4, 3); /// Ditto
public alias Mat4x3b = Matrix!(byte, 4, 3); /// Ditto
public alias Mat4x3ub = Matrix!(ubyte, 4, 3); /// Ditto
public alias Mat4x3s = Matrix!(short, 4, 3); /// Ditto
public alias Mat4x3us = Matrix!(ushort, 4, 3); /// Ditto
public alias Mat4x3i = Matrix!(int, 4, 3); /// Ditto
public alias Mat4x3ui = Matrix!(uint, 4, 3); /// Ditto
public alias Mat4x3l = Matrix!(long, 4, 3); /// Ditto
public alias Mat4x3ul = Matrix!(ulong, 4, 3); /// Ditto

public alias Mat4x4f = Matrix!(float, 4, 4); /// Ditto
public alias Mat4x4d = Matrix!(double, 4, 4); /// Ditto
public alias Mat4x4r = Matrix!(real, 4, 4); /// Ditto
public alias Mat4x4b = Matrix!(byte, 4, 4); /// Ditto
public alias Mat4x4ub = Matrix!(ubyte, 4, 4); /// Ditto
public alias Mat4x4s = Matrix!(short, 4, 4); /// Ditto
public alias Mat4x4us = Matrix!(ushort, 4, 4); /// Ditto
public alias Mat4x4i = Matrix!(int, 4, 4); /// Ditto
public alias Mat4x4ui = Matrix!(uint, 4, 4); /// Ditto
public alias Mat4x4l = Matrix!(long, 4, 4); /// Ditto
public alias Mat4x4ul = Matrix!(ulong, 4, 4); /// Ditto



// -----------------------------------------------------------------------------
// Unit tests
// -----------------------------------------------------------------------------

// Construction from a single value
unittest
{
    import sbxs.util.test;

    auto m1 = Mat3x3f(1.0);

    assert(m1._data[0] == 1.0);
    assert(m1._data[1] == 1.0);
    assert(m1._data[2] == 1.0);

    assert(m1._data[3] == 1.0);
    assert(m1._data[4] == 1.0);
    assert(m1._data[5] == 1.0);

    assert(m1._data[6] == 1.0);
    assert(m1._data[7] == 1.0);
    assert(m1._data[8] == 1.0);

    const m2 = Mat2x4ub(cast(ubyte)55);

    assert(m2._data[0] == 55);
    assert(m2._data[1] == 55);
    assert(m2._data[2] == 55);
    assert(m2._data[3] == 55);

    assert(m2._data[4] == 55);
    assert(m2._data[5] == 55);
    assert(m2._data[6] == 55);
    assert(m2._data[7] == 55);
}

// Construction from values
unittest
{
    auto m1 = Mat4x4f( 0.0,   1.0,  2.0,  3.0,
                       4.0,   5.0,  6.0,  7.0,
                       8.0,   9.0, 10.0, 11.0,
                       12.0, 13.0, 14.0, 15.0);

    assert(m1._data[0]  ==  0.0);
    assert(m1._data[1]  ==  1.0);
    assert(m1._data[2]  ==  2.0);
    assert(m1._data[3]  ==  3.0);

    assert(m1._data[4]  ==  4.0);
    assert(m1._data[5]  ==  5.0);
    assert(m1._data[6]  ==  6.0);
    assert(m1._data[7]  ==  7.0);

    assert(m1._data[8]  ==  8.0);
    assert(m1._data[9]  ==  9.0);
    assert(m1._data[10] == 10.0);
    assert(m1._data[11] == 11.0);

    assert(m1._data[12] == 12.0);
    assert(m1._data[13] == 13.0);
    assert(m1._data[14] == 14.0);
    assert(m1._data[15] == 15.0);

    auto m2 = Mat2x2l( 10, 20,
                       30, 40);

    assert(m2._data[0]  ==  10);
    assert(m2._data[1]  ==  20);
    assert(m2._data[2]  ==  30);
    assert(m2._data[3]  ==  40);
}


// Identity matrix
unittest
{
    auto m1 = Mat2x2i.identity;
    assert(m1[0,0] == 1);
    assert(m1[0,1] == 0);
    assert(m1[1,0] == 0);
    assert(m1[1,1] == 1);

    const m2 = Mat3x3f.identity;
    assert (m2 == Mat3x3f(1.0, 0.0, 0.0,
                          0.0, 1.0, 0.0,
                          0.0, 0.0, 1.0));

    immutable m3 = Mat4x4d.identity;
    assert (m3 == Mat4x4d(1.0, 0.0, 0.0, 0.0,
                          0.0, 1.0, 0.0, 0.0,
                          0.0, 0.0, 1.0, 0.0,
                          0.0, 0.0, 0.0, 1.0));
}


// Matrix indexing
unittest
{
    auto m1 = Mat4x4f( 1.0,  2.0,  3.0,  4.0,
                       5.0,  6.0,  7.0,  8.0,
                       9.0, 10.0, 11.0, 12.0,
                      13.0, 14.0, 15.0, 16.0);

    auto m2 = Mat2x3ui(10, 20, 30,
                       40, 50, 60);

    auto m3 = Mat3x2l(-1, -2,
                      -3, -4,
                      -5, -6);

    // Read matrix elements
    assert(m1[0,0] ==  1.0);
    assert(m1[0,1] ==  2.0);
    assert(m1[0,2] ==  3.0);
    assert(m1[0,3] ==  4.0);
    assert(m1[1,0] ==  5.0);
    assert(m1[1,1] ==  6.0);
    assert(m1[1,2] ==  7.0);
    assert(m1[1,3] ==  8.0);
    assert(m1[2,0] ==  9.0);
    assert(m1[2,1] == 10.0);
    assert(m1[2,2] == 11.0);
    assert(m1[2,3] == 12.0);
    assert(m1[3,0] == 13.0);
    assert(m1[3,1] == 14.0);
    assert(m1[3,2] == 15.0);
    assert(m1[3,3] == 16.0);

    assert(m2[0,0] == 10);
    assert(m2[0,1] == 20);
    assert(m2[0,2] == 30);
    assert(m2[1,0] == 40);
    assert(m2[1,1] == 50);
    assert(m2[1,2] == 60);

    assert(m3[0,0] == -1);
    assert(m3[0,1] == -2);
    assert(m3[1,0] == -3);
    assert(m3[1,1] == -4);
    assert(m3[2,0] == -5);
    assert(m3[2,1] == -6);

    // Write to matrix elements
    m1[1,2] = 77.0;
    assert(m1[0,0] ==  1.0);
    assert(m1[0,1] ==  2.0);
    assert(m1[0,2] ==  3.0);
    assert(m1[0,3] ==  4.0);
    assert(m1[1,0] ==  5.0);
    assert(m1[1,1] ==  6.0);
    assert(m1[1,2] == 77.0);
    assert(m1[1,3] ==  8.0);
    assert(m1[2,0] ==  9.0);
    assert(m1[2,1] == 10.0);
    assert(m1[2,2] == 11.0);
    assert(m1[2,3] == 12.0);
    assert(m1[3,0] == 13.0);
    assert(m1[3,1] == 14.0);
    assert(m1[3,2] == 15.0);
    assert(m1[3,3] == 16.0);

    m1[3,2] = 99.0;
    assert(m1[0,0] ==  1.0);
    assert(m1[0,1] ==  2.0);
    assert(m1[0,2] ==  3.0);
    assert(m1[0,3] ==  4.0);
    assert(m1[1,0] ==  5.0);
    assert(m1[1,1] ==  6.0);
    assert(m1[1,2] == 77.0);
    assert(m1[1,3] ==  8.0);
    assert(m1[2,0] ==  9.0);
    assert(m1[2,1] == 10.0);
    assert(m1[2,2] == 11.0);
    assert(m1[2,3] == 12.0);
    assert(m1[3,0] == 13.0);
    assert(m1[3,1] == 14.0);
    assert(m1[3,2] == 99.0);
    assert(m1[3,3] == 16.0);

    m1[0,0] = -1.0;
    assert(m1[0,0] == -1.0);
    assert(m1[0,1] ==  2.0);
    assert(m1[0,2] ==  3.0);
    assert(m1[0,3] ==  4.0);
    assert(m1[1,0] ==  5.0);
    assert(m1[1,1] ==  6.0);
    assert(m1[1,2] == 77.0);
    assert(m1[1,3] ==  8.0);
    assert(m1[2,0] ==  9.0);
    assert(m1[2,1] == 10.0);
    assert(m1[2,2] == 11.0);
    assert(m1[2,3] == 12.0);
    assert(m1[3,0] == 13.0);
    assert(m1[3,1] == 14.0);
    assert(m1[3,2] == 99.0);
    assert(m1[3,3] == 16.0);

    m2[1,1] = 55;
    assert(m2[0,0] == 10);
    assert(m2[0,1] == 20);
    assert(m2[0,2] == 30);
    assert(m2[1,0] == 40);
    assert(m2[1,1] == 55);
    assert(m2[1,2] == 60);

    m2[0,1] = 22;
    assert(m2[0,0] == 10);
    assert(m2[0,1] == 22);
    assert(m2[0,2] == 30);
    assert(m2[1,0] == 40);
    assert(m2[1,1] == 55);
    assert(m2[1,2] == 60);

    m2[1,0] = 44;
    assert(m2[0,0] == 10);
    assert(m2[0,1] == 22);
    assert(m2[0,2] == 30);
    assert(m2[1,0] == 44);
    assert(m2[1,1] == 55);
    assert(m2[1,2] == 60);

    m3[0,0] = 1;
    assert(m3[0,0] ==  1);
    assert(m3[0,1] == -2);
    assert(m3[1,0] == -3);
    assert(m3[1,1] == -4);
    assert(m3[2,0] == -5);
    assert(m3[2,1] == -6);

    m3[2,1] = 6;
    assert(m3[0,0] ==  1);
    assert(m3[0,1] == -2);
    assert(m3[1,0] == -3);
    assert(m3[1,1] == -4);
    assert(m3[2,0] == -5);
    assert(m3[2,1] ==  6);

    // Now, with const and immutable
    const m4 = Mat2x2ul(11, 22,
                        33, 44);
    assert(m4[0,0] == 11);
    assert(m4[0,1] == 22);
    assert(m4[1,0] == 33);
    assert(m4[1,1] == 44);

    immutable m5 = Mat4x2d(1.0, 2.0,
                           3.0, 4.0,
                           5.0, 6.0,
                           7.0, 8.0);
    assert(m5[0,0] == 1.0);
    assert(m5[0,1] == 2.0);
    assert(m5[1,0] == 3.0);
    assert(m5[1,1] == 4.0);
    assert(m5[2,0] == 5.0);
    assert(m5[2,1] == 6.0);
    assert(m5[3,0] == 7.0);
    assert(m5[3,1] == 8.0);
}


// Matrix.ptr
unittest
{
    auto m1 = Mat4x4f(0.0);
    assert(m1.ptr == &m1._data[0]);

    auto m2 = Mat2x3l(-1);
    assert(m2.ptr == &m2._data[0]);
}


// Matrix equality
unittest
{
    // Matrices of the same type
    const m1 = Mat4x4ul( 1,  2,  3,  4,
                         5,  6,  7,  8,
                         9, 10, 11, 12,
                        13, 14, 15, 16);

    auto m2 = Mat4x4ul( 1,  2,  3,  4,
                        5,  6,  7,  8,
                        9, 10, 11, 12,
                       13, 14, 15, 16);

    assert(m1 == m2);
    m2[2,2] = 111;
    assert(m1 != m2);

    // Matrices of different, but compatible types
    auto m3 = Mat2x3f(1.0, 2.0, 3.0,
                      4.0, 5.0, 6.0);

    immutable m4 = Mat2x3i(1, 2, 3,
                           4, 5, 6);

    assert(m3 == m4);
    m3[0,0] = 1.1;
    assert(m3 != m4);

    // Rvalue matrices
    assert(Mat2x3f(1.1, 2.0, 3.0, 4.0, 5.0, 6.0) == m3);
    assert(m4 == Mat2x3l(1, 2, 3, 4, 5, 6));
}


// Matrix negation and "unary plus"
unittest
{
    auto m1 = Mat4x4f( 0.0,  -1.0,  2.0,  3.0,
                       4.0,   5.0,  6.0,  7.0,
                       8.0,   9.0, 10.0, 11.0,
                       12.0, 13.0, 14.0, 15.0);

    auto mm1 = -m1;
    assert(mm1 == Mat4x4f(  0.0,   1.0,  -2.0,  -3.0,
                           -4.0,  -5.0,  -6.0,  -7.0,
                           -8.0,  -9.0, -10.0, -11.0,
                          -12.0, -13.0, -14.0, -15.0));

    auto pm1 = +m1;
    assert(pm1 == m1);

    auto m2 = Mat2x2i(1, -1,
                      2, -3);

    auto mm2 = -m2;
    assert(mm2 == Mat2x2i(-1, 1,
                          -2, 3));

    auto pm2 = +m2;
    assert(pm2 == m2);
}


// Multiply-assign and divide-assign
unittest
{
    auto m1 = Mat4x4f( 1.0, -2.0,  3.0,  4.0,
                       5.0,  6.0,  7.0,  8.0,
                      -9.0, 10.0, 11.0, 12.0,
                      13.0, 14.0, 15.0, 16.0);

    m1 *= 10;

    assert(m1 == Mat4x4f(  10.0, -20.0,  30.0,  40.0,
                           50.0,  60.0,  70.0,  80.0,
                          -90.0, 100.0, 110.0, 120.0,
                          130.0, 140.0, 150.0, 160.0));

    m1 /= 2.0;

    assert(m1 == Mat4x4f(   5.0, -10.0,  15.0,  20.0,
                           25.0,  30.0,  35.0,  40.0,
                          -45.0,  50.0,  55.0,  60.0,
                           65.0,  70.0,  75.0,  80.0));

    // Now, with another matrix type
    auto m2 = Mat2x4i( 2, -4,  6, -8,
                      10, 12, 14, 16);

    m2 /= -2;

    assert(m2 == Mat2x4i(-1,  2, -3,  4,
                         -5, -6, -7, -8));

    assert((m2 *= -3) == Mat2x4i( 3, -6,  9, -12,
                                 15, 18, 21,  24));
}


// Matrix multiplication and division by scalar
unittest
{
    const m1 = Mat4x4f( 1.0, -2.0,  3.0,  4.0,
                        5.0,  6.0,  7.0,  8.0,
                       -9.0, 10.0, 11.0, 12.0,
                       13.0, 14.0, 15.0, 16.0);

    assert(m1 * 2.0 == Mat4x4f(  2.0, -4.0,  6.0,  8.0,
                                10.0, 12.0, 14.0, 16.0,
                               -18.0, 20.0, 22.0, 24.0,
                                26.0, 28.0, 30.0, 32.0));

    assert(m1 * 3.5 == 3.5 * m1);

    assert(m1 / -1.0 == Mat4x4f( -1.0,   2.0,  -3.0,  -4.0,
                                 -5.0,  -6.0,  -7.0,  -8.0,
                                  9.0, -10.0, -11.0, -12.0,
                                -13.0, -14.0, -15.0, -16.0));

    // 'nuther matrix type
    auto m2 = Mat4x2ui(1, 2,
                       3, 4,
                       5, 6,
                       7, 8);

    auto m3 = m2 * 10;
    assert(m3 == Mat4x2ui(10, 20,
                          30, 40,
                          50, 60,
                          70, 80));

    assert(m2 * 177 == 177 * m2);

    assert(m3 / 5 == Mat4x2ui( 2,  4,
                               6,  8,
                              10, 12,
                              14, 16));

    assert(m2 * 3 * 2 / 6 == m2);
}


// Multiplication of two matrices
unittest
{
    // 3x3 * 3x3
    const m1 = Mat3x3l(1, -5,  3,
                       0, -2,  6,
                       7,  2, -4);

    immutable m2 = Mat3x3i(-8, 6,  1,
                            7, 0, -3,
                            2, 4,  5);

    assert(m1 * m2 == Mat3x3i(-37, 18,  31,
                               -2, 24,  36,
                              -50, 26, -19));

    // 4x4 * 4x4
    auto m3 = Mat2x2f(-3, 0,
                       5, 0.5);

    auto m4 = Mat2x2i(-7, 2,
                       4, 6);

    assert(m3 * m4 == Mat2x2f( 21.0, -6.0,
                              -33.0, 13.0));

    // 3x2 * 2x4
    const m5 = Mat3x2i(6, -4,
                       7, -1,
                       5,  3);

    const m6 = Mat2x4i( 1, 2, -2, 4,
                       -4, 6,  7, 8);

    assert(m5 * m6 == Mat3x4i(22, -12, -40, -8,
                              11,   8, -21, 20,
                              -7,  28,  11, 44));

    // 4x4 * identity
    immutable m7 = Mat4x4d( 8.8, -0.2, 3.3, -1.1,
                            0.5,  0.2, 2.6, -2.5,
                           -0.1,  1.7, 0.4,  1.3,
                            0.0,  0.9, 3.3, -0.8);

    assert(m7 * Mat4x4d.identity == m7);
}


// Vector x Matrix multiplication
unittest
{
    import sbxs.util.test;
    enum epsilon = 1e-6;

    // 3 * 3x3
    const v1 = Vec3i(2, -3, -3);
    const m1 = Mat3x3l(-2, -6, -2,
                        3, -3, -4,
                        1, -1,  1);

    assert(v1 * m1 == Vec3l(-16, 0, 5));

    assert(v1 * Mat3x3i.identity == v1);

    // 4 * 4*4
    auto v2 = Vec4f(-4.3, 4.3, 3.4, 7.7);
    auto m2 = Mat4x4f( 2.3,  4.5, -1.8,  2.0,
                       5.2, -4.4,  5.2, -1.2,
                       7.0, -7.0,  0.0,  1.0,
                      -1.0,  1.6,  1.7,  5.1);
    Vec4f r2 = v2 * m2;
    assertClose(r2.x,  28.57, epsilon);
    assertClose(r2.y, -49.75, epsilon);
    assertClose(r2.z,  43.19, epsilon);
    assertClose(r2.w,  28.91, epsilon);

    assert(v2 * Mat4x4f.identity == v2);

    // 2 * 2x2
    immutable v3 = Vec2i(-1, 2);
    immutable m3 = Mat2x2d(-1.3, 5.3,
                            0.1, 7.2);

    auto r3 = v3 * m3;

    assertClose(r3.x, 1.5, epsilon);
    assertClose(r3.y, 9.1, epsilon);

    assert(r3 * Mat2x2d.identity == r3);
}


// Matrix transposition
unittest
{
    // Using transposed()
    const m1 = Mat4x4f( 1.0,  2.0,  3.0,  4.0,
                        5.0,  6.0,  7.0,  8.0,
                        9.0, 10.0, 11.0, 12.0,
                       13.0, 14.0, 15.0, 16.0);

    Mat4x4f m1t = m1.transposed;

    assert(m1t == Mat4x4f(1.0, 5.0,  9.0, 13.0,
                          2.0, 6.0, 10.0, 14.0,
                          3.0, 7.0, 11.0, 15.0,
                          4.0, 8.0, 12.0, 16.0));

    auto m2 = Mat2x3ul(1, 2, 3,
                       4, 5, 6);

    Mat3x2ul m2t = m2.transposed;

    assert(m2t == Mat3x2ul(1, 4,
                           2, 5,
                           3, 6));

    immutable m3 = Mat4x3l( 1,  2,  3,
                            4,  5,  6,
                            7,  8,  9,
                            10, 11, 12);

    Mat3x4l m3t = transposed(m3);

    assert(m3t == Mat3x4l(1, 4, 7, 10,
                          2, 5, 8, 11,
                          3, 6, 9, 12));

    // Using Matrix.transpose()
    m1t.transpose();
    assert(m1t == m1);

    auto m4 = Mat2x2i(-11, -22,
                      -33, -44);
    m4.transpose();
    assert(m4 == Mat2x2i(-11, -33,
                         -22, -44));

    auto m5 = Mat3x3ui(111, 222, 333,
                       444, 555, 666,
                       777, 888, 999);
    m5.transpose();
    assert(m5 == Mat3x3ui(111, 444, 777,
                          222, 555, 888,
                          333, 666, 999));
}


/// Matrix diagonal
unittest
{
    const m1 = Mat4x4f( 1.0,  2.0,  3.0,  4.0,
                        5.0,  6.0,  7.0,  8.0,
                        9.0, 10.0, 11.0, 12.0,
                       13.0, 14.0, 15.0, 16.0);
    Vec4f d1 = m1.diagonal;

    assert(d1[0] ==  1.0);
    assert(d1[1] ==  6.0);
    assert(d1[2] == 11.0);
    assert(d1[3] == 16.0);

    auto m2 = Mat2x2i(11, 22,
                      33, 44);
    assert(diagonal(m2) == Vec2i(11, 44));
}


// 2D rotation matrix
unittest
{
    import std.math;
    import sbxs.util.test;
    enum epsilon = 1e-6;

    auto r1 = Mat2x2d.rotation(PI/3.0);

    immutable v1ao = Vec2d(1.0, 0.0);
    auto v1a = v1ao * r1;
    assertClose(v1a.x, 0.5, epsilon);
    assertClose(v1a.y, 0.866025, epsilon);
    assertClose(v1ao.length, v1a.length, epsilon);

    auto v1bo = Vec2d(0.3, -5.5);
    auto v1b = v1bo * r1;
    assertClose(v1b.x, 4.91314, epsilon);
    assertClose(v1b.y, -2.49019, epsilon);
    assertClose(v1bo.length, v1b.length, epsilon);

    const r2 = Mat2x2f.rotation(-PI/6.0);

    const v2ao = Vec2f(1.0, 0.0);
    auto v2a = v2ao * r2;
    assertClose(v2a.x, 0.866025, epsilon);
    assertClose(v2a.y, -0.5, epsilon);
    assertClose(v2ao.length, v2a.length, epsilon);

    const v2bo = Vec2r(-6.5, -4.5);
    auto v2b = v2bo * r2;
    assertClose(v2b.x, -7.87917, epsilon);
    assertClose(v2b.y, -0.647114, epsilon);
    assertClose(v2bo.length, v2b.length, epsilon);
}


// 3x3 rotation matrices around coordinate axes
unittest
{
    import std.math;
    import sbxs.util.test;
    enum epsilon = 1e-6;

    // This is testing basically the same rotation for each axis. More diverse
    // tests would be better.

    // x-axis
    auto r1 = Mat3x3f.rotationX(PI/3.0);

    immutable v1ao = Vec3f(0.1, 0.0, 1.0);
    auto v1a = v1ao * r1;
    assertClose(v1a.x, 0.1, epsilon);
    assertClose(v1a.y, -0.866025, epsilon);
    assertClose(v1a.z, 0.5, epsilon);

    assertClose(v1ao.length, v1a.length, epsilon);

    // y-axis
    auto r2 = Mat3x3r.rotationY(PI/3.0);

    immutable v2ao = Vec3r(0.0, 0.2, 1.0);
    auto v2a = v2ao * r2;
    assertClose(v2a.x, 0.866025, epsilon);
    assertClose(v2a.y, 0.2, epsilon);
    assertClose(v2a.z, 0.5, epsilon);

    assertClose(v2ao.length, v2a.length, epsilon);

    // z-axis
    auto r3 = Mat3x3d.rotationZ(PI/3.0);

    immutable v3ao = Vec3d(1.0, 0.0, -0.1);
    auto v3a = v3ao * r3;
    assertClose(v3a.x,  0.5, epsilon);
    assertClose(v3a.y,  0.866025, epsilon);
    assertClose(v3a.z, -0.1, epsilon);

    assertClose(v3ao.length, v3a.length, epsilon);
}


// 3x3 rotation matrices around arbitrary axis
unittest
{
    import std.math;
    import sbxs.util.test;
    enum epsilon = 1e-5;

    // Case 1
    const axis1 = Vec3f(4.5, 3.4, -0.9).normalized;
    const r1 = Mat3x3f.rotation(axis1, 1.883);
    const v1 = Vec3f(2.3, -0.4, 0.8) * r1;

    assertClose(v1.x,  1.17806, epsilon);
    assertClose(v1.y,  0.304852, epsilon);
    assertClose(v1.z, -2.14691, epsilon);

    // Case 2
    auto axis2 = Vec3f(-2.2, -1.6, 0.8).normalized;
    auto r2 = Mat3x3d.rotation(axis2, 4.56);
    auto v2 = Vec3f(0.3, -0.1, 0.4) * r2;

    assertClose(v2.x,  0.206399, epsilon);
    assertClose(v2.y, -0.333978, epsilon);
    assertClose(v2.z, -0.325359, epsilon);
}


// Compare 3x3 rotation matrices around coordinate and arbitrary axes
unittest
{
    import std.math;
    import sbxs.util.test;
    enum epsilon = 1e-7;

    // x-axis
    const theta1 = 2.654;
    auto rx1 = Mat3x3f.rotationX(theta1);
    auto rx2 = Mat3x3f.rotation(Vec3f(1.0, 0.0, 0.0), theta1);

    assertClose(rx1[0,0], rx2[0,0], epsilon);
    assertClose(rx1[0,1], rx2[0,1], epsilon);
    assertClose(rx1[0,2], rx2[0,2], epsilon);
    assertClose(rx1[1,0], rx2[1,0], epsilon);
    assertClose(rx1[1,1], rx2[1,1], epsilon);
    assertClose(rx1[1,2], rx2[1,2], epsilon);
    assertClose(rx1[2,0], rx2[2,0], epsilon);
    assertClose(rx1[2,1], rx2[2,1], epsilon);
    assertClose(rx1[2,2], rx2[2,2], epsilon);

    // y-axis
    const theta2 = -0.582;
    auto ry1 = Mat3x3d.rotationY(theta2);
    auto ry2 = Mat3x3d.rotation(Vec3r(0.0, 1.0, 0.0), theta2);

    assertClose(ry1[0,0], ry2[0,0], epsilon);
    assertClose(ry1[0,1], ry2[0,1], epsilon);
    assertClose(ry1[0,2], ry2[0,2], epsilon);
    assertClose(ry1[1,0], ry2[1,0], epsilon);
    assertClose(ry1[1,1], ry2[1,1], epsilon);
    assertClose(ry1[1,2], ry2[1,2], epsilon);
    assertClose(ry1[2,0], ry2[2,0], epsilon);
    assertClose(ry1[2,1], ry2[2,1], epsilon);
    assertClose(ry1[2,2], ry2[2,2], epsilon);

    // z-axis
    const theta3 = 7.916;
    const rz1 = Mat3x3r.rotationZ(theta3);
    const rz2 = Mat3x3r.rotation(Vec3f(0.0, 0.0, 1.0), theta3);

    assertClose(rz1[0,0], rz2[0,0], epsilon);
    assertClose(rz1[0,1], rz2[0,1], epsilon);
    assertClose(rz1[0,2], rz2[0,2], epsilon);
    assertClose(rz1[1,0], rz2[1,0], epsilon);
    assertClose(rz1[1,1], rz2[1,1], epsilon);
    assertClose(rz1[1,2], rz2[1,2], epsilon);
    assertClose(rz1[2,0], rz2[2,0], epsilon);
    assertClose(rz1[2,1], rz2[2,1], epsilon);
    assertClose(rz1[2,2], rz2[2,2], epsilon);
}


// 4x4 rotation matrices around coordinate axes
unittest
{
    import std.math;
    import sbxs.util.test;
    enum epsilon = 1e-6;

    // This is testing basically the same rotation for each axis. More diverse
    // tests would be better.

    // x-axis
    auto r1 = Mat4x4f.rotationX(PI/3.0);

    immutable v1ao = Vec4f(0.1, 0.0, 1.0, 1.0);
    auto v1a = v1ao * r1;
    assertClose(v1a.x, 0.1, epsilon);
    assertClose(v1a.y, -0.866025, epsilon);
    assertClose(v1a.z, 0.5, epsilon);
    assertClose(v1a.w, 1.0, epsilon);

    assertClose(v1ao.length, v1a.length, epsilon);

    // y-axis
    auto r2 = Mat4x4r.rotationY(PI/3.0);

    immutable v2ao = Vec4r(0.0, 0.2, 1.0, 1.0);
    auto v2a = v2ao * r2;
    assertClose(v2a.x, 0.866025, epsilon);
    assertClose(v2a.y, 0.2, epsilon);
    assertClose(v2a.z, 0.5, epsilon);
    assertClose(v2a.w, 1.0, epsilon);

    assertClose(v2ao.length, v2a.length, epsilon);

    // z-axis
    auto r3 = Mat4x4d.rotationZ(PI/3.0);

    immutable v3ao = Vec4d(1.0, 0.0, -0.1, 1.0);
    auto v3a = v3ao * r3;
    assertClose(v3a.x,  0.5, epsilon);
    assertClose(v3a.y,  0.866025, epsilon);
    assertClose(v3a.z, -0.1, epsilon);
    assertClose(v3a.w,  1.0, epsilon);

    assertClose(v3ao.length, v3a.length, epsilon);
}


// 4x4 rotation matrices around arbitrary axis
unittest
{
    import std.math;
    import sbxs.util.test;
    enum epsilon = 1e-5;

    // Case 1
    const axis1 = Vec3f(4.5, 3.4, -0.9).normalized;
    const r1 = Mat4x4f.rotation(axis1, 1.883);
    const v1 = Vec4f(2.3, -0.4, 0.8, 1.0) * r1;

    assertClose(v1.x,  1.17806, epsilon);
    assertClose(v1.y,  0.304852, epsilon);
    assertClose(v1.z, -2.14691, epsilon);
    assertClose(v1.w,  1.0, epsilon);

    // Case 2
    auto axis2 = Vec3f(-2.2, -1.6, 0.8).normalized;
    auto r2 = Mat4x4d.rotation(axis2, 4.56);
    auto v2 = Vec4f(0.3, -0.1, 0.4, 1.0) * r2;

    assertClose(v2.x,  0.206399, epsilon);
    assertClose(v2.y, -0.333978, epsilon);
    assertClose(v2.z, -0.325359, epsilon);
    assertClose(v2.w,  1.0, epsilon);
}


// Compare 4x4 rotation matrices around coordinate and arbitrary axes
unittest
{
    import std.math;
    import sbxs.util.test;
    enum epsilon = 1e-7;

    // x-axis
    const theta1 = 2.654;
    auto rx1 = Mat4x4f.rotationX(theta1);
    auto rx2 = Mat4x4f.rotation(Vec3f(1.0, 0.0, 0.0), theta1);

    assertClose(rx1[0,0], rx2[0,0], epsilon);
    assertClose(rx1[0,1], rx2[0,1], epsilon);
    assertClose(rx1[0,2], rx2[0,2], epsilon);
    assertClose(rx1[1,0], rx2[1,0], epsilon);
    assertClose(rx1[1,1], rx2[1,1], epsilon);
    assertClose(rx1[1,2], rx2[1,2], epsilon);
    assertClose(rx1[2,0], rx2[2,0], epsilon);
    assertClose(rx1[2,1], rx2[2,1], epsilon);
    assertClose(rx1[2,2], rx2[2,2], epsilon);

    // y-axis
    const theta2 = -0.582;
    auto ry1 = Mat4x4d.rotationY(theta2);
    auto ry2 = Mat4x4d.rotation(Vec3r(0.0, 1.0, 0.0), theta2);

    assertClose(ry1[0,0], ry2[0,0], epsilon);
    assertClose(ry1[0,1], ry2[0,1], epsilon);
    assertClose(ry1[0,2], ry2[0,2], epsilon);
    assertClose(ry1[1,0], ry2[1,0], epsilon);
    assertClose(ry1[1,1], ry2[1,1], epsilon);
    assertClose(ry1[1,2], ry2[1,2], epsilon);
    assertClose(ry1[2,0], ry2[2,0], epsilon);
    assertClose(ry1[2,1], ry2[2,1], epsilon);
    assertClose(ry1[2,2], ry2[2,2], epsilon);

    // z-axis
    const theta3 = 7.916;
    const rz1 = Mat4x4r.rotationZ(theta3);
    const rz2 = Mat4x4r.rotation(Vec3f(0.0, 0.0, 1.0), theta3);

    assertClose(rz1[0,0], rz2[0,0], epsilon);
    assertClose(rz1[0,1], rz2[0,1], epsilon);
    assertClose(rz1[0,2], rz2[0,2], epsilon);
    assertClose(rz1[1,0], rz2[1,0], epsilon);
    assertClose(rz1[1,1], rz2[1,1], epsilon);
    assertClose(rz1[1,2], rz2[1,2], epsilon);
    assertClose(rz1[2,0], rz2[2,0], epsilon);
    assertClose(rz1[2,1], rz2[2,1], epsilon);
    assertClose(rz1[2,2], rz2[2,2], epsilon);
}


/// 2D scaling along coordinate axes
unittest
{
    import sbxs.util.test;
    enum epsilon = 1e-7;

    auto s1 = Mat2x2f.scaling(3, 1.5);
    const v1 = Vec2f(1.0, 2.0) * s1;
    assertClose(v1.x, 3.0, epsilon);
    assertClose(v1.y, 3.0, epsilon);

    immutable s2 = Mat2x2d.scaling(-0.5, -0.5);
    immutable v2 = Vec2d(10.0, 10.0) * s2;
    assertClose(v2.x, -5.0, epsilon);
    assertClose(v2.y, -5.0, epsilon);

    const s3 = Mat2x2r.scaling(v1);
    const v3 = v2 * s3;
    assertClose(v3.x, -15.0, epsilon);
    assertClose(v3.y, -15.0, epsilon);
}

/// 2D scaling along arbitrary axes
unittest
{
    import sbxs.util.test;
    enum epsilon = 1e-5;

    auto axis1 = Vec2d(0.4, 1.2).normalized;
    auto s1 = Mat2x2f.scaling(axis1, 1.234);
    const v1 = Vec2f(3.2, -0.4) * s1;
    assertClose(v1.x,  3.2468, epsilon);
    assertClose(v1.y, -0.2596, epsilon);

    const axis2 = Vec2d(-1.1, 1.3).normalized;
    immutable s2 = Mat2x2d.scaling(axis2, -4.23);
    immutable v2 = Vec2d(0.1, 1.1) * s2;
    assertClose(v2.x,  2.71861, epsilon);
    assertClose(v2.y, -1.99472, epsilon);
}


/// 3x3 3D scaling matrices along coordinate axes
unittest
{
    import sbxs.util.test;
    enum epsilon = 1e-7;

    auto s1 = Mat3x3f.scaling(3, 1.5, 0.0);
    const v1 = Vec3f(1.0, 2.0, 3.0) * s1;
    assertClose(v1.x, 3.0, epsilon);
    assertClose(v1.y, 3.0, epsilon);
    assertClose(v1.z, 0.0, epsilon);

    immutable s2 = Mat3x3d.scaling(-0.5, -0.5, 2);
    immutable v2 = Vec3d(10.0, 10.0, 8.0) * s2;
    assertClose(v2.x, -5.0, epsilon);
    assertClose(v2.y, -5.0, epsilon);
    assertClose(v2.z, 16.0, epsilon);

    const s3 = Mat3x3r.scaling(v1);
    const v3 = v2 * s3;
    assertClose(v3.x, -15.0, epsilon);
    assertClose(v3.y, -15.0, epsilon);
    assertClose(v3.z,   0.0, epsilon);
}


/// 3x3 3D scaling matrices along arbitrary axes
unittest
{
    import sbxs.util.test;
    enum epsilon = 1e-5;

    auto axis1 = Vec3d(0.4, 1.2, 3.3).normalized;
    auto s1 = Mat3x3f.scaling(axis1, 5.5);
    const v1 = Vec3f(3.2, -0.4, 2.2) * s1;
    assertClose(v1.x, 4.36157, epsilon);
    assertClose(v1.y, 3.08471, epsilon);
    assertClose(v1.z, 11.7829, epsilon);

    const axis2 = Vec3d(-1.1, 1.3, 0.1).normalized;
    immutable s2 = Mat3x3d.scaling(axis2, -2.22);
    immutable v2 = Vec3d(0.1, 1.1, -0.1) * s2;
    assertClose(v2.x,  1.69451, epsilon);
    assertClose(v2.y, -0.784419, epsilon);
    assertClose(v2.z, -0.244955, epsilon);
}


/// 4x4 3D scaling matrices along coordinate axes
unittest
{
    import sbxs.util.test;
    enum epsilon = 1e-7;

    auto s1 = Mat4x4f.scaling(3, 1.5, 0.0);
    const v1 = Vec4f(1.0, 2.0, 3.0, 1.0) * s1;
    assertClose(v1.x, 3.0, epsilon);
    assertClose(v1.y, 3.0, epsilon);
    assertClose(v1.z, 0.0, epsilon);
    assertClose(v1.w, 1.0, epsilon);

    immutable s2 = Mat4x4d.scaling(-0.5, -0.5, 2);
    immutable v2 = Vec4d(10.0, 10.0, 8.0, 1.0) * s2;
    assertClose(v2.x, -5.0, epsilon);
    assertClose(v2.y, -5.0, epsilon);
    assertClose(v2.z, 16.0, epsilon);
    assertClose(v2.w,  1.0, epsilon);

    const s3 = Mat4x4r.scaling(v1.xyz);
    const v3 = v2 * s3;
    assertClose(v3.x, -15.0, epsilon);
    assertClose(v3.y, -15.0, epsilon);
    assertClose(v3.z,   0.0, epsilon);
    assertClose(v3.w,   1.0, epsilon);
}


/// 4x4 3D scaling matrices along arbitrary axes
unittest
{
    import sbxs.util.test;
    enum epsilon = 1e-5;

    auto axis1 = Vec3d(0.4, 1.2, 3.3).normalized;
    auto s1 = Mat4x4f.scaling(axis1, 5.5);
    const v1 = Vec4f(3.2, -0.4, 2.2, 1.0) * s1;
    assertClose(v1.x, 4.36157, epsilon);
    assertClose(v1.y, 3.08471, epsilon);
    assertClose(v1.z, 11.7829, epsilon);
    assertClose(v1.w, 1.0, epsilon);

    const axis2 = Vec3d(-1.1, 1.3, 0.1).normalized;
    immutable s2 = Mat4x4d.scaling(axis2, -2.22);
    immutable v2 = Vec4d(0.1, 1.1, -0.1, 1.0) * s2;
    assertClose(v2.x,  1.69451, epsilon);
    assertClose(v2.y, -0.784419, epsilon);
    assertClose(v2.z, -0.244955, epsilon);
    assertClose(v2.w,  1.0, epsilon);
}


// 2D orthographic projection onto coordinate axes
unittest
{
    auto o1 = Mat2x2i.orthoProjX;
    auto p1 = Vec2i(3, 5) * o1;
    assert(p1.x == 3);
    assert(p1.y == 0);

    auto o2 = Mat2x2f.orthoProjY;
    auto p2 = Vec2f(-1.2, 4.0) * o2;
    assert(p2.x == 0.0);
    assert(p2.y == 4.0);
}


// 2D orthographic projection onto arbitrary axis
unittest
{
    import sbxs.util.test;
    enum epsilon = 1e-6;

    auto o1 = Mat2x2f.orthoProj(Vec2f(-0.6, 1.7).normalized);
    auto p1 = Vec2f(3.2, -0.4) * o1;
    assertClose(p1.x, 2.72, epsilon);
    assertClose(p1.y, 0.96, epsilon);
}


// 3x3 matrices for performing 3D orthographic projection onto coordinate planes
unittest
{
    import sbxs.util.test;
    enum epsilon = 1e-7;

    auto o1 = Mat3x3l.orthoProjXY;
    auto p1 = Vec3l(3, 5, -8) * o1;
    assert(p1.x == 3);
    assert(p1.y == 5);
    assert(p1.z == 0);

    auto o2 = Mat3x3f.orthoProjXZ;
    auto p2 = Vec3f(-1.2, 4.0, 0.1) * o2;
    assertClose(p2.x, -1.2, epsilon);
    assert(p2.y ==  0.0);
    assertClose(p2.z, 0.1, epsilon);

    auto o3 = Mat3x3d.orthoProjYZ;
    auto p3 = Vec3d(-1.2, 4.0, 0.1) * o3;
    assert(p3.x == 0.0);
    assertClose(p3.y, 4.0, epsilon);
    assertClose(p3.z, 0.1, epsilon);
}


// 3x3 matrix for performing 3D orthographic projection onto arbitrary plane
unittest
{
    import sbxs.util.test;
    enum epsilon = 1e-5;

    auto o1 = Mat3x3d.orthoProj(Vec3d(-0.6, 1.7, 0.8).normalized);
    auto p1 = Vec3d(3.2, -0.4, 1.1) * o1;
    assertClose(p1.x, 2.9347, epsilon);
    assertClose(p1.y, 0.351671, epsilon);
    assertClose(p1.z, 1.45373, epsilon);
}


// 4x4 matrices for performing 3D orthographic projection onto coordinate planes
unittest
{
    import sbxs.util.test;
    enum epsilon = 1e-7;

    auto o1 = Mat4x4l.orthoProjXY;
    auto p1 = Vec4l(3, 5, -8, 1) * o1;
    assert(p1.x == 3);
    assert(p1.y == 5);
    assert(p1.z == 0);
    assert(p1.w == 1);

    auto o2 = Mat4x4f.orthoProjXZ;
    auto p2 = Vec4f(-1.2, 4.0, 0.1, 1.0) * o2;
    assertClose(p2.x, -1.2, epsilon);
    assert(p2.y ==  0.0);
    assertClose(p2.z, 0.1, epsilon);
    assertClose(p2.w, 1.0, epsilon);

    auto o3 = Mat4x4d.orthoProjYZ;
    auto p3 = Vec4d(-1.2, 4.0, 0.1, 1.0) * o3;
    assert(p3.x == 0.0);
    assertClose(p3.y, 4.0, epsilon);
    assertClose(p3.z, 0.1, epsilon);
    assertClose(p3.w, 1.0, epsilon);
}


// 4x4 matrix for performing 3D orthographic projection onto arbitrary plane
unittest
{
    import sbxs.util.test;
    enum epsilon = 1e-5;

    auto o1 = Mat4x4d.orthoProj(Vec3d(-0.6, 1.7, 0.8).normalized);
    auto p1 = Vec4d(3.2, -0.4, 1.1, 1.0) * o1;
    assertClose(p1.x, 2.9347, epsilon);
    assertClose(p1.y, 0.351671, epsilon);
    assertClose(p1.z, 1.45373, epsilon);
    assertClose(p1.w, 1.0, epsilon);
}


// 2D shearing
unittest
{
    import sbxs.util.test;
    enum epsilon = 1e-7;

    auto s1 = Mat2x2f.shearingX(0.8);
    auto v1 = Vec2d(1.3, -3.2) * s1;
    assertClose(v1.x, -1.26, epsilon);
    assertClose(v1.y, -3.2, epsilon);

    auto s2 = Mat2x2f.shearingY(-0.7);
    auto v2 = Vec2d(1.3, -3.2) * s2;
    assertClose(v2.x,  1.3, epsilon);
    assertClose(v2.y, -4.11, epsilon);
}


// 3x3 matrices for 3D shearing
unittest
{
    import sbxs.util.test;
    enum epsilon = 1e-7;

    auto s1 = Mat3x3f.shearingXY(0.8, -0.8);
    auto v1 = Vec3d(1.3, -3.2, 2.1) * s1;
    assertClose(v1.x,  2.98 , epsilon);
    assertClose(v1.y, -4.88, epsilon);
    assertClose(v1.z,  2.1, epsilon);

    auto s2 = Mat3x3f.shearingXZ(0.7, -0.9);
    auto v2 = Vec3r(1.3, -3.2, 2.1) * s2;
    assertClose(v2.x, -0.94, epsilon);
    assertClose(v2.y, -3.2, epsilon);
    assertClose(v2.z,  4.98, epsilon);

    auto s3 = Mat3x3f.shearingYZ(0.2, 0.4);
    auto v3 = Vec3f(1.3, -3.2, 2.1) * s3;
    assertClose(v3.x,  1.3, epsilon);
    assertClose(v3.y, -2.94, epsilon);
    assertClose(v3.z,  2.62, epsilon);
}


// 4x4 matrices for 3D shearing
unittest
{
    import sbxs.util.test;
    enum epsilon = 1e-7;

    auto s1 = Mat4x4f.shearingXY(0.8, -0.8);
    auto v1 = Vec4d(1.3, -3.2, 2.1, 1.0) * s1;
    assertClose(v1.x,  2.98, epsilon);
    assertClose(v1.y, -4.88, epsilon);
    assertClose(v1.z,  2.1, epsilon);
    assertClose(v1.w,  1.0, epsilon);

    auto s2 = Mat4x4f.shearingXZ(0.7, -0.9);
    auto v2 = Vec4r(1.3, -3.2, 2.1, 1.0) * s2;
    assertClose(v2.x, -0.94, epsilon);
    assertClose(v2.y, -3.2, epsilon);
    assertClose(v2.z,  4.98, epsilon);
    assertClose(v2.w,  1.0, epsilon);

    auto s3 = Mat4x4f.shearingYZ(0.2, 0.4);
    auto v3 = Vec4f(1.3, -3.2, 2.1, 1.0) * s3;
    assertClose(v3.x,  1.3, epsilon);
    assertClose(v3.y, -2.94, epsilon);
    assertClose(v3.z,  2.62, epsilon);
    assertClose(v3.w,  1.0, epsilon);
}


// 4x4 matrices for 3D translation
unittest
{
    import sbxs.util.test;
    enum epsilon = 1e-7;

    auto t1 = Mat4x4f.translation(3.2, 0.0, -0.9);
    auto v1 = Vec4d(1.3, -3.2, 2.1, 1.0) * t1;
    assertClose(v1.x,  4.5 , epsilon);
    assertClose(v1.y, -3.2, epsilon);
    assertClose(v1.z,  1.2, epsilon);
    assertClose(v1.w,  1.0, epsilon);

    const t2 = Mat4x4d.translation(Vec3f(-1.2, 0.5, 0.3));
    const v2 = Vec4d(5.3, -5.7, 0.1, 1.0) * t2;
    assertClose(v2.x,  4.1, epsilon);
    assertClose(v2.y, -5.2, epsilon);
    assertClose(v2.z,  0.4, epsilon);
    assertClose(v2.w,  1.0, epsilon);
}


// Matrix determinants
unittest
{
    import sbxs.util.test;
    enum epsilon = 1e-7;

    // 2x2
    immutable m1 = Mat2x2i(-3, 4,
                            2, 5);

    assert(m1.determinant == -23);

    // 3x3
    const m2 = Mat3x3f( 1.2,  3.1, -0.4,
                        2.5, -1.1,  1.1,
                       -0.2,  0.4,  5.6);

    assertClose(m2.determinant, -52.314, epsilon);

    // 4x4
    auto m3 = Mat4x4d( 1.2,  3.1, -0.4,  3.3,
                       2.5, -1.1,  1.1, -3.3,
                      -0.2,  0.4,  5.6,  1.2,
                       1.0,  0.1,  0.3,  0.4);

    assertClose(m3.determinant, -51.9594, epsilon);
}


// Equivalence of determinant of 3x3 matrix and triple product
unittest
{
    import sbxs.util.test;
    enum epsilon = 1e-6;

    const v1 = Vec3f(1.1, 2.1, 0.5);
    const v2 = Vec3f(2.5, 6.1, 1.4);
    const v3 = Vec3f(4.1, 2.1, 3.3);

    auto m = Mat3x3f(v1.x, v1.y, v1.z,
                     v2.x, v2.y, v2.z,
                     v3.x, v3.y, v3.z);

    assertClose(determinant(m), dot(cross(v1, v2), v3), epsilon);
}


// Determinants of transform matrices
unittest
{
    import sbxs.util.test;
    enum epsilon = 1e-7;

    // Determinant of rotation matrices is 1
    assertClose(Mat2x2f.rotation(1.234).determinant, 1.0, epsilon);
    assertClose(Mat2x2r.rotation(-5.432).determinant, 1.0, epsilon);
    assertClose(Mat3x3d.rotationX(0.123).determinant, 1.0, epsilon);
    assertClose(Mat3x3f.rotationY(0.456).determinant, 1.0, epsilon);
    assertClose(Mat3x3f.rotationZ(9.318).determinant, 1.0, epsilon);
    assertClose(
        Mat3x3d.rotation(Vec3d(-0.1, 4.3, -1.3).normalized, 7.65).determinant,
        1.0,
        epsilon);

    // For uniform 2D scaling matrices, determinant is the scale factor squared
    assertClose(Mat2x2f.scaling(2.2, 2.2).determinant, 2.2*2.2, epsilon);
    assertClose(Mat2x2d.scaling(-4.1, -4.1).determinant, 4.1*4.1, epsilon);

    // For uniform 3D scaling matrices, determinant is the scale factor cubed
    assertClose(
        Mat3x3f.scaling(2.3, 2.3, 2.3).determinant,
        2.3 * 2.3 * 2.3,
        epsilon);

    assertClose(
        Mat3x3r.scaling(-6.6, -6.6, -6.6).determinant,
        -6.6 * -6.6 * -6.6,
        epsilon);

    // For orthographic projection matrices, determinant is zero
    assertClose(Mat2x2r.orthoProjX.determinant, 0.0, epsilon);
    assertClose(Mat2x2f.orthoProjY.determinant, 0.0, epsilon);
    assertClose(
        Mat2x2f.orthoProj(Vec2d(3,6).normalized).determinant,
        0.0,
        epsilon);
    assertClose(Mat3x3d.orthoProjXY.determinant, 0.0, epsilon);
    assertClose(Mat3x3f.orthoProjXZ.determinant, 0.0, epsilon);
    assertClose(Mat3x3f.orthoProjYZ.determinant, 0.0, epsilon);
    assertClose(
        Mat3x3f.orthoProj(Vec3d(3,6,-3).normalized).determinant,
        0.0,
        epsilon);

    // For shearing matrices, determinant is one
    assertClose(Mat2x2r.shearingX(-0.5).determinant, 1.0, epsilon);
    assertClose(Mat2x2f.shearingY(0.8).determinant, 1.0, epsilon);
    assertClose(Mat3x3f.shearingXY(-0.2, 0.4).determinant, 1.0, epsilon);
    assertClose(Mat3x3d.shearingXZ(0.1, 0.0).determinant, 1.0, epsilon);
    assertClose(Mat3x3d.shearingYZ(0.0, 2.1).determinant, 1.0, epsilon);
}


// Matrix inverse
unittest
{
    import sbxs.util.test;
    enum epsilon = 1e-5;

    // 2x2
    const m1 = Mat2x2f( 2.1, -3.3,
                       -1.8,  5.0);
    const im1 = m1.inverse;

    assertClose(im1[0,0], 1.09649, epsilon);
    assertClose(im1[0,1], 0.723684, epsilon);
    assertClose(im1[1,0], 0.394737, epsilon);
    assertClose(im1[1,1], 0.460526, epsilon);

    assert(m1.inverse(m1.determinant) == im1);

    // 3x3
    auto m2 = Mat3x3d( 2.1, -3.3, -1.3,
                      -1.8,  5.0,  3.4,
                       1.1,  2.2, -2.2);

    immutable im2 = m2.inverse;

    assertClose(im2[0,0],  0.716724, epsilon);
    assertClose(im2[0,1],  0.392491, epsilon);
    assertClose(im2[0,2],  0.183059, epsilon);

    assertClose(im2[1,0],  0.00853242, epsilon);
    assertClose(im2[1,1],  0.12372, epsilon);
    assertClose(im2[1,2],  0.186162, epsilon);

    assertClose(im2[2,0],  0.366894, epsilon);
    assertClose(im2[2,1],  0.319966, epsilon);
    assertClose(im2[2,2], -0.176854, epsilon);

    assert(m2.inverse(m2.determinant) == im2);

    // 4x4
    auto m3 = Mat4x4r( 2.1, -3.3, -1.3,  3.2,
                      -1.8,  5.0,  3.4, -1.1,
                       1.1,  2.2, -2.2,  3.9,
                      -1.0,  1.0,  4.3, -2.5);

    immutable im3 = m3.inverse;

    assertClose(im3[0,0], -1.29949, epsilon);
    assertClose(im3[0,1], -2.17477, epsilon);
    assertClose(im3[0,2],  1.93936, epsilon);
    assertClose(im3[0,3],  2.31894, epsilon);

    assertClose(im3[1,0], -0.474634, epsilon);
    assertClose(im3[1,1], -0.491499, epsilon);
    assertClose(im3[1,2],  0.607041, epsilon);
    assertClose(im3[1,3],  0.555713, epsilon);

    assertClose(im3[2,0],  0.263278, epsilon);
    assertClose(im3[2,1],  0.188031, epsilon);
    assertClose(im3[2,2], -0.0865955, epsilon);
    assertClose(im3[2,3],  0.119174, epsilon);

    assertClose(im3[3,0],  0.782781, epsilon);
    assertClose(im3[3,1],  0.996721, epsilon);
    assertClose(im3[3,2], -0.68187, epsilon);
    assertClose(im3[3,3], -0.900314, epsilon);

    assert(m3.inverse(m3.determinant) == im3);
}


// Matrix orthonormalization
unittest
{
    import std.math;
    import sbxs.util.test;
    enum epsilon = 1e-5;

    // 2D
    auto m2d = Mat2x2r(2.3, -1.3,
                       0.6,  1.1);

    orthonormalize(m2d);

    assertClose(m2d[0,0],  0.870563, epsilon);
    assertClose(m2d[0,1], -0.492057, epsilon);
    assertClose(m2d[1,0],  0.492057, epsilon);
    assertClose(m2d[1,1],  0.870563, epsilon);

    // 3D
    auto m3d = Mat3x3d(-1.9, -1.0,  0.4,
                       -0.2,  0.8,  1.0,
                       -0.8,  1.1, -1.1);

    orthonormalize(m3d);

    assertClose(m3d[0,0], -0.869950, epsilon);
    assertClose(m3d[0,1], -0.457869, epsilon);
    assertClose(m3d[0,2],  0.183147, epsilon);

    assertClose(m3d[1,0], -0.160454, epsilon);
    assertClose(m3d[1,1],  0.613994, epsilon);
    assertClose(m3d[1,2],  0.772830, epsilon);

    assertClose(m3d[2,0], -0.466306, epsilon);
    assertClose(m3d[2,1],  0.642937, epsilon);
    assertClose(m3d[2,2], -0.607611, epsilon);

    // 4D
    auto m4d = Mat4x4f( 0.5, 0.0, 2.2, -0.3,
                        0.0, 0.3, 0.0,  0.0,
                        0.2, 0.0, 0.1,  0.8,
                       -1.6, 0.0, 0.4,  0.4);

    orthonormalize(m4d);

    assertClose(m4d[0,0],  0.219687, epsilon);
    assertClose(m4d[0,1],  0.000000, epsilon);
    assertClose(m4d[0,2],  0.966625, epsilon);
    assertClose(m4d[0,3], -0.131812, epsilon);

    assertClose(m4d[1,0],  0.000000, epsilon);
    assertClose(m4d[1,1],  1.000000, epsilon);
    assertClose(m4d[1,2],  0.000000, epsilon);
    assertClose(m4d[1,3],  0.000000, epsilon);

    assertClose(m4d[2,0],  0.2316830, epsilon);
    assertClose(m4d[2,1],  0.0000000, epsilon);
    assertClose(m4d[2,2],  0.0795538, epsilon);
    assertClose(m4d[2,3],  0.9695330, epsilon);

    assertClose(m4d[3,0], -0.947661, epsilon);
    assertClose(m4d[3,1],  0.000000, epsilon);
    assertClose(m4d[3,2],  0.243533, epsilon);
    assertClose(m4d[3,3],  0.206474, epsilon);
}
