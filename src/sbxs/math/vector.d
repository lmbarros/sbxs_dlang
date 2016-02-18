/**
 * Vectors in 2D, 3D and 4D.
 *
 * License: MIT License, see the `LICENSE` file.
 *
 * Authors: Leandro Motta Barros (though everything here, to some extent, is
 *     derived from public domain code from
 *     $(LINK2 https://github.com/d-gamedev-team/gfm, GFM)).
 */

module sbxs.math.vector;

import std.traits;

version(unittest)
{
    import sbxs.util.test;
}


/**
 * Vector template structure, for vectors of 2, 3 or 4 dimensions.
 *
 * Why limiting to these dimensions only? Because these are the ones that
 * interest me right now, and because then I can do one or two tricks here and
 * there, like manually unrolling loops.
 *
 * Parameters:
 *     T = The type of the vector elements.
 *     N = The number of dimensions; must be between 2 and 4, inclusive.
 */
public struct Vector(T, size_t N)
   if (N >= 2 && N <= 4)
{
    // -------------------------------------------------------------------------
    // Things which are not @safe and nothrow and pure and @nogc
    // -------------------------------------------------------------------------

    /**
     * Returns a string version of this vector.
     *
     * Notice that, unlike almost everything else in this module, this method is
     * $(I not) `@nogc` nor `@safe`.
     */
    public nothrow @property string toString() const
    {
        import std.format: format;
        import std.exception: assumeWontThrow;

        return assumeWontThrow(format("%s", _data));
    }

    ///
    unittest
    {
        Vec4f v = [ 1.1, 2.2, 3.3, 4.4 ];
        assert(v.toString == "[1.1, 2.2, 3.3, 4.4]");
    }


    // All methods below this point are @safe, nothrow, pure and @nogc
    @safe: nothrow: pure: @nogc:

    // -------------------------------------------------------------------------
    // Constructors
    // -------------------------------------------------------------------------

    /// Constructs a Vector from a scalar; sets all elements to the same value.
    public this(U)(U value)
        if (is(U : T))
    {
        opAssign!U(value);
    }

    /// Constructs a Vector from same-sized Vector of compatible type.
    public this(U)(auto ref const Vector!(U, N) other)
        if (is(U : T))
    {
        _data[0] = other._data[0];
        _data[1] = other._data[1];
        static if (N >= 3) _data[2] = other._data[2];
        static if (N >= 4) _data[3] = other._data[3];
    }


    static if (N == 2)
    {
        /// Constructs a 2-element vector from scalars.
        public this(X, Y)(X x, Y y)
            if (is(X : T) && is(Y : T))
        {
            _data[0] = x;
            _data[1] = y;
        }
    }
    else static if (N == 3)
    {
        /// Constructs a 3-element vector from scalars.
        public this(X, Y, Z)(X x, Y y, Z z)
            if (is(X : T) && is(Y : T) && is(Z : T))
        {
            _data[0] = x;
            _data[1] = y;
            _data[2] = z;
        }

        /// Constructs a 3-element vector from a 2-element vector and a scalar.
        public this(XY, Z)(auto ref const Vector!(XY, 2) xy, Z z)
            if (is(XY : T) && is(Z : T))
        {
            _data[0] = xy._data[0];
            _data[1] = xy._data[1];
            _data[2] = z;
        }

        /// Ditto
        public this(X, YZ)(X x, auto ref const Vector!(YZ, 2) yz)
            if (is(X : T) && is(YZ : T))
        {
            _data[0] = x;
            _data[1] = yz._data[0];
            _data[2] = yz._data[1];
        }
    }
    else static if (N == 4)
    {
        /// Constructs a 4-element vector from scalars.
        public this(X, Y, Z, W)(X x, Y y, Z z, W w)
            if (is(X : T) && is(Y : T) && is(Z : T) && is(W : T))
        {
            _data[0] = x;
            _data[1] = y;
            _data[2] = z;
            _data[3] = w;
        }

        /// Constructs a 4-element vector from 2-element vectors.
        public this(XY, ZW)
            (auto ref const Vector!(XY, 2) xy, auto ref const Vector!(ZW, 2) zw)
            if (is(XY : T) && is(ZW : T))
        {
            _data[0] = xy._data[0];
            _data[1] = xy._data[1];
            _data[2] = zw._data[0];
            _data[3] = zw._data[1];
        }

        /// Constructs a 4-element vector from a 2-element vector and two scalars.
        public this(XY, Z, W)(auto ref const Vector!(XY, 2) xy, Z z, W w)
            if (is(XY : T) && is(Z : T) && is(W : T))
        {
            _data[0] = xy._data[0];
            _data[1] = xy._data[1];
            _data[2] = z;
            _data[3] = w;
        }

        /// Ditto
        public this(X, YZ, W)(X x, auto ref const Vector!(YZ, 2) yz, W w)
            if (is(X : T) && is(YZ : T) && is(W : T))
        {
            _data[0] = x;
            _data[1] = yz._data[0];
            _data[2] = yz._data[1];
            _data[3] = w;
        }

        /// Ditto
        public this(X, Y, ZW)(X x, Y y, auto ref const Vector!(ZW, 2) zw)
            if (is(X : T) && is(Y : T) && is(ZW : T))
        {
            _data[0] = x;
            _data[1] = y;
            _data[2] = zw._data[0];
            _data[3] = zw._data[1];
        }

        /// Constructs a 4-element vector from a 3-element vector a scalar.
        public this(XYZ, W)(auto ref const Vector!(XYZ, 3) xyz, W w)
            if (is(XYZ : T) && is(W : T))
        {
            _data[0] = xyz._data[0];
            _data[1] = xyz._data[1];
            _data[2] = xyz._data[2];
            _data[3] = w;
        }

        /// Ditto
        public this(X, YZW)(X x, auto ref const Vector!(YZW, 3) yzw)
            if (is(X : T) && is(YZW : T))
        {
            _data[0] = x;
            _data[1] = yzw._data[0];
            _data[2] = yzw._data[1];
            _data[3] = yzw._data[2];
        }
    }

    /**
     * Constructs the `Vector` from an array.
     *
     * The length of the array must match the vector dimension. For static
     * arrays, the length check is performed at compile-time; for dynamic
     * arrays, it is done at runtime using `assert()`.
     */
    public this(U)(U staticArray)
        if ((isStaticArray!(U)
            && is(typeof(staticArray[0]) : T)
            && (staticArray.length == N)))
    {
        _data[0] = staticArray[0];
        _data[1] = staticArray[1];
        static if (N >= 3) _data[2] = staticArray[2];
        static if (N >= 4) _data[3] = staticArray[3];
    }

    /// Ditto
    public this(U)(U dynArray)
        if (isDynamicArray!(U)
            && is(typeof(dynArray[0]) : T))
    {
        assert(dynArray.length == N);

        _data[0] = dynArray[0];
        _data[1] = dynArray[1];
        static if (N >= 3) _data[2] = dynArray[2];
        static if (N >= 4) _data[3] = dynArray[3];
    }


    // -------------------------------------------------------------------------
    // Assignment operators
    // -------------------------------------------------------------------------

    /// Sets all vector elements to a given scalar.
    ref Vector opAssign(U)(U x)
        if (is(U : T))
    {
        _data[] = x; // copy to each component
        return this;
    }

    /// Assigns from other vector type of same size and compatible type.
    ref Vector opAssign(U)(auto ref const Vector!(U, N) other)
        if (is(U : T))
    {
        _data[0] = other._data[0];
        _data[1] = other._data[1];
        static if (N >= 3) _data[2] = other._data[2];
        static if (N >= 4) _data[3] = other._data[3];

        return this;
    }

    /**
     * Assigns an array to this vector.
     *
     * The length of the array must match the vector dimension. For static
     * arrays, the length check is performed at compile-time; for dynamic
     * arrays, it is done at runtime using `assert()`.
     */
    public ref Vector opAssign(U)(U staticArray)
        if ((isStaticArray!(U)
             && is(typeof(staticArray[0]) : T)
             && (staticArray.length == N)))
    {
        _data[0] = staticArray[0];
        _data[1] = staticArray[1];
        static if (N >= 3) _data[2] = staticArray[2];
        static if (N >= 4) _data[3] = staticArray[3];

        return this;
    }

    /// Ditto
    public ref Vector opAssign(U)(U dynArray)
        if (isDynamicArray!(U) && is(typeof(dynArray[0]) : T))
    {
        assert(dynArray.length == N, "Wrong Vector dimension in assignment");

        _data[0] = dynArray[0];
        _data[1] = dynArray[1];
        static if (N >= 3) _data[2] = dynArray[2];
        static if (N >= 4) _data[3] = dynArray[3];

        return this;
    }


    // -------------------------------------------------------------------------
    // Access to elements
    // -------------------------------------------------------------------------

    /// Provides read and write access to elements through indexing
    public ref inout(T) opIndex(size_t i) inout
    {
        assert(i < N);
        return _data[i];
    }

    /**
     * Provides read and write access to vector elements through one-character
     * names.
     *
     * These names are the usual ones used for coordinates in space (`x`, `y`,
     * `z`, `w`), colors (`r`, `g`, `b`, `a`) and texture coordinates (`s`, `t`,
     * `p`, `q`); not by coincidence, these are the names used by GLSL vectors.
     */
    public @property ref inout(T) x() inout { return _data[0]; }
    alias r = x; /// Ditto
    alias s = x; /// Ditto
    public @property ref inout(T) y() inout { return _data[1]; } /// Ditto
    alias g = y; /// Ditto
    alias t = y; /// Ditto

    static if (N >= 3)
    {
        public @property ref inout(T) z() inout { return _data[2]; } /// Ditto
        alias b = z; /// Ditto
        alias p = z; /// Ditto
    }
    static if (N >= 4)
    {
        public @property ref inout(T) w() inout { return _data[3]; } /// Ditto
        alias a = w; /// Ditto
        alias q = w; /// Ditto
    }

    /// Returns a pointer to the vector data.
    public @property inout(T*) ptr() inout
    {
        return _data.ptr;
    }


    // -------------------------------------------------------------------------
    // Other operators
    // -------------------------------------------------------------------------

    /// Vector equality
    public bool opEquals(U)(auto ref const Vector!(U, N) other) const
        if (is(T : U))
    {
        static if (N == 2)
        {
            return _data[0] == other._data[0] && _data[1] == other._data[1];
        }
        else static if (N == 3)
        {
            return _data[0] == other._data[0] && _data[1] == other._data[1]
                && _data[2] == other._data[2];
        }
        else static if (N == 4)
        {
            return _data[0] == other._data[0] && _data[1] == other._data[1]
                && _data[2] == other._data[2] && _data[3] == other._data[3];
        }
        else
        {
            static assert(false, "Unexpected Vector dimension"); // Can't happen
        }
    }

    /// Vector negation and the useless-but-symmetric "unary plus".
    public Vector opUnary(string op)() const
        if (op == "+" || op == "-")
    {
        Vector res = void;
        mixin("res._data[0] = " ~ op ~ "_data[0];");
        mixin("res._data[1] = " ~ op ~ "_data[1];");
        static if (N >= 3) mixin("res._data[2] = " ~ op ~ "_data[2];");
        static if (N >= 4) mixin("res._data[3] = " ~ op ~ "_data[3];");

        return res;
    }

    /// Add-assign and subtract-assign vector of same or compatible types.
    public ref Vector opOpAssign(string op, U)
        (auto ref const Vector!(U, N) other)
        if (isNumeric!U && (op == "+" || op == "-"))
    {
        mixin("_data[0] " ~ op ~ "= other._data[0];");
        mixin("_data[1] " ~ op ~ "= other._data[1];");
        static if (N >= 3) mixin("_data[2] " ~ op ~ "= other._data[2];");
        static if (N >= 4) mixin("_data[3] " ~ op ~ "= other._data[3];");

        return this;
    }

    /// Vector addition and subtraction.
    public Vector opBinary(string op, U)(auto ref const Vector!(U, N) rhs) const
        if (isNumeric!U && (op == "+" || op == "-"))
    {
        Vector temp = this;
        return temp.opOpAssign!op(rhs);
    }

    /// Ditto
    public Vector opBinaryRight(string op, U)
        (auto ref const Vector!(U, N) lhs) const
        if (op == "+" || op == "-")
    {
        Vector temp = lhs;
        return temp.opOpAssign!op(this);
    }

    /// Vector scaling (multiplication and division by scalar)
    public Vector opBinary(string op, U)(U rhs) const
       if (isNumeric!U && (op == "*" || op == "/"))
    {
        Vector res = this;
        mixin("res " ~ op ~ "= rhs;");
        return res;
    }

    /// Ditto
    public Vector opBinaryRight(string op, U)(U lhs) const
        if (isNumeric!U && op == "*")
    {
        mixin("return this " ~ op ~ "lhs;");
    }

    /// Ditto
    public ref Vector opOpAssign(string op, U)(U rhs)
        if (isNumeric!U && (op == "*" || op == "/"))
    {
        mixin("_data[0] " ~ op ~ "= rhs;");
        mixin("_data[1] " ~ op ~ "= rhs;");
        static if (N >= 3) mixin("_data[2] " ~ op ~ "= rhs;");
        static if (N >= 4) mixin("_data[3] " ~ op ~ "= rhs;");

        return this;
    }


    // -------------------------------------------------------------------------
    // Swizzling
    // -------------------------------------------------------------------------

    /**
     * Swizzling support, kinda of like in shading languages.
     *
     * This does not support swizzling assignment.
     *
     * And, while it may not make much sense, it is possible to mix letters from
     * different sets, like `vec.xrs`.
     */
    public @property auto opDispatch(string op)() const
        if (isValidSwizzle(op))
    {
        Vector!(T, op.length) res;

        enum i0 = getSwizzleIndex!N(op[0]);
        res._data[0] = _data[i0];

        enum i1 = getSwizzleIndex!N(op[1]);
        res._data[1] = _data[i1];

        static if (op.length >= 3)
        {
            enum i2 = getSwizzleIndex!N(op[2]);
            res._data[2] = _data[i2];
        }

        static if (op.length >= 4)
        {
            enum i3 = getSwizzleIndex!N(op[3]);
            res._data[3] = _data[i3];
        }

        return res;
    }

    /**
     * Checks whether a given string is valid swizzling string.
     *
     * Parameters:
     *     op = The string to test.
     */
    private static bool isValidSwizzle(string op)
    {
        if (op.length < 2 || op.length > 4)
            return false;

        foreach (c; op)
        {
            if (getSwizzleIndex!4(c) == size_t.max)
                return false;
        }
        return true;
    }

    unittest
    {
        assert(isValidSwizzle("xy"));
        assert(isValidSwizzle("xyz"));
        assert(isValidSwizzle("xyzw"));

        assert(isValidSwizzle("rg"));
        assert(isValidSwizzle("rgb"));
        assert(isValidSwizzle("rgba"));

        assert(isValidSwizzle("st"));
        assert(isValidSwizzle("stp"));
        assert(isValidSwizzle("stpq"));

        assert(isValidSwizzle("zrp"));

        assert(!isValidSwizzle("abcd"));
        assert(!isValidSwizzle("x"));
        assert(!isValidSwizzle("xxxxx"));
    }

    /**
     * Gets the index (for indexing `_data`) of a given character when used for
     * swizzling.
     *
     * Parameters:
     *     c = The character to test.
     *
     * Returns:
     *     The index; `size_t.max` if `c` is not a valid swizzling character.
     */
    private static size_t getSwizzleIndex(size_t N)(char c)
    {
        if (c == 'x' || c == 'r' || c == 's')
            return 0;

        if (c == 'y' || c == 'g' || c == 't')
            return 1;

        static if (N >= 3)
        {
            if (c == 'z' || c == 'b' || c == 'p')
                return 2;
        }

        static if (N >= 4)
        {
            if (c == 'w' || c == 'a' || c == 'q')
                return 3;
        }

        return size_t.max;
    }


    // -------------------------------------------------------------------------
    // Slicing
    // -------------------------------------------------------------------------

    /**
     * Operators used for supporting slicing on `Vector`s.
     *
     * I don't know if this will be really useful, but support is here.
     */
    public size_t opDollar() const
    {
        return N;
    }

    /// Ditto
    public inout(T[]) opSlice() inout
    {
        return _data[];
    }

    /// Ditto
    public inout(T[]) opSlice(size_t a, size_t b) inout
    {
        return _data[a..b];
    }


    // -------------------------------------------------------------------------
    // Other vector operations
    // -------------------------------------------------------------------------

    static if (isFloatingPoint!T)
    {
        /**
         * Normalizes this `Vector`, that is leaves it pointing to the same
         * direction, but with unit length.
         */
        public void normalize()
        {
            const invLength = 1.0 / this.length;
            _data[] *= invLength; // array operations
        }
    }


    // -------------------------------------------------------------------------
    // Data members
    // -------------------------------------------------------------------------

    /// Vector data, AKA "the vector elements".
    private T[N] _data;
}


