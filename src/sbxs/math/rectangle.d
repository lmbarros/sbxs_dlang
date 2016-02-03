/**
 * Rectangles.
 *
 * License: MIT License, see the `LICENSE` file.
 *
 * Authors: Leandro Motta Barros.
 */

module sbxs.math.rectangle;

import std.traits;
import sbxs.math.vector;

version(unittest)
{
    import sbxs.util.test;
}


/**
 * A rectangle. One of those 2D shapes, you know.
 *
 * The rectangle spans from `x` to `x + width` and `y` to `y + height`.
 *
 * Parameters:
 *     T = The type uses to store the rectangle coordinates.
 *
 * TODO: Make members private; make sure width and height are non-negative. Test
 *     degenerate cases.
 */
public struct Rectangle(T)
    if (isNumeric!T)
{
    /// Constructs the `Rectangle` from the given coordinates and dimensions.
    public this(T x, T y, T width, T height)
    {
        this.x = x;
        this.y = y;
        this.width = width;
        this.height = height;
    }

    /// Returns the `Rectangle`'s corner.
    public @property Vector!(T, 2) corner() const
    {
        return Vector!(T, 2)(x, y);
    }

    /// Returns the `Rectangle`'s dimensions.
    public @property Vector!(T, 2) size() const
    {
        return Vector!(T, 2)(width, height);
    }

    /// Returns a `Rectangle` just like this one, but translated to the origin.
    public @property Rectangle atOrigin() @nogc nothrow pure const
    {
        return Rectangle(0, 0, width, height);
    }

    ///
    unittest
    {
        const rect = Rectangle!int(-10, 123, 50, 51);
        const rectAtOrigin = rect.atOrigin();
        assert(rectAtOrigin.x == 0);
        assert(rectAtOrigin.y == 0);
        assert(rectAtOrigin.width == 50);
        assert(rectAtOrigin.height == 51);
    }

    /// The $(I x) coordinate of this rectangle's corner.
    public T x;

    /// The $(I y) coordinate of this Rectangle's corner.
    public T y;

    /// The rectangle width.
    public T width;

    /// The rectangle height.
    public T height;
}


/**
 * Checks if a given point is inside a given rectangle.
 *
 * The `Rectangle` is considered closed in the `x` and `y` sides and open in the
 * `x + width` and `y + height` sides.
 */
public bool inside(T)(Vector!(T,2) point,
                      Rectangle!T rect) pure nothrow @safe @nogc
{
    return point.x >= rect.x
        && point.x < rect.x + rect.width
        && point.y >= rect.y
        && point.y < rect.y + rect.height;
}




// -----------------------------------------------------------------------------
// Handy aliases
// -----------------------------------------------------------------------------

/// Bunch of aliases for commonly used rectangle types.
public alias Rectf = Rectangle!float;
public alias Rectd = Rectangle!double; /// Ditto
public alias Rectr = Rectangle!real; /// Ditto
public alias Rects = Rectangle!short; /// Ditto
public alias Recti = Rectangle!int; /// Ditto
public alias Rectl = Rectangle!long; /// Ditto


// -----------------------------------------------------------------------------
// Unit tests
// -----------------------------------------------------------------------------

// Tests the constructor.
unittest
{
    auto rect = Rectd(1.0, 2.0, 10.0, 20.0);

    assert(rect.x == 1.0);
    assert(rect.y == 2.0);
    assert(rect.width == 10.0);
    assert(rect.height == 20.0);
}


// Tests `corner` and `size`
unittest
{
    const rect = Rectf(-1.0, -2.0, 1.0, 3.0);

    assert(rect.corner.x == -1.0);
    assert(rect.corner.y == -2.0);
    assert(rect.size.x == 1.0);
    assert(rect.size.y == 3.0);
}


// Tests `inside()`: the simple cases.
unittest
{
    auto rect = Rectf(-1.0, -2.0, 1.0, 3.0);

    assert(Vec2f(-0.8, 0.5).inside(rect));
    assert(inside(Vec2f(-0.8, -0.5), rect));
    assert(inside(Vec2f(-0.5, 0.0), rect));
    assert(!inside(Vec2f(-1.1, 0.0), rect));
    assert(!inside(Vec2f(-0.5, -2.1), rect));
}


// Tests `inside()`: the corner cases
unittest
{
    const rect = Rectf(-1.0, -2.0, 1.0, 3.0);

    // The literally corner cases
    assert(inside(Vec2f(-1.0, -2.0), rect));
    assert(!inside(Vec2f(-1.0,  1.0), rect));
    assert(!inside(Vec2f( 0.0,  1.0), rect));
    assert(!inside(Vec2f( 0.0, -2.0), rect));

    // Other, not so literal, corner cases
    assert(inside(Vec2f(-1.00,  0.99), rect));
    assert(inside(Vec2f(-0.01, -1.99), rect));
}
