/**
 * Useful things for testing.
 *
 * License: MIT License, see the `LICENSE` file.
 *
 * Authors: Leandro Motta Barros.
 */

module sbxs.util.test;


/**
 * Checks whether `u` and `v` are close to each other within a tolerance of `e`.
 *
 * This implements the same "very close with tolerance $(I e)" algorithm used by
 * $(LINK2 http://www.boost.org/doc/libs/1_56_0/libs/test/doc/html/utf/testing-tools/floating_point_comparison.html, Boost Test),
 * which works nicely with both very large and very small numbers.
 *
 * TODO: Consider using `std.math.approxEqual()` instead of this. Docs say its
 *       naming and semantics will be revised, so I should probably keep my
 *       function around for some time. Anyway, using a standard alternative
 *       instead of maintaining my own code would be good.
 */
public bool isClose(U, V, E)(U u, V v, E e) @safe @nogc nothrow pure
{
    import std.math: abs;
    const d = abs(u - v);
    return d == 0 || (d / abs(u) <= e && d / abs(v) <= e);
}

/**
 * Checks whether `u` and `v` are close to each other within a tolerance of `e`,
 * using `isClose()`.
 */
public void assertClose(U, V, E)
    (U u, V v, E e, string file = __FILE__, size_t line = __LINE__) @trusted
{
    import std.string: format;

    assert(
        isClose(u, v, e),
        format(
            "assertClose failure at %s:%s: %s and %s are not within %s tolerance",
            file, line, u, v, e));
}

///
unittest
{
    import core.exception;
    import std.exception;

    assertClose(0.001, 0.001001, 0.001);
    assertClose(0.001001, 0.001, 0.001);
    assertThrown!AssertError(assertClose(0.001, 0.001001, 0.0001));
    assertThrown!AssertError(assertClose(0.001001, 0.001, 0.0001));

    assertClose(10.0e4, 10.01e4, 0.001);
    assertClose(10.01e4, 10.0e4, 0.001);
    assertThrown!AssertError(assertClose(10.0e4, 10.01e4, 0.0001));
    assertThrown!AssertError(assertClose(10.01e4, 10.0e4, 0.0001));
}


// assertClose() corner cases
unittest
{
    assertClose(0.0, 0.0, 1e-10); // should probably use `assertSmall` instead
    assertClose(0.2, 0.2, 1e-10);
}


/**
 * Checks whether `v` is "small enough"; useful for testing if a value is
 * equals to zero, within a tolerance `e`.
 *
 * The algorithm used by `assertClose()` is not appropriate for testing if a
 * value is (approximately) zero. Use this test instead.
 */
public void assertSmall(V, E)
    (V v, E e, string file = __FILE__, size_t line = __LINE__)
{
    import std.math;
    import std.string;

    const d = abs(v);

    assert(d <= e, format("assertSmall failure at %s:%s: %s is not small "
                          "enough (tolerance = %s)",
                          file, line, v, e));
}

///
unittest
{
    import core.exception;
    import std.exception;

    assertSmall(0.0000001, 1e-7);
    assertSmall(-0.0000001, 1e-7);
    assertThrown!AssertError(assertSmall(0.000001, 1e-7));
    assertThrown!AssertError(assertSmall(-0.000001, 1e-7));
}


/// Checks whether `v` is between `a` and `b` (closed interval at both ends).
public void assertBetween(V, L, H)
    (V v, L a, H b, string file = __FILE__, size_t line = __LINE__)
in
{
    assert(a <= b);
}
body
{
    import std.string;

    assert(
        v >= a && v <= b,
        format(
            "assertBetween failure at %s:%s: %s is not between %s and %s",
            file, line, v, a, b));
}

///
unittest
{
    import core.exception;
    import std.exception;

    assertBetween(2, 1, 3);
    2.assertBetween(1, 3);
    2.0.assertBetween(1.0, 3.0);
    byte(2).assertBetween(byte(1), byte(3));

    (-1).assertBetween(-2, 5);
    (-3).assertBetween(-5, -2);
    5.assertBetween(5, 5);
    5.assertBetween(0, 5);
    5.assertBetween(5, 15);

    assertThrown!AssertError(5.assertBetween(1, 2));
    assertThrown!AssertError(1.2.assertBetween(1.201, 1.3));
}