// -----------------------------------------------------------------------------
// Stuff that looks better as non-members (UFCS is always there, anyway)
// -----------------------------------------------------------------------------

/// Returns the squared Euclidean length of a given `Vector`.
public @property @safe nothrow pure @nogc auto squaredLength(T, size_t N)
    (auto ref const Vector!(T, N) v)
{
    static if (N == 2)
    {
        return v._data[0] * v._data[0] + v._data[1] * v._data[1];
    }
    else static if (N == 3)
    {
        return v._data[0] * v._data[0] + v._data[1] * v._data[1]
            + v._data[2] * v._data[2];
    }
    else static if (N == 4)
    {
        return v._data[0] * v._data[0] + v._data[1] * v._data[1]
            + v._data[2] * v._data[2] + v._data[3] * v._data[3];
    }
    else
    {
        static assert(false, "Unexpected Vector dimension"); // Can't happen
    }
}

/// Returns the Euclidean length of a given `Vector`.
public @property @safe nothrow pure @nogc auto length(T, size_t N)
    (auto ref const Vector!(T, N) v)
{
    import std.math;

    // Cannot take the square root of, say, an int. So, if necessary, try
    // casting the squared length to a real.
    static if (__traits(compiles, sqrt(v.squaredLength)))
        return sqrt(v.squaredLength);
    else static if (__traits(compiles, sqrt(cast(real)(v.squaredLength))))
        return sqrt(cast(real)(v.squaredLength));
    else
        static assert(false, "Cannot get the length of a non-numeric Vector");
}

