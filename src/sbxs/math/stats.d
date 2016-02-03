/**
 * Routines for computing simple statistics.
 *
 * Also, my first attempt to write some range-based code -- with a feeling of "I
 * think I should have tried harder".
 *
 * Authors: Leandro Motta Barros.
 */

module sbxs.math.stats;

import std.array;
import std.traits;
import std.range;


/**
 * Computes and returns the sum of the numbers in a range.
 *
 * Parameters:
 *     data = The range with the desired numbers.
 *
 * Returns: The sum of all numbers in `data`. It has the same type as the
 *     elements of `data`.
 */
public auto sum(InputRange)(InputRange data)
    if (isInputRange!InputRange && isNumeric!(typeof(data.front)))
{
    typeof(data.front) sum = 0;

    for (; !data.empty; data.popFront())
        sum += data.front;

    return sum;
}

///
unittest
{
    double[] data1 = [ 3.0, -1.0, 0.0, 2.0, 2.0, 1.0, -5.0, 7.0 ];
    assert(data1.sum() == 9.0);

    float[] data2 = [ ];
    assert(data2.sum() == 0.0);

    // Good and old Fibonacci Sequence
    assert(recurrence!("a[n-1] + a[n-2]")(1, 1).take(10).sum() == 143);
}


/**
 * Computes and returns the mean of a collection of numbers.
 *
 * Parameters:
 *     data = The range with the desired numbers.
 *
 * Returns:
 *     The mean of `data`. If `data` is an empty range, returns `double.nan`.
 */
public double mean(InputRange)(InputRange data)
    if (isInputRange!InputRange && isNumeric!(typeof(data.front)))
{
    double sum = 0.0;
    auto n = 0;

    for (; !data.empty; data.popFront(), ++n)
        sum += data.front;

    if (n == 0)
        return double.nan;
    else
        return sum / n;
}

///
unittest
{
    import std.math: isNaN;

    double[] data1 = [ 3.0, -1.0, 0.0, 2.0, 2.0, 1.0, -5.0, 7.0 ];
    assert(data1.mean() == 1.125);

    float[] data2 = [ ];
    assert(data2.mean().isNaN);

    // Good and old Fibonacci Sequence
    assert(recurrence!("a[n-1] + a[n-2]")(1, 1).take(10).mean() == 14.3);
}


/**
 * Computes and returns the variance of a collection of numbers.
 *
 * Parameters:
 *     data = The range with the desired numbers.
 *     mean = The mean of `data`, just in case you already have it.
 *
 * Returns:
 *     The variance of `data`. If `data` is an empty range, returns `double.nan`.
 */
public double variance(InputRange)(InputRange data, double mean)
    if (isInputRange!InputRange && isNumeric!(typeof(data.front)))
{
    double acc = 0.0;
    auto n = 0;

    for (; !data.empty; data.popFront(), ++n)
    {
        const v = data.front - mean;
        acc += v * v;
    }

    if (n == 0)
        return double.nan;
    else
        return acc / n;
}

/// Ditto
public double variance(InputRange)(InputRange data)
    if (isInputRange!InputRange && isNumeric!(typeof(data.front)))
{
    auto mean = data.mean();
    return data.variance(mean);
}

///
unittest
{
    import sbxs.util.test;
    import std.math: isNaN;

    enum epsilon = 1e-9;

    double[] data1 = [ 3.0, -1.0, 0.0, 2.0, 2.0, 1.0, -5.0, 7.0 ];
    assertClose(data1.variance(), 10.359375, epsilon);

    float[] data2 = [ ];
    assert(data2.variance().isNaN);

    // Good and old Fibonacci Sequence
    assertClose(
        recurrence!("a[n-1] + a[n-2]")(1, 1).take(10).variance(),
        285.01,
        epsilon);
}


/**
 * Computes and returns the standard deviation of the numbers in a range.
 *
 * Parameters:
 *     data = The range with the desired numbers.
 *     mean = The mean of `data`, just in case you already have it.
 *
 * Returns:
 *     The standard deviation `data`. If `data` is an empty range, returns
 *     `double.nan`.
 */
public double standardDeviation(InputRange)(InputRange data)
    if (isInputRange!InputRange && isNumeric!(typeof(data.front)))
{
    import std.math: sqrt;
    return sqrt(data.variance);
}

public double standardDeviation(InputRange)(InputRange data, double mean)
    if (isInputRange!InputRange && isNumeric!(typeof(data.front)))
{
    import std.math: sqrt;
    return sqrt(data.variance(mean));
}

///
unittest
{
    import sbxs.util.test;
    import std.math: isNaN;

    enum epsilon = 1e-8;

    double[] data1 = [ 3.0, -1.0, 0.0, 2.0, 2.0, 1.0, -5.0, 7.0 ];
    assertClose(data1.standardDeviation(), 3.21859829, epsilon);

    float[] data2 = [ ];
    assert(data2.standardDeviation().isNaN);

    // Good and old Fibonacci Sequence
    assertClose(
        recurrence!("a[n-1] + a[n-2]")(1, 1).take(10).standardDeviation(),
        16.8822391,
        epsilon);

    // Try the more efficient version which also accepts the mean
    assertClose(data1.standardDeviation(1.125), 3.21859829, epsilon);
}