/**
 * Interpreting vectors as points, computes and returns the squared Euclidean
 * distance between two `Vector`s.
 */
public @safe nothrow pure @nogc auto squaredDist(T, U, size_t D)
    (auto ref const Vector!(T, D) v1, auto ref const Vector!(U, D) v2)
{
    return (v1 - v2).squaredLength();
}

/**
 * Interpreting vectors as points, computes and returns the Euclidean distance
 * between two `Vector`s.
 */
public @property @safe nothrow pure @nogc auto dist(T, U, size_t N)
    (auto ref const Vector!(T, N) v1, auto ref const Vector!(U, N) v2)
{
    import std.math;

    // Cannot take the square root of, say, an int. So, if necessary, try
    // casting the squared length to a real.
    static if (__traits(compiles, sqrt(squaredDist(v1, v2))))
    {
        return sqrt(squaredDist(v1, v2));
    }
    else static if (__traits(compiles, sqrt(cast(real)(squaredDist(v1, v2)))))
    {
        return sqrt(cast(real)(squaredDist(v1, v2)));
    }
    else
    {
        static assert(
            false, "Cannot compute the distance between non-numeric Vectors");
    }
}

/**
 * Returns a normalized version (unit length, same direction) of a given
 * `Vector`.
 */
public @property @safe nothrow pure @nogc auto normalized(T, size_t N)
    (auto ref const Vector!(T, N) v)
    if (isFloatingPoint!T)
{
    Vector!(T, N) res = v;
    res.normalize();
    return res;
}

/// Returns the dot product of two `Vector`s.
public @safe nothrow pure @nogc auto dot(T, U, size_t N)
    (auto ref const Vector!(T, N) v1, auto ref const Vector!(U, N) v2)
{
    CommonType!(T, U) res =
        v1._data[0] * v2._data[0] + v1._data[1] * v2._data[1];
    static if (N >= 3) res += v1._data[2] * v2._data[2];
    static if (N >= 4) res += v1._data[3] * v2._data[3];

    return res;
}

/// Returns the cross product of two 3D `Vector`s.
public @safe nothrow pure @nogc auto cross(T, U)
    (auto ref const Vector!(T, 3) v1, auto ref const Vector!(U, 3) v2)
{
    alias TU = CommonType!(T, U);

    return Vector!(TU, 3)(
        v1._data[1] * v2._data[2] - v1._data[2] * v2._data[1],
        v1._data[2] * v2._data[0] - v1._data[0] * v2._data[2],
        v1._data[0] * v2._data[1] - v1._data[1] * v2._data[0]);
}

/**
 * Returns the reflected vector, given an incident vector and a normal vector;
 * this is the same as GLSL's `reflect()` function.
 *
 * Parameters:
 *     i = The incident vector.
 *     n = The normal vector, which must a unit vector.
 *
 * Returns: The reflect vector, with the same length as `i`.
 */
public @safe nothrow pure @nogc auto reflect(T, U, size_t D)
    (auto ref const Vector!(T, D) i, auto ref const Vector!(U, D) n)
in
{
    import sbxs.util.test: isClose;
    assert(isClose(n.squaredLength, 1.0, 1e-5));
}
body
{
    return i - 2.0 * dot(n, i) * n;
}

/**
 * Returns the angle, in radians, between two vectors.
 *
 * This doesn't use the typical `acos(dot(v1,v2))` formula, by following the
 * advice from
 * $(LINK2 http://www.plunk.org/~hatch/rightway.php, The Right Way to Calculate Stuff).
 */
public @safe nothrow pure @nogc auto angle(T, U, size_t N)
    (auto ref const Vector!(T, N) v1, auto ref const Vector!(U, N) v2)
{
    import std.math;
    import std.traits;

    static if(isFloatingPoint!T)
        const v1n = v1.normalized();
    else
        const v1n = Vector!(real, N)(v1).normalized();

    static if(isFloatingPoint!U)
        const v2n = v2.normalized();
    else
        const v2n = Vector!(real, N)(v2).normalized();

    const dp = dot(v1n, v2n);

    if (dp < 0)
        return PI - 2 * asin((-v2n-v1n).length / 2.0);
    else
        return 2 * asin((v2n-v1n).length / 2.0);
}

/**
 * Returns a 3D vector orthogonal to a given 3D vector.
 *
 * Based on an algorithm described in post by
 * $(LINK2 lolengine.net/blog/2013/09/21/picking-orthogonal-vector-combing-coconuts, Sam Hocevar).
 *
 * Parameters:
 *     v = The input vector.
 *
 * Returns: A vector orthogonal to `v`; it is not normalized.
 */
public @safe nothrow pure @nogc Vector!(T, 3) orthogonal(T)
    (auto ref const Vector!(T, 3) v)
{
    import std.math;

    return abs(v._data[0]) > abs(v._data[2])
        ? Vector!(T, 3)(-v._data[1],  v._data[0], 0)
        : Vector!(T, 3)( 0       , -v._data[2], v._data[1]);
}

/**
 * Orthonormalizes a set of vectors.
 *
 * This implements the Gram-Schmidt method. User's shouldn't rely on the fact
 * that this particular method is used (the implementation may change someday!),
 * but you can assume that the method used will not be much slower than
 * Gram-Schmidt. Avoid making assumptions on the "quality" of this
 * orthonormalization.
 *
 * Vectors are normalized "in place" (that is, this function modifies its
 * parameters).
 */
public @safe nothrow pure @nogc void orthonormalize(T1, T2)
    (ref Vector!(T1, 2) v1, ref Vector!(T2, 2) v2)
    if (isFloatingPoint!T1 && isFloatingPoint!T2)
{
    v1.normalize();
    v2 -= dot(v2, v1) * v1;
    v2.normalize();
}

/// Ditto
public @safe nothrow pure @nogc void orthonormalize(T1, T2, T3)
    (ref Vector!(T1, 3) v1, ref Vector!(T2, 3) v2, ref Vector!(T3, 3) v3)
    if (isFloatingPoint!T1 && isFloatingPoint!T2 && isFloatingPoint!T3)
{
    v1.normalize();
    v2 -= dot(v2, v1) * v1;
    v2.normalize();
    v3 -= dot(v3, v1) * v1 + dot(v3, v2) * v2;
    v3.normalize();
}

/// Ditto
public @safe nothrow pure @nogc void orthonormalize(T1, T2, T3, T4)
    (ref Vector!(T1, 4) v1, ref Vector!(T2, 4) v2,
     ref Vector!(T3, 4) v3, ref Vector!(T4, 4) v4)
    if (isFloatingPoint!T1 && isFloatingPoint!T2 && isFloatingPoint!T3
        && isFloatingPoint!T4)
{
    v1.normalize();
    v2 -= dot(v2, v1) * v1;
    v2.normalize();
    v3 -= dot(v3, v1) * v1 + dot(v3, v2) * v2;
    v3.normalize();
    v4 -= dot(v4, v1) * v1 + dot(v4, v2) * v2 + dot(v4, v3) * v3;
    v4.normalize();
}


// -----------------------------------------------------------------------------
// Handy aliases
// -----------------------------------------------------------------------------

/// Bunch of aliases for commonly used vector types.
public alias Vec2f = Vector!(float, 2);
public alias Vec2d = Vector!(double, 2); /// Ditto
public alias Vec2r = Vector!(real, 2); /// Ditto
public alias Vec2b = Vector!(byte, 2); /// Ditto
public alias Vec2ub = Vector!(ubyte, 2); /// Ditto
public alias Vec2s = Vector!(short, 2); /// Ditto
public alias Vec2us = Vector!(ushort, 2); /// Ditto
public alias Vec2i = Vector!(int, 2); /// Ditto
public alias Vec2ui = Vector!(uint, 2); /// Ditto
public alias Vec2l = Vector!(long, 2); /// Ditto
public alias Vec2ul = Vector!(ulong, 2); /// Ditto

public alias Vec3f = Vector!(float, 3); /// Ditto
public alias Vec3d = Vector!(double, 3); /// Ditto
public alias Vec3r = Vector!(real, 3); /// Ditto
public alias Vec3b = Vector!(byte, 3); /// Ditto
public alias Vec3ub = Vector!(ubyte, 3); /// Ditto
public alias Vec3s = Vector!(short, 3); /// Ditto
public alias Vec3us = Vector!(ushort, 3); /// Ditto
public alias Vec3i = Vector!(int, 3); /// Ditto
public alias Vec3ui = Vector!(uint, 3); /// Ditto
public alias Vec3l = Vector!(long, 3); /// Ditto
public alias Vec3ul = Vector!(ulong, 3); /// Ditto

public alias Vec4f = Vector!(float, 4); /// Ditto
public alias Vec4d = Vector!(double, 4); /// Ditto
public alias Vec4r = Vector!(real, 4); /// Ditto
public alias Vec4b = Vector!(byte, 4); /// Ditto
public alias Vec4ub = Vector!(ubyte, 4); /// Ditto
public alias Vec4s = Vector!(short, 4); /// Ditto
public alias Vec4us = Vector!(ushort, 4); /// Ditto
public alias Vec4i = Vector!(int, 4); /// Ditto
public alias Vec4ui = Vector!(uint, 4); /// Ditto
public alias Vec4l = Vector!(long, 4); /// Ditto
public alias Vec4ul = Vector!(ulong, 4); /// Ditto



// -----------------------------------------------------------------------------
// Unit tests
// -----------------------------------------------------------------------------

// Construction from scalars
unittest
{
    const v0 = Vec4f(0.0);
    assert(v0._data[0] == 0.0);
    assert(v0._data[1] == 0.0);
    assert(v0._data[2] == 0.0);
    assert(v0._data[3] == 0.0);

    const v1 = Vec2d(1.0, 2.0);
    assert(v1._data[0] == 1.0);
    assert(v1._data[1] == 2.0);

    const v2 = Vec3s(cast(short)(-1), cast(short)(-2), cast(short)(-3));
    assert(v2._data[0] == -1);
    assert(v2._data[1] == -2);
    assert(v2._data[2] == -3);

    const v3 = Vec4r(33.0, 44.0, 55.0, 66.0);
    assert(v3._data[0] == 33.0);
    assert(v3._data[1] == 44.0);
    assert(v3._data[2] == 55.0);
    assert(v3._data[3] == 66.0);

    // This should also work with parameters of different types, as long as they
    // are convertible to T
    const ubyte a = 77;
    const long b = -1234567;
    const float c = 10.0;
    const real d = -20.0;

    const v4 = Vec2d(a, b);
    assert(v4._data[0] ==  77.0);
    assert(v4._data[1] == -1234567.0);

    const v5 = Vec3r(a, b, c);
    assert(v5._data[0] ==  77.0);
    assert(v5._data[1] == -1234567.0);
    assert(v5._data[2] ==  10.0);

    const v6 = Vec4f(a, b, c, d);
    assert(v6._data[0] ==  77.0);
    assert(v6._data[1] == -1234567.0);
    assert(v6._data[2] ==  10.0);
    assert(v6._data[3] == -20.0);
}


// Construction from same-sized vectors of compatible type
unittest
{
    Vec2i v1 = [ 8, -8 ];
    const v2 = Vec2l(v1);
    assert(v2._data[0] ==  8);
    assert(v2._data[1] == -8);

    Vec4r v3 = [ 3.0, -1.0, 77.0, 11.0 ];
    immutable v4 = Vec4f(v3);
    assert(v4._data[0] ==   3.0);
    assert(v4._data[1] ==  -1.0);
    assert(v4._data[2] ==  77.0);
    assert(v4._data[3] ==  11.0);
}


// Construction from other vectors (and possibly other scalars)
unittest
{
    const v2ub = Vec2ub(cast(ubyte)(82), cast(ubyte)(83));
    const v2ui = Vec2ui(182, 183);

    // vec3 = (vec2, scalar)
    const v3i1 = Vec3i(v2ub, -84);
    assert(v3i1._data[0] ==  82);
    assert(v3i1._data[1] ==  83);
    assert(v3i1._data[2] == -84);

    // vec3 = (scalar, vec2)
    const v3i2 = Vec3i(-81, v2ub);
    assert(v3i2._data[0] == -81);
    assert(v3i2._data[1] ==  82);
    assert(v3i2._data[2] ==  83);

    // vec4 = (vec2, vec2)
    const v4l1 = Vec4l(v2ub, v2ui);
    assert(v4l1._data[0] == 82);
    assert(v4l1._data[1] == 83);
    assert(v4l1._data[2] == 182);
    assert(v4l1._data[3] == 183);

    // vec4 = (vec2, scalar, scalar)
    const v4l2 = Vec4l(v2ub, -11, -22);
    assert(v4l2._data[0] == 82);
    assert(v4l2._data[1] == 83);
    assert(v4l2._data[2] == -11);
    assert(v4l2._data[3] == -22);

    // vec4 = (scalar, vec2, scalar)
    const v4l3 = Vec4l(111, v2ui, -222);
    assert(v4l3._data[0] ==  111);
    assert(v4l3._data[1] ==  182);
    assert(v4l3._data[2] ==  183);
    assert(v4l3._data[3] == -222);

    // vec4 = (scalar, scalar, vec2)
    const v4l4 = Vec4l(-88, -99, v2ub);
    assert(v4l4._data[0] == -88);
    assert(v4l4._data[1] == -99);
    assert(v4l4._data[2] ==  82);
    assert(v4l4._data[3] ==  83);

    // vec4 = (vec3, scalar)
    const v4l5 = Vec4f(v3i1, 123.0);
    assert(v4l5._data[0] ==  82.0);
    assert(v4l5._data[1] ==  83.0);
    assert(v4l5._data[2] == -84.0);
    assert(v4l5._data[3] ==  123.0);

    // vec4 = (scalar, vec3)
    const v4l6 = Vec4f(-987.0f, v3i2);
    assert(v4l6._data[0] == -987.0);
    assert(v4l6._data[1] == -81.0);
    assert(v4l6._data[2] ==  82.0);
    assert(v4l6._data[3] ==  83.0);
}


// Construction from arrays
unittest
{
    Vec4f v4f = [ 95.0f, 96.0f, 97.0f, 98.0f ];
    assert(v4f._data[0] == 95.0);
    assert(v4f._data[1] == 96.0);
    assert(v4f._data[2] == 97.0);
    assert(v4f._data[3] == 98.0);

    double[4] sa4d = [ -11.0, -22.0, -33.0, 44.0 ];
    v4f = Vec4f(sa4d);
    assert(v4f._data[0] == -11.0);
    assert(v4f._data[1] == -22.0);
    assert(v4f._data[2] == -33.0);
    assert(v4f._data[3] ==  44.0);

    Vec2ui v2ui = [ 55u, 56u ];
    assert(v2ui._data[0] == 55);
    assert(v2ui._data[1] == 56);

    byte[2] sa2b = [ 33, 44 ];
    v2ui = Vec2ui(sa2b);
    assert(v2ui._data[0] == 33);
    assert(v2ui._data[1] == 44);
}


// Scalar assignment
unittest
{
    Vec4d v0 = [ 1.0, 2.0, 3.0, 4.0 ];
    v0 = 0.0;

    assert(v0._data[0] == 0.0);
    assert(v0._data[1] == 0.0);
    assert(v0._data[2] == 0.0);
    assert(v0._data[3] == 0.0);
}


// Array assignment
unittest
{
    Vec4f v4f;
    float[4] sa4f = [ 1.0, -2.0, 3.0, -4.0 ];
    int[4] sa4i = [ 5, 0, 3, -1 ];
    float[] da4f = [ 11.0, 22.0, 33.0, -44.0 ];
    double[] da4d = [ -11.0, -22.0, -33.0, 44.0 ];

    // Assignment of static array of same type
    v4f = sa4f;
    assert(v4f[0] ==  1.0);
    assert(v4f[1] == -2.0);
    assert(v4f[2] ==  3.0);
    assert(v4f[3] == -4.0);

    // Assignment of static array of compatible type
    v4f = sa4i;
    assert(v4f[0] ==  5.0);
    assert(v4f[1] ==  0.0);
    assert(v4f[2] ==  3.0);
    assert(v4f[3] == -1.0);

    // Assignment of dynamic array of same type
    v4f = da4f;
    assert(v4f[0] ==  11.0);
    assert(v4f[1] ==  22.0);
    assert(v4f[2] ==  33.0);
    assert(v4f[3] == -44.0);

    // Assignment of dynamic array of compatible type
    v4f = da4d;
    assert(v4f[0] == -11.0);
    assert(v4f[1] == -22.0);
    assert(v4f[2] == -33.0);
    assert(v4f[3] ==  44.0);

    // Do similar tests with a different Vector instantiation
    Vec2ui v2ui;
    uint[2] sa2ui = [ 254, 255 ];
    int[2] sa2i = [ 41, 42 ];
    uint[] da2ui = [ 170, 171 ];
    byte[] da2b = [ 77, 88 ];

    v2ui = sa2ui;
    assert(v2ui[0] == 254);
    assert(v2ui[1] == 255);

    v2ui = sa2i;
    assert(v2ui[0] == 41);
    assert(v2ui[1] == 42);

    v2ui = da2ui;
    assert(v2ui[0] == 170);
    assert(v2ui[1] == 171);

    v2ui = da2b;
    assert(v2ui[0] == 77);
    assert(v2ui[1] == 88);

    // Try some chained assignments
    Vec4f otherV4f;
    Vec2ui otherV2ui;

    v4f = otherV4f = sa4f;
    assert(v4f[0] ==  1.0);
    assert(v4f[1] == -2.0);
    assert(v4f[2] ==  3.0);
    assert(v4f[3] == -4.0);
    assert(otherV4f[0] ==  1.0);
    assert(otherV4f[1] == -2.0);
    assert(otherV4f[2] ==  3.0);
    assert(otherV4f[3] == -4.0);

    v2ui = otherV2ui = da2ui;
    assert(v2ui[0] == 170);
    assert(v2ui[1] == 171);
}


// Assignment of Vector to Vector
unittest
{
    // Same types
    const v2i1 = Vec2i(1234, -5678);
    Vec2i v2i2 = 0;
    v2i2 = v2i1;
    assert(v2i2._data[0] ==  1234);
    assert(v2i2._data[1] == -5678);

    const v4ui1 = Vec4ui(33, 44, 55, 66);
    Vec4ui v4ui2 = 0;
    v4ui2 = v4ui1;
    assert(v4ui2._data[0] == 33);
    assert(v4ui2._data[1] == 44);
    assert(v4ui2._data[2] == 55);
    assert(v4ui2._data[3] == 66);

    // Different but compatible types
    Vec2d v2d = 0.0;
    v2d = v2i1;
    assert(v2d._data[0] ==  1234.0);
    assert(v2d._data[1] == -5678.0);

    Vec4f v4f = 0.0;
    v4f = v4ui2;
    assert(v4f._data[0] == 33.0);
    assert(v4f._data[1] == 44.0);
    assert(v4f._data[2] == 55.0);
    assert(v4f._data[3] == 66.0);
}


// Accessing array elements through indexing
unittest
{
    Vec4i v4i = [ 1, 2, 3, 4 ];

    // Read
    assert(v4i[0] == 1);
    assert(v4i[1] == 2);
    assert(v4i[2] == 3);
    assert(v4i[3] == 4);

    // Write
    v4i[2] = 33;
    assert(v4i[0] == 1);
    assert(v4i[1] == 2);
    assert(v4i[2] == 33);
    assert(v4i[3] == 4);

    v4i[0] = 11;
    assert(v4i[0] == 11);
    assert(v4i[1] == 2);
    assert(v4i[2] == 33);
    assert(v4i[3] == 4);

    v4i[3] = 44;
    assert(v4i[0] == 11);
    assert(v4i[1] == 2);
    assert(v4i[2] == 33);
    assert(v4i[3] == 44);

    v4i[1] = 22;
    assert(v4i[0] == 11);
    assert(v4i[1] == 22);
    assert(v4i[2] == 33);
    assert(v4i[3] == 44);

    // Read from const and immutable vectors
    const(Vec4i) vc = [ -1, 0, 1, 2 ];
    assert(vc[0] == -1);
    assert(vc[1] ==  0);
    assert(vc[2] ==  1);
    assert(vc[3] ==  2);

    immutable vi = Vec4i(-10, 0, 10, 20);
    assert(vi[0] == -10);
    assert(vi[1] ==  0);
    assert(vi[2] ==  10);
    assert(vi[3] ==  20);
}


// Accessing elements through named members
unittest
{
    // Read
    Vec4f v = [ 0.0, -1.0, -2.0, 3.0 ];
    assert(v.x ==  0.0);
    assert(v.y == -1.0);
    assert(v.z == -2.0);
    assert(v.w ==  3.0);

    // Write
    v.x = 99.0;
    assert(v.x == 99.0);
    v.x += 1.0;
    assert(v.x == 100.0);

    v.y = 11.0;
    assert(v.y == 11.0);
    v.y -= 1.0;
    assert(v.y == 10.0);

    v.z = 10.0;
    assert(v.z == 10.0);
    v.z *= 2.0;
    assert(v.z == 20.0);

    // Test access through alternative names (RGBA, STPQ)
    v.x = 1.0;
    v.y = 2.0;
    v.z = 3.0;
    v.w = 4.0;

    assert(v.r == 1.0);
    assert(v.g == 2.0);
    assert(v.b == 3.0);
    assert(v.a == 4.0);

    assert(v.s == 1.0);
    assert(v.t == 2.0);
    assert(v.p == 3.0);
    assert(v.q == 4.0);

    // Just in case, try some writing operations with the alternative names
    v.r = 2.0;
    v.g += 1.0;
    v.b -= 1.0;
    v.a /= 2.0;
    assert(v.x == 2.0);
    assert(v.y == 3.0);
    assert(v.z == 2.0);
    assert(v.w == 2.0);

    v.s =  0.0;
    v.t = -1.0;
    v.p = -2.0;
    v.q -= 5.0;
    assert(v.r ==  0.0);
    assert(v.g == -1.0);
    assert(v.b == -2.0);
    assert(v.a == -3.0);

    // Finally, be sure that this work with constant vectors
    const(Vec4i) vc = [ -1, 0, 1, 2 ];
    assert(vc.r == -1);
    assert(vc.g ==  0);
    assert(vc.b ==  1);
    assert(vc.a ==  2);
    assert(vc.s == -1);
    assert(vc.t ==  0);
    assert(vc.p ==  1);
    assert(vc.q ==  2);

    immutable vi = Vec4i([ -10, 0, 10, 20 ]);
    assert(vi.r == -10);
    assert(vi.g ==  0);
    assert(vi.b ==  10);
    assert(vi.a ==  20);
    assert(vi.s == -10);
    assert(vi.t ==  0);
    assert(vi.p ==  10);
    assert(vi.q ==  20);
}


// Vector.ptr
unittest
{
    Vec4f v = [ 1.1, 2.2, 3.3, 4.4 ];
    assert(v.ptr == &v._data[0]);

    const Vec4r vc = [ 1.11, 2.22, 3.33, 4.44 ];
    assert(vc.ptr == &vc._data[0]);
}


// Equality
unittest
{
    // Same types
    Vec2r v2i1 = [ 4,  6 ];
    Vec2r v2i2 = [ 4,  6 ];
    Vec2r v2i3 = [ 4, -6 ];
    assert(v2i1 == v2i2);
    assert(v2i2 == v2i1);
    assert(v2i1 != v2i3);
    assert(v2i3 != v2i1);

    Vec3ui v3ui1 = [ 9, 8, 7 ];
    Vec3ui v3ui2 = [ 9, 8, 7 ];
    Vec3ui v3ui3 = [ 9, 8, 9 ];
    assert(v3ui1 == v3ui2);
    assert(v3ui2 == v3ui1);
    assert(v3ui1 != v3ui3);
    assert(v3ui3 != v3ui1);

    const Vec4f v4f1 = [ 1.0, 2.2, 3.0, -4.4 ];
    immutable Vec4f v4f2 = [ 1.0, 2.2, 3.0, -4.4 ];
    Vec4f v4f3 = [ 1.0, 2.2, 3.0,  4.4 ];
    assert(v4f1 == v4f2);
    assert(v4f2 == v4f1);
    assert(v4f1 != v4f3);
    assert(v4f3 != v4f1);

    // Different, compatible types
    Vec2f v2d1 = [ 4.0, 6.0 ];
    Vec2f v2d2 = [ 8.0, 1.0 ];
    assert(v2i1 == v2d1);
    assert(v2d1 == v2i1);
    assert(v2i1 != v2d2);
    assert(v2d2 != v2i1);

    const Vec3ul v3ul1 = [ 9, 8, 7 ];
    const Vec3ul v3ul2 = [ 9, 8, 70 ];
    assert(v3ui1 == v3ul1);
    assert(v3ul1 == v3ui1);
    assert(v3ui1 != v3ul2);
    assert(v3ul2 != v3ui1);

    const Vec4f v4d1 = [ 1.0, 2.2, 3.0, -4.4 ];
    const Vec4r v4r1 = [ 1.0, 2.2, 3.0,  4.4 ];
    assert(v4f1 == v4d1);
    assert(v4d1 == v4f1);
    assert(v4f1 != v4r1);
    assert(v4r1 != v4f1);
}


// Vector negation and "unary plus"
unittest
{
    Vec3l v1 = [ 12, 13, 14 ];
    auto negV1 = -v1;
    auto posV1 = +v1;
    assert(negV1.x == -12);
    assert(negV1.y == -13);
    assert(negV1.z == -14);
    assert(posV1.x ==  12);
    assert(posV1.y ==  13);
    assert(posV1.z ==  14);

    const Vec4f v2 = [ 2.0, -4.0, 6.0, 8.0 ];
    auto negV2 = -v2;
    auto posV2 = +v2;

    assert(negV2.x == -2.0);
    assert(negV2.y ==  4.0);
    assert(negV2.z == -6.0);
    assert(negV2.w == -8.0);
    assert(posV2.x ==  2.0);
    assert(posV2.y == -4.0);
    assert(posV2.z ==  6.0);
    assert(posV2.w ==  8.0);
}


// Add-assign and subtract-assign
unittest
{
    Vec3r v3r = [ 1.0, 2.0, 3.0 ];

    v3r += Vec3ui(3, 2, 1);
    assert(v3r.r == 4.0);
    assert(v3r.g == 4.0);
    assert(v3r.b == 4.0);

    v3r -= Vec3f(3, 2, 1);
    assert(v3r.r == 1.0);
    assert(v3r.g == 2.0);
    assert(v3r.b == 3.0);

    Vec4f v4f = [ 10.0, -20.0, 30.0, -40.0 ];

    v4f -= Vec4f(-5.0, -6.0, 2.0, 33.0);
    assert(v4f.x ==  15.0);
    assert(v4f.y == -14.0);
    assert(v4f.z ==  28.0);
    assert(v4f.w == -73.0);

    v4f += Vec4ul(0, 14, 0, 73);
    assert(v4f.x == 15.0);
    assert(v4f.y ==  0.0);
    assert(v4f.z == 28.0);
    assert(v4f.w ==  0.0);
}


// Vector addition and subtraction
unittest
{
    Vec3i v1 = [ 1, 2, 3 ];
    const Vec3l v2 = [ 10, 20, 30 ];

    immutable Vec3ul v3 = v1 + v2;
    assert(v3.x == 11);
    assert(v3.y == 22);
    assert(v3.z == 33);

    Vec3ul v4 = v2 - v1;
    assert(v4.x ==  9);
    assert(v4.y == 18);
    assert(v4.z == 27);

    auto v5 = Vec4f(-1.0, -2.0, -3.0, -4.0);
    auto v6 = Vec4ul(3, 3, 3, 3);

    Vec4f v7 = v5 + v6;
    assert(v7.x ==  2.0);
    assert(v7.y ==  1.0);
    assert(v7.z ==  0.0);
    assert(v7.w == -1.0);

    immutable Vec4f v8 = v7 - Vec4f(2.0, 1.0, 0.0, -1.0);
    assert(v8.x == 0.0);
    assert(v8.y == 0.0);
    assert(v8.z == 0.0);
    assert(v8.w == 0.0);
}


// Vector scaling (multiplication and division by scalar)
unittest
{
    const v1 = Vec3i(1, 2, -3);
    auto v2 = v1 * 2.1;
    assert(v2.x ==  2);
    assert(v2.y ==  4);
    assert(v2.z == -6);

    auto v3 = v1 * -7;
    assert(v3.x ==  -7);
    assert(v3.y == -14);
    assert(v3.z ==  21);

    Vec3l v4 = -1 * v3;
    assert(v4.x ==   7);
    assert(v4.y ==  14);
    assert(v4.z == -21);

    immutable v5 = Vec4f(6.0, -15.0, 0.0, 3.0);
    auto v6 = v5 / 3;
    assert(v6.x ==   2.0);
    assert(v6.y ==  -5.0);
    assert(v6.z ==   0.0);
    assert(v6.w ==   1.0);

    auto v7 = Vec4d(-100.0, 50.0, 70.0, -30.0) / -10.0;
    assert(v7.x ==  10.0);
    assert(v7.y ==  -5.0);
    assert(v7.z ==  -7.0);
    assert(v7.w ==   3.0);

    v7 *= 6.0;
    assert(v7.x ==  60.0);
    assert(v7.y == -30.0);
    assert(v7.z == -42.0);
    assert(v7.w ==  18.0);

    v7 /= -6;
    assert(v7.x == -10.0);
    assert(v7.y ==   5.0);
    assert(v7.z ==   7.0);
    assert(v7.w ==  -3.0);
}


// Swizzling
unittest
{
    const v1 = Vec4f(1.0, -2.0, 3.0, -4.0);

    auto v2 = v1.zwyx;
    assert(v2.x ==  3.0);
    assert(v2.y == -4.0);
    assert(v2.z == -2.0);
    assert(v2.w ==  1.0);

    immutable v3 = v1.abgr;
    assert(v3.x == -4.0);
    assert(v3.y ==  3.0);
    assert(v3.z == -2.0);
    assert(v3.w ==  1.0);

    auto v4 = -v1.stpq;
    assert(v4.x == -1.0);
    assert(v4.y ==  2.0);
    assert(v4.z == -3.0);
    assert(v4.w ==  4.0);

    Vec4f v5 = v1.xxxx;
    assert(v5.x == 1.0);
    assert(v5.y == 1.0);
    assert(v5.z == 1.0);
    assert(v5.w == 1.0);

    const v6 = v1.rrqq; // not nice to mix RGBA with STPQ, but anyway...
    assert(v6.x ==  1.0);
    assert(v6.y ==  1.0);
    assert(v6.z == -4.0);
    assert(v6.w == -4.0);

    Vec3f v7 = v1.zyz;
    assert(v7.x ==  3.0);
    assert(v7.y == -2.0);
    assert(v7.z ==  3.0);

    Vec2f v8 = v1.st;
    assert(v8.x ==  1.0);
    assert(v8.y == -2.0);

    // Another vector type; also try to create a vector of higher dimension
    auto v9 = Vec2i(9, 7);

    Vec2i v10 = v9.yx;
    assert(v10.x == 7);
    assert(v10.y == 9);

    const Vec3i v11 = v9.rgr;
    assert(v11.x == 9);
    assert(v11.y == 7);
    assert(v11.z == 9);

    immutable Vec4i v12 = v9.stts;
    assert(v12.x == 9);
    assert(v12.y == 7);
    assert(v12.z == 7);
    assert(v12.w == 9);
}


// Slicing
unittest
{
    auto v1 = Vec4f(-1.0, -2.0, -3.0, -4.0);

    auto s1 = v1[0..$];
    assert(s1.length == 4);
    assert(s1[0] == -1.0);
    assert(s1[1] == -2.0);
    assert(s1[2] == -3.0);
    assert(s1[3] == -4.0);

    const s2 = v1[0..2];
    assert(s2.length == 2);
    assert(s2[0] == -1.0);
    assert(s2[1] == -2.0);

    auto s3 = v1[1..$];
    assert(s3.length == 3);
    assert(s3[0] == -2.0);
    assert(s3[1] == -3.0);
    assert(s3[2] == -4.0);

    auto s4 = v1[];
    assert(s4.length == 4);
    assert(s4[0] == -1.0);
    assert(s4[1] == -2.0);
    assert(s4[2] == -3.0);
    assert(s4[3] == -4.0);

    // Change the vector through slices
    s3[0] = 2.0;
    assert(v1.x == -1.0);
    assert(v1.y ==  2.0);
    assert(v1.z == -3.0);
    assert(v1.w == -4.0);

    s4[3] = 4.0;
    assert(v1.x == -1.0);
    assert(v1.y ==  2.0);
    assert(v1.z == -3.0);
    assert(v1.w ==  4.0);

    // Different vector type, const
    const v2 = Vec2ul(4, 6);

    auto s5 = v2[];
    assert(s5.length == 2);
    assert(s5[0] == 4);
    assert(s5[1] == 6);

    auto s6 = v2[0..0];
    assert(s6.length == 0);

    auto s7 = v2[0..$];
    assert(s7.length == 2);
    assert(s7[0] == 4);
    assert(s7[1] == 6);

    auto s8 = v2[1..$];
    assert(s8.length == 1);
    assert(s8[0] == 6);

    // Yet another vector type, immutable
    immutable v3 = Vec3r(10.0, 20.0, 30.0);

    auto s9 = v3[1..3];
    assert(s9.length == 2);
    assert(s9[0] == 20.0);
    assert(s9[1] == 30.0);

    immutable s10 = v3[];
    assert(s10.length == 3);
    assert(s10[0] == 10.0);
    assert(s10[1] == 20.0);
    assert(s10[2] == 30.0);

    immutable s11 = v3[2..$];
    assert(s11.length == 1);
    assert(s11[0] == 30.0);
}


// Vector length and squared length
unittest
{
    enum epsilon = 1e-7;

    // 2D floating point vector
    const v2f = Vec2d(3.5, 5.5);
    assert(v2f.squaredLength == 42.5);
    assertClose(v2f.length, 6.5192024052026, epsilon);

    // 3D floating point vector
    const v3f = Vec3r(1.0, -2.0, 2.5);
    assertClose(v3f.squaredLength, 11.25, epsilon);
    assertClose(v3f.length, 3.3541019662497, epsilon);

    // 4D floating point vector
    const v4f = Vec4f(-2.2, 4.2, 10.0, -7.6);
    assertClose(v4f.squaredLength, 180.24, epsilon);
    assertClose(v4f.length, 13.425349157471, epsilon);

    // 2D non-float vector
    const v2i = Vec2i(3, 4);
    assert(v2i.squaredLength == 25);
    assert(v2i.length == 5.0);

    // 3D non-float vector
    const v3i = Vec3ul(2, 9, 3);
    assert(v3i.squaredLength == 94);
    assertClose(v3i.length, 9.6953597148327, epsilon);

    // 4D non-float vector
    const v4i = Vec4l(-3, 6, 3, -2);
    assert(v4i.squaredLength == 58);
    assertClose(v4i.length, 7.6157731058639, epsilon);
}


// Distances between vectors interpreted as points
unittest
{
    enum epsilon = 1e-7;

    const v1 = Vec4f(1.0, 2.0, 3.0, 4.0);
    const v2 = Vec4l(2, 3, 4, 5);

    assert(squaredDist(v1, v2) == 4.0);
    assert(squaredDist(v2, v1) == 4.0);
    assert(squaredDist(v1, v1) == 0.0);
    assert(squaredDist(v2, v2) == 0);

    assert(dist(v1, v2) == 2.0);
    assert(dist(v2, v1) == 2.0);
    assert(dist(v1, v1) == 0.0);
    assert(dist(v2, v2) == 0);

    // Other Vector instantiations (and using UFCS, just for the sake of it)
    auto v3 = Vec3ui(2, 3, 4);
    auto v4 = Vec3l(-2, -3, -4);

    assert(v3.squaredDist(v4) == 116);
    assertClose(v3.dist(v4), 10.770329614269, epsilon);
}


// Vector normalization
unittest
{
    enum epsilon = 1e-6;

    auto v1 = Vec4f(2.4, 3.2, 6.9, -2.1);
    auto v1n = v1.normalized;
    assertClose(v1n.x,  0.291, epsilon);
    assertClose(v1n.y,  0.388, epsilon);
    assertClose(v1n.z,  0.836625, epsilon);
    assertClose(v1n.w, -0.254625, epsilon);

    v1.normalize();
    assert(v1 == v1n);

    auto v2 = Vec3f(0.1, 0.2, 0.3);
    v2.normalize();
    assertClose(v2.x, 0.267261, epsilon);
    assertClose(v2.y, 0.534522, epsilon);
    assertClose(v2.z, 0.801784, epsilon);

    // Try with const and immutable
    const v3 = Vec3d(7.5, -9.1, 2.2);
    const v3n = v3.normalized;
    assertClose(v3n.x,  0.625217, epsilon);
    assertClose(v3n.y, -0.758597, epsilon);
    assertClose(v3n.z,  0.183397, epsilon);

    immutable v4 = Vec2r(2.2, 0.2);
    const v4n = v4.normalized;
    assertClose(v4n.x, 0.995893, epsilon);
    assertClose(v4n.y, 0.0905357, epsilon);
}


// Dot product
unittest
{
    enum epsilon = 1e-7;

    auto v1 = Vec4f(1.1, 0.2, 2.3, 1.0);
    auto v2 = Vec4f(0.4, -1.2, 3.1, -1.1);
    assertClose(dot(v1, v2), 6.23, epsilon);

    const v3 = Vec3i(3, -2, 7);
    const v4 = Vec3l(0, 4, -1);
    assert(dot(v3, v4) == -15);

    immutable v5 = Vec2d(-5.5, -1.1);
    immutable v6 = Vec2r(4.2, 4.4);
    assertClose(dot(v5, v6), -27.94, epsilon);

    // Dot product is commutative
    assert(dot(v1, v2) == dot(v2, v1));
    assert(dot(v3, v4) == dot(v4, v3));
    assert(dot(v5, v6) == dot(v6, v5));
}


// Cross product
unittest
{
    enum epsilon = 1e-7;

    // Bread-and-butter floats
    immutable v1 = Vec3f(3.4, -2.4, -2.3);
    auto v2 = Vec3f(1.1, 7.2, -6.6);
    auto v3 = cross(v1, v2);
    assertClose(v3.x, 32.4, epsilon);
    assertClose(v3.y, 19.91, epsilon);
    assertClose(v3.z, 27.12, epsilon);

    // Try with integers of different types
    const v4 = Vec3us(cast(ushort)1, cast(ushort)3, cast(ushort)4);
    const v5 = Vec3i(2, -5, 8);
    const v6 = v4.cross(v5); // UFCS... not that it looks good here
    assert(v6.x ==  44);
    assert(v6.y ==   0);
    assert(v6.z == -11);

    // Cross product is anti-commutative
    assert(cross(v1, v2) == -cross(v2, v1));
    assert(cross(v4, v5) == -cross(v5, v4));
}


// Reflect
unittest
{
    enum epsilon = 1e-5;

    auto n1 = Vec2i(0, 1);
    auto v1 = Vec2l(2, -2);
    auto r1 = reflect(v1, n1);
    assert(r1.x == 2);
    assert(r1.y == 2);
    assert(v1.length == r1.length);

    const n2 = Vec3r(-0.57735, -0.57735, -0.57735);
    immutable v2 = Vec3d(0.6, 0.0, 0.0);
    auto r2 = reflect(v2, n2);
    assertClose(r2.x,  0.2, epsilon);
    assertClose(r2.y, -0.4, epsilon);
    assertClose(r2.z, -0.4, epsilon);
    assertClose(v2.length, r2.length, epsilon);

    const n3 = Vec4f(-0.319688, -0.8525, 0.399609, 0.106563);
    immutable v3 = Vec4f(5.5, 1.1, 0.0, -3.3);
    auto r3 = reflect(v3, n3);
    assertClose(r3.x,  3.55138, epsilon);
    assertClose(r3.y, -4.09632, epsilon);
    assertClose(r3.z,  2.43577, epsilon);
    assertClose(r3.w, -2.65046, epsilon);
    assertClose(v3.length, r3.length, epsilon);
}


// Angle between vectors
unittest
{
    enum epsilon = 1e-5;

    const v1 = Vec2i(0, 1);
    const v2 = Vec2l(1, 1);
    assertClose(angle(v1, v2), 0.78539816339745, epsilon);

    immutable v3 = Vec3r( 3.2, -1.1, -0.3);
    immutable v4 = Vec3f(-0.9,  3.3,  0.0);
    assertClose(angle(v3, v4), 2.16549, epsilon);

    auto v5 = Vec4d(0.2, -0.2,  0.5,  0.1);
    auto v6 = Vec4d(0.0,  0.7, -0.6, -0.6);
    assertClose(angle(v5, v6), 2.46473, epsilon);
}


// Vector orthogonal to another vector
unittest
{
    import std.math;
    enum epsilon = 1e-7;

    const v1 = Vec3i(1, 2, 3);
    auto v2 = orthogonal(v1);
    assertClose(angle(v1, v2), PI/2, epsilon);

    const v3 = Vec3f(1.0, 2.0, 3.0);
    auto v4 = orthogonal(v3);
    assertClose(angle(v3, v4), PI/2, epsilon);

    const v5 = Vec3r(3.0, 1.0, 0.5);
    auto v6 = orthogonal(v5);
    assertClose(angle(v5, v6), PI/2, epsilon);
}


// Orthonormalization
unittest
{
    import std.math;
    enum epsilon = 1e-5;

    // 2D
    auto v2d1 = Vec2f(2.3, -1.3);
    auto v2d2 = Vec2f(0.6, 1.1);

    orthonormalize(v2d1, v2d2);

    assertClose(v2d1.length, 1.0, epsilon);
    assertClose(v2d2.length, 1.0, epsilon);

    assertClose(angle(v2d1, v2d2), PI/2.0, epsilon);

    assertClose(v2d1.x,  0.870563, epsilon);
    assertClose(v2d1.y, -0.492057, epsilon);

    assertClose(v2d2.x,  0.492057, epsilon);
    assertClose(v2d2.y,  0.870563, epsilon);

    // 3D
    auto v3d1 = Vec3d(-1.9, -1.0,  0.4);
    auto v3d2 = Vec3d(-0.2,  0.8,  1.0);
    auto v3d3 = Vec3d(-0.8,  1.1, -1.1);

    orthonormalize(v3d1, v3d2, v3d3);

    assertClose(v3d1.length, 1.0, epsilon);
    assertClose(v3d2.length, 1.0, epsilon);
    assertClose(v3d3.length, 1.0, epsilon);

    assertClose(angle(v3d1, v3d2), PI/2.0, epsilon);
    assertClose(angle(v3d1, v3d3), PI/2.0, epsilon);
    assertClose(angle(v3d2, v3d3), PI/2.0, epsilon);

    assertClose(v3d1.x, -0.869950, epsilon);
    assertClose(v3d1.y, -0.457869, epsilon);
    assertClose(v3d1.z,  0.183147, epsilon);

    assertClose(v3d2.x, -0.160454, epsilon);
    assertClose(v3d2.y,  0.613994, epsilon);
    assertClose(v3d2.z,  0.772830, epsilon);

    assertClose(v3d3.x, -0.466306, epsilon);
    assertClose(v3d3.y,  0.642937, epsilon);
    assertClose(v3d3.z, -0.607611, epsilon);

    // 4D
    auto v4d1 = Vec4r( 0.5, 0.0, 2.2, -0.3);
    auto v4d2 = Vec4d( 0.0, 0.3, 0.0,  0.0);
    auto v4d3 = Vec4f( 0.2, 0.0, 0.1,  0.8);
    auto v4d4 = Vec4d(-1.6, 0.0, 0.4,  0.4);

    orthonormalize(v4d1, v4d2, v4d3, v4d4);

    assertClose(v4d1.length, 1.0, epsilon);
    assertClose(v4d2.length, 1.0, epsilon);
    assertClose(v4d3.length, 1.0, epsilon);
    assertClose(v4d4.length, 1.0, epsilon);

    assertClose(angle(v4d1, v4d2), PI/2.0, epsilon);
    assertClose(angle(v4d1, v4d3), PI/2.0, epsilon);
    assertClose(angle(v4d1, v4d4), PI/2.0, epsilon);
    assertClose(angle(v4d2, v4d3), PI/2.0, epsilon);
    assertClose(angle(v4d2, v4d4), PI/2.0, epsilon);
    assertClose(angle(v4d3, v4d4), PI/2.0, epsilon);

    assertClose(v4d1.x,  0.219687, epsilon);
    assertClose(v4d1.y,  0.000000, epsilon);
    assertClose(v4d1.z,  0.966625, epsilon);
    assertClose(v4d1.w, -0.131812, epsilon);

    assertClose(v4d2.x,  0.000000, epsilon);
    assertClose(v4d2.y,  1.000000, epsilon);
    assertClose(v4d2.z,  0.000000, epsilon);
    assertClose(v4d2.w,  0.000000, epsilon);

    assertClose(v4d3.x,  0.2316830, epsilon);
    assertClose(v4d3.y,  0.0000000, epsilon);
    assertClose(v4d3.z,  0.0795538, epsilon);
    assertClose(v4d3.w,  0.9695330, epsilon);

    assertClose(v4d4.x, -0.947661, epsilon);
    assertClose(v4d4.y,  0.000000, epsilon);
    assertClose(v4d4.z,  0.243533, epsilon);
    assertClose(v4d4.w,  0.206474, epsilon);
}
