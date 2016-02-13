/**
 * OpenSimplex noise in 2D, 3D and 4D.
 *
 * "Visually axis-decorrelated coherent noise", similar to Perlin's
 * simplex noise, but unencumbered by patents.
 *
 * License: MIT License, see the `LICENSE` file.
 *
 * Authors: Original public domain Java code by Kurt Spencer. Translated to D by
 *     Leandro Motta Barros.
 *
 * See_Also:
 *     https://gist.github.com/KdotJPG/b1270127455a94ac5d19,
 *     http://uniblock.tumblr.com/post/97868843242/noise,
 *     http://uniblock.tumblr.com/post/99279694832/2d-and-4d-noise-too
 */

module sbxs.noise.open_simplex_noise;

import std.traits: isFloatingPoint;

version (unittest)
{
    import sbxs.util.test;
}


/**
 * Generates noise in 2, 3 and 4 dimensions, using the Open Simplex Noise
 * technique.
 */
public struct OpenSimplexNoiseGenerator(T)
    if (isFloatingPoint!T)
{
    import std.math: sqrt;

    /**
     * Constructs the `OpenSimplexNoiseGenerator`.
     *
     * Parameters:
     *     seed = The seed used to initialize the internal pseudo random
     *         number generator responsible for the randomizing the noise
     *         pattern.
     *
     * TODO:
     *    Use `sbxs.rand.knuth_lcg.KnuthLCG`.
     */
    public this(long seed)
    {
        // Initializes the struct using a permutation array generated from a
        // 64-bit seed.  Generates a proper permutation (i.e. doesn't merely
        // perform N successive pair swaps on a base array) Uses a simple 64-bit
        // LCG.
        short[256] source;
        foreach (short i; 0..256)
            source[i] = i;

        seed = seed * 6364136223846793005L + 1442695040888963407L;
        seed = seed * 6364136223846793005L + 1442695040888963407L;
        seed = seed * 6364136223846793005L + 1442695040888963407L;

        for (auto i = 255; i >= 0; --i)
        {
            seed = seed * 6364136223846793005L + 1442695040888963407L;
            int r = (seed + 31) % (i + 1);
            if (r < 0)
                r += (i + 1);
            _perm[i] = source[r];
            _permGradIndex3D[i] = (_perm[i] % (_gradients3D.length / 3)) * 3;
            source[r] = source[i];
        }
    }

    /**
     * Computes and returns 2D noise.
     *
     * Parameters:
     *     x = The first coordinate from where noise will be taken.
     *     y = The second coordinate from where noise will be taken.
     *
     * Returns: The noise at the requested coordinates.
     */
    public T noise(T x, T y) const
    {
        // Place input coordinates onto grid
        const T stretchOffset = (x + y) * _stretchConst2D;
        const T xs = x + stretchOffset;
        const T ys = y + stretchOffset;

        // Floor to get grid coordinates of rhombus (stretched square)
        // super-cell origin
        int xsb = fastFloor(xs);
        int ysb = fastFloor(ys);

        // Skew out to get actual coordinates of rhombus origin. We'll need
        // these later
        const T squishOffset = (xsb + ysb) * _squishConst2D;
        const T xb = xsb + squishOffset;
        const T yb = ysb + squishOffset;

        // Compute grid coordinates relative to rhombus origin
        const T xins = xs - xsb;
        const T yins = ys - ysb;

        // Sum those together to get a value that determines which region we're in
        const T inSum = xins + yins;

        // Positions relative to origin point
        T dx0 = x - xb;
        T dy0 = y - yb;

        // We'll be defining these inside the next block and using them afterwards
        T dx_ext, dy_ext;
        int xsv_ext, ysv_ext;

        T value = 0;

        // Contribution (1,0)
        const T dx1 = dx0 - 1 - _squishConst2D;
        const T dy1 = dy0 - 0 - _squishConst2D;
        T attn1 = 2 - dx1 * dx1 - dy1 * dy1;

        if (attn1 > 0)
        {
            attn1 *= attn1;
            value += attn1 * attn1 * extrapolate(xsb + 1, ysb + 0, dx1, dy1);
        }

        // Contribution (0,1)
        const T dx2 = dx0 - 0 - _squishConst2D;
        const T dy2 = dy0 - 1 - _squishConst2D;
        T attn2 = 2 - dx2 * dx2 - dy2 * dy2;
        if (attn2 > 0)
        {
            attn2 *= attn2;
            value += attn2 * attn2 * extrapolate(xsb + 0, ysb + 1, dx2, dy2);
        }

        if (inSum <= 1)
        {
            // We're inside the triangle (2-Simplex) at (0,0)
            const T zins = 1 - inSum;
            if (zins > xins || zins > yins)
            {
                // (0,0) is one of the closest two triangular vertices
                if (xins > yins)
                {
                    xsv_ext = xsb + 1;
                    ysv_ext = ysb - 1;
                    dx_ext = dx0 - 1;
                    dy_ext = dy0 + 1;
                }
                else
                {
                    xsv_ext = xsb - 1;
                    ysv_ext = ysb + 1;
                    dx_ext = dx0 + 1;
                    dy_ext = dy0 - 1;
                }
            }
            else
            {
                // (1,0) and (0,1) are the closest two vertices
                xsv_ext = xsb + 1;
                ysv_ext = ysb + 1;
                dx_ext = dx0 - 1 - 2 * _squishConst2D;
                dy_ext = dy0 - 1 - 2 * _squishConst2D;
            }
        }
        else
        {
            // We're inside the triangle (2-Simplex) at (1,1)
            const T zins = 2 - inSum;
            if (zins < xins || zins < yins)
            {
                // (0,0) is one of the closest two triangular vertices
                if (xins > yins)
                {
                    xsv_ext = xsb + 2;
                    ysv_ext = ysb + 0;
                    dx_ext = dx0 - 2 - 2 * _squishConst2D;
                    dy_ext = dy0 + 0 - 2 * _squishConst2D;
                }
                else
                {
                    xsv_ext = xsb + 0;
                    ysv_ext = ysb + 2;
                    dx_ext = dx0 + 0 - 2 * _squishConst2D;
                    dy_ext = dy0 - 2 - 2 * _squishConst2D;
                }
            }
            else
            {
                // (1,0) and (0,1) are the closest two vertices
                dx_ext = dx0;
                dy_ext = dy0;
                xsv_ext = xsb;
                ysv_ext = ysb;
            }
            xsb += 1;
            ysb += 1;
            dx0 = dx0 - 1 - 2 * _squishConst2D;
            dy0 = dy0 - 1 - 2 * _squishConst2D;
        }

        // Contribution (0,0) or (1,1)
        T attn0 = 2 - dx0 * dx0 - dy0 * dy0;
        if (attn0 > 0)
        {
            attn0 *= attn0;
            value += attn0 * attn0 * extrapolate(xsb, ysb, dx0, dy0);
        }

        // Extra Vertex
        T attn_ext = 2 - dx_ext * dx_ext - dy_ext * dy_ext;
        if (attn_ext > 0)
        {
            attn_ext *= attn_ext;
            value += attn_ext * attn_ext * extrapolate(xsv_ext, ysv_ext, dx_ext, dy_ext);
        }

        return value / _normConst2D;
    }

    /**
     * Computes and returns 3D noise.
     *
     * Parameters:
     *     x = The first coordinate from where noise will be taken.
     *     y = The second coordinate from where noise will be taken.
     *     z = The third coordinate from where noise will be taken.
     *
     * Returns: The noise at the requested coordinates. Normally, will be in the
     *     [0, 1] range, but may occasionally be slightly out of this range. Do
     *     your own clamping if you need to be sure.
     */
    public T noise(T x, T y, T z) const
    {
        // Place input coordinates on simplectic honeycomb
        const T stretchOffset = (x + y + z) * _stretchConst3D;
        const T xs = x + stretchOffset;
        const T ys = y + stretchOffset;
        const T zs = z + stretchOffset;

        // Floor to get simplectic honeycomb coordinates of rhombohedron
        // (stretched cube) super-cell origin
        const xsb = fastFloor(xs);
        const ysb = fastFloor(ys);
        const zsb = fastFloor(zs);

        // Skew out to get actual coordinates of rhombohedron origin. We'll need
        // these later
        const T squishOffset = (xsb + ysb + zsb) * _squishConst3D;
        const T xb = xsb + squishOffset;
        const T yb = ysb + squishOffset;
        const T zb = zsb + squishOffset;

        // Compute simplectic honeycomb coordinates relative to rhombohedral
        // origin
        const T xins = xs - xsb;
        const T yins = ys - ysb;
        const T zins = zs - zsb;

        // Sum those together to get a value that determines which region we're in
        const T inSum = xins + yins + zins;

        // Positions relative to origin point
        T dx0 = x - xb;
        T dy0 = y - yb;
        T dz0 = z - zb;

        // We'll be defining these inside the next block and using them afterwards
        T dx_ext0, dy_ext0, dz_ext0;
        T dx_ext1, dy_ext1, dz_ext1;
        int xsv_ext0, ysv_ext0, zsv_ext0;
        int xsv_ext1, ysv_ext1, zsv_ext1;

        T value = 0;

        if (inSum <= 1)
        {
            // We're inside the tetrahedron (3-Simplex) at (0,0,0)

            // Determine which two of (0,0,1), (0,1,0), (1,0,0) are closest
            byte aPoint = 0x01;
            T aScore = xins;
            byte bPoint = 0x02;
            T bScore = yins;

            if (aScore >= bScore && zins > bScore)
            {
                bScore = zins;
                bPoint = 0x04;
            }
            else if (aScore < bScore && zins > aScore)
            {
                aScore = zins;
                aPoint = 0x04;
            }

            // Now we determine the two lattice points not part of the
            // tetrahedron that may contribute.  This depends on the closest two
            // tetrahedral vertices, including (0,0,0)
            const T wins = 1 - inSum;
            if (wins > aScore || wins > bScore)
            {
                // (0,0,0) is one of the closest two tetrahedral vertices

                // Our other closest vertex is the closest out of a and b
                byte c = (bScore > aScore ? bPoint : aPoint);

                if ((c & 0x01) == 0)
                {
                    xsv_ext0 = xsb - 1;
                    xsv_ext1 = xsb;
                    dx_ext0 = dx0 + 1;
                    dx_ext1 = dx0;
                }
                else
                {
                    xsv_ext0 = xsv_ext1 = xsb + 1;
                    dx_ext0 = dx_ext1 = dx0 - 1;
                }

                if ((c & 0x02) == 0)
                {
                    ysv_ext0 = ysv_ext1 = ysb;
                    dy_ext0 = dy_ext1 = dy0;
                    if ((c & 0x01) == 0)
                    {
                        ysv_ext1 -= 1;
                        dy_ext1 += 1;
                    }
                    else
                    {
                        ysv_ext0 -= 1;
                        dy_ext0 += 1;
                    }
                }
                else
                {
                    ysv_ext0 = ysv_ext1 = ysb + 1;
                    dy_ext0 = dy_ext1 = dy0 - 1;
                }

                if ((c & 0x04) == 0)
                {
                    zsv_ext0 = zsb;
                    zsv_ext1 = zsb - 1;
                    dz_ext0 = dz0;
                    dz_ext1 = dz0 + 1;
                }
                else
                {
                    zsv_ext0 = zsv_ext1 = zsb + 1;
                    dz_ext0 = dz_ext1 = dz0 - 1;
                }
            }
            else
            {
                // (0,0,0) is not one of the closest two tetrahedral vertices

                // Our two extra vertices are determined by the closest two
                const byte c = aPoint | bPoint;

                if ((c & 0x01) == 0)
                {
                    xsv_ext0 = xsb;
                    xsv_ext1 = xsb - 1;
                    dx_ext0 = dx0 - 2 * _squishConst3D;
                    dx_ext1 = dx0 + 1 - _squishConst3D;
                }
                else
                {
                    xsv_ext0 = xsv_ext1 = xsb + 1;
                    dx_ext0 = dx0 - 1 - 2 * _squishConst3D;
                    dx_ext1 = dx0 - 1 - _squishConst3D;
                }

                if ((c & 0x02) == 0)
                {
                    ysv_ext0 = ysb;
                    ysv_ext1 = ysb - 1;
                    dy_ext0 = dy0 - 2 * _squishConst3D;
                    dy_ext1 = dy0 + 1 - _squishConst3D;
                }
                else
                {
                    ysv_ext0 = ysv_ext1 = ysb + 1;
                    dy_ext0 = dy0 - 1 - 2 * _squishConst3D;
                    dy_ext1 = dy0 - 1 - _squishConst3D;
                }

                if ((c & 0x04) == 0)
                {
                    zsv_ext0 = zsb;
                    zsv_ext1 = zsb - 1;
                    dz_ext0 = dz0 - 2 * _squishConst3D;
                    dz_ext1 = dz0 + 1 - _squishConst3D;
                }
                else
                {
                    zsv_ext0 = zsv_ext1 = zsb + 1;
                    dz_ext0 = dz0 - 1 - 2 * _squishConst3D;
                    dz_ext1 = dz0 - 1 - _squishConst3D;
                }
            }

            // Contribution (0,0,0)
            T attn0 = 2 - dx0 * dx0 - dy0 * dy0 - dz0 * dz0;
            if (attn0 > 0)
            {
                attn0 *= attn0;
                value += attn0 * attn0 * extrapolate(
                    xsb + 0, ysb + 0, zsb + 0, dx0, dy0, dz0);
            }

            // Contribution (1,0,0)
            const T dx1 = dx0 - 1 - _squishConst3D;
            const T dy1 = dy0 - 0 - _squishConst3D;
            const T dz1 = dz0 - 0 - _squishConst3D;
            T attn1 = 2 - dx1 * dx1 - dy1 * dy1 - dz1 * dz1;
            if (attn1 > 0)
            {
                attn1 *= attn1;
                value += attn1 * attn1 * extrapolate(
                    xsb + 1, ysb + 0, zsb + 0, dx1, dy1, dz1);
            }

            // Contribution (0,1,0)
            const T dx2 = dx0 - 0 - _squishConst3D;
            const T dy2 = dy0 - 1 - _squishConst3D;
            const T dz2 = dz1;
            T attn2 = 2 - dx2 * dx2 - dy2 * dy2 - dz2 * dz2;
            if (attn2 > 0)
            {
                attn2 *= attn2;
                value += attn2 * attn2 * extrapolate(
                    xsb + 0, ysb + 1, zsb + 0, dx2, dy2, dz2);
            }

            // Contribution (0,0,1)
            const T dx3 = dx2;
            const T dy3 = dy1;
            const T dz3 = dz0 - 1 - _squishConst3D;
            T attn3 = 2 - dx3 * dx3 - dy3 * dy3 - dz3 * dz3;
            if (attn3 > 0)
            {
                attn3 *= attn3;
                value += attn3 * attn3 * extrapolate(
                    xsb + 0, ysb + 0, zsb + 1, dx3, dy3, dz3);
            }
        }
        else if (inSum >= 2)
        {
            // We're inside the tetrahedron (3-Simplex) at (1,1,1)

            // Determine which two tetrahedral vertices are the closest, out
            // of (1,1,0), (1,0,1), (0,1,1) but not (1,1,1)
            byte aPoint = 0x06;
            T aScore = xins;
            byte bPoint = 0x05;
            T bScore = yins;
            if (aScore <= bScore && zins < bScore)
            {
                bScore = zins;
                bPoint = 0x03;
            }
            else if (aScore > bScore && zins < aScore)
            {
                aScore = zins;
                aPoint = 0x03;
            }

            // Now we determine the two lattice points not part of the
            // tetrahedron that may contribute.  This depends on the closest two
            // tetrahedral vertices, including (1,1,1)
            const T wins = 3 - inSum;
            if (wins < aScore || wins < bScore)
            {
                // (1,1,1) is one of the closest two tetrahedral vertices

                // Our other closest vertex is the closest out of a and b
                const byte c = (bScore < aScore ? bPoint : aPoint);

                if ((c & 0x01) != 0)
                {
                    xsv_ext0 = xsb + 2;
                    xsv_ext1 = xsb + 1;
                    dx_ext0 = dx0 - 2 - 3 * _squishConst3D;
                    dx_ext1 = dx0 - 1 - 3 * _squishConst3D;
                }
                else
                {
                    xsv_ext0 = xsv_ext1 = xsb;
                    dx_ext0 = dx_ext1 = dx0 - 3 * _squishConst3D;
                }

                if ((c & 0x02) != 0)
                {
                    ysv_ext0 = ysv_ext1 = ysb + 1;
                    dy_ext0 = dy_ext1 = dy0 - 1 - 3 * _squishConst3D;
                    if ((c & 0x01) != 0)
                    {
                        ysv_ext1 += 1;
                        dy_ext1 -= 1;
                    }
                    else
                    {
                        ysv_ext0 += 1;
                        dy_ext0 -= 1;
                    }
                }
                else
                {
                    ysv_ext0 = ysv_ext1 = ysb;
                    dy_ext0 = dy_ext1 = dy0 - 3 * _squishConst3D;
                }

                if ((c & 0x04) != 0)
                {
                    zsv_ext0 = zsb + 1;
                    zsv_ext1 = zsb + 2;
                    dz_ext0 = dz0 - 1 - 3 * _squishConst3D;
                    dz_ext1 = dz0 - 2 - 3 * _squishConst3D;
                }
                else
                {
                    zsv_ext0 = zsv_ext1 = zsb;
                    dz_ext0 = dz_ext1 = dz0 - 3 * _squishConst3D;
                }
            }
            else
            {
                // (1,1,1) is not one of the closest two tetrahedral vertices

                // Our two extra vertices are determined by the closest two
                const byte c = aPoint & bPoint;

                if ((c & 0x01) != 0)
                {
                    xsv_ext0 = xsb + 1;
                    xsv_ext1 = xsb + 2;
                    dx_ext0 = dx0 - 1 - _squishConst3D;
                    dx_ext1 = dx0 - 2 - 2 * _squishConst3D;
                }
                else
                {
                    xsv_ext0 = xsv_ext1 = xsb;
                    dx_ext0 = dx0 - _squishConst3D;
                    dx_ext1 = dx0 - 2 * _squishConst3D;
                }

                if ((c & 0x02) != 0)
                {
                    ysv_ext0 = ysb + 1;
                    ysv_ext1 = ysb + 2;
                    dy_ext0 = dy0 - 1 - _squishConst3D;
                    dy_ext1 = dy0 - 2 - 2 * _squishConst3D;
                }
                else
                {
                    ysv_ext0 = ysv_ext1 = ysb;
                    dy_ext0 = dy0 - _squishConst3D;
                    dy_ext1 = dy0 - 2 * _squishConst3D;
                }

                if ((c & 0x04) != 0)
                {
                    zsv_ext0 = zsb + 1;
                    zsv_ext1 = zsb + 2;
                    dz_ext0 = dz0 - 1 - _squishConst3D;
                    dz_ext1 = dz0 - 2 - 2 * _squishConst3D;
                }
                else
                {
                    zsv_ext0 = zsv_ext1 = zsb;
                    dz_ext0 = dz0 - _squishConst3D;
                    dz_ext1 = dz0 - 2 * _squishConst3D;
                }
            }

            // Contribution (1,1,0)
            const T dx3 = dx0 - 1 - 2 * _squishConst3D;
            const T dy3 = dy0 - 1 - 2 * _squishConst3D;
            const T dz3 = dz0 - 0 - 2 * _squishConst3D;
            T attn3 = 2 - dx3 * dx3 - dy3 * dy3 - dz3 * dz3;
            if (attn3 > 0)
            {
                attn3 *= attn3;
                value += attn3 * attn3 * extrapolate(
                    xsb + 1, ysb + 1, zsb + 0, dx3, dy3, dz3);
            }

            // Contribution (1,0,1)
            const T dx2 = dx3;
            const T dy2 = dy0 - 0 - 2 * _squishConst3D;
            const T dz2 = dz0 - 1 - 2 * _squishConst3D;
            T attn2 = 2 - dx2 * dx2 - dy2 * dy2 - dz2 * dz2;
            if (attn2 > 0)
            {
                attn2 *= attn2;
                value += attn2 * attn2 * extrapolate(
                    xsb + 1, ysb + 0, zsb + 1, dx2, dy2, dz2);
            }

            // Contribution (0,1,1)
            const T dx1 = dx0 - 0 - 2 * _squishConst3D;
            const T dy1 = dy3;
            const T dz1 = dz2;
            T attn1 = 2 - dx1 * dx1 - dy1 * dy1 - dz1 * dz1;
            if (attn1 > 0)
            {
                attn1 *= attn1;
                value += attn1 * attn1 * extrapolate(
                    xsb + 0, ysb + 1, zsb + 1, dx1, dy1, dz1);
            }

            // Contribution (1,1,1)
            dx0 = dx0 - 1 - 3 * _squishConst3D;
            dy0 = dy0 - 1 - 3 * _squishConst3D;
            dz0 = dz0 - 1 - 3 * _squishConst3D;
            T attn0 = 2 - dx0 * dx0 - dy0 * dy0 - dz0 * dz0;
            if (attn0 > 0)
            {
                attn0 *= attn0;
                value += attn0 * attn0 * extrapolate(
                    xsb + 1, ysb + 1, zsb + 1, dx0, dy0, dz0);
            }
        }
        else
        {
            // We're inside the octahedron (Rectified 3-Simplex) in between
            T aScore;
            byte aPoint;
            bool aIsFurtherSide;
            T bScore;
            byte bPoint;
            bool bIsFurtherSide;

            // Decide between point (0,0,1) and (1,1,0) as closest
            const p1 = xins + yins;
            if (p1 > 1)
            {
                aScore = p1 - 1;
                aPoint = 0x03;
                aIsFurtherSide = true;
            }
            else
            {
                aScore = 1 - p1;
                aPoint = 0x04;
                aIsFurtherSide = false;
            }

            // Decide between point (0,1,0) and (1,0,1) as closest
            const T p2 = xins + zins;
            if (p2 > 1)
            {
                bScore = p2 - 1;
                bPoint = 0x05;
                bIsFurtherSide = true;
            }
            else
            {
                bScore = 1 - p2;
                bPoint = 0x02;
                bIsFurtherSide = false;
            }

            // The closest out of the two (1,0,0) and (0,1,1) will replace
            // the furthest out of the two decided above, if closer
            const T p3 = yins + zins;
            if (p3 > 1)
            {
                const T score = p3 - 1;
                if (aScore <= bScore && aScore < score)
                {
                    aScore = score;
                    aPoint = 0x06;
                    aIsFurtherSide = true;
                }
                else if (aScore > bScore && bScore < score)
                {
                    bScore = score;
                    bPoint = 0x06;
                    bIsFurtherSide = true;
                }
            }
            else
            {
                const T score = 1 - p3;
                if (aScore <= bScore && aScore < score)
                {
                    aScore = score;
                    aPoint = 0x01;
                    aIsFurtherSide = false;
                }
                else if (aScore > bScore && bScore < score)
                {
                    bScore = score;
                    bPoint = 0x01;
                    bIsFurtherSide = false;
                }
            }

            // Where each of the two closest points are determines how the
            // extra two vertices are calculated
            if (aIsFurtherSide == bIsFurtherSide)
            {
                if (aIsFurtherSide)
                {
                    // Both closest points on (1,1,1) side

                    // One of the two extra points is (1,1,1)
                    dx_ext0 = dx0 - 1 - 3 * _squishConst3D;
                    dy_ext0 = dy0 - 1 - 3 * _squishConst3D;
                    dz_ext0 = dz0 - 1 - 3 * _squishConst3D;
                    xsv_ext0 = xsb + 1;
                    ysv_ext0 = ysb + 1;
                    zsv_ext0 = zsb + 1;

                    // Other extra point is based on the shared axis
                    const byte c = aPoint & bPoint;
                    if ((c & 0x01) != 0)
                    {
                        dx_ext1 = dx0 - 2 - 2 * _squishConst3D;
                        dy_ext1 = dy0 - 2 * _squishConst3D;
                        dz_ext1 = dz0 - 2 * _squishConst3D;
                        xsv_ext1 = xsb + 2;
                        ysv_ext1 = ysb;
                        zsv_ext1 = zsb;
                    }
                    else if ((c & 0x02) != 0)
                    {
                        dx_ext1 = dx0 - 2 * _squishConst3D;
                        dy_ext1 = dy0 - 2 - 2 * _squishConst3D;
                        dz_ext1 = dz0 - 2 * _squishConst3D;
                        xsv_ext1 = xsb;
                        ysv_ext1 = ysb + 2;
                        zsv_ext1 = zsb;
                    }
                    else
                    {
                        dx_ext1 = dx0 - 2 * _squishConst3D;
                        dy_ext1 = dy0 - 2 * _squishConst3D;
                        dz_ext1 = dz0 - 2 - 2 * _squishConst3D;
                        xsv_ext1 = xsb;
                        ysv_ext1 = ysb;
                        zsv_ext1 = zsb + 2;
                    }
                }
                else
                {
                    // Both closest points on (0,0,0) side

                    // One of the two extra points is (0,0,0)
                    dx_ext0 = dx0;
                    dy_ext0 = dy0;
                    dz_ext0 = dz0;
                    xsv_ext0 = xsb;
                    ysv_ext0 = ysb;
                    zsv_ext0 = zsb;

                    // Other extra point is based on the omitted axis
                    const byte c = aPoint | bPoint;
                    if ((c & 0x01) == 0)
                    {
                        dx_ext1 = dx0 + 1 - _squishConst3D;
                        dy_ext1 = dy0 - 1 - _squishConst3D;
                        dz_ext1 = dz0 - 1 - _squishConst3D;
                        xsv_ext1 = xsb - 1;
                        ysv_ext1 = ysb + 1;
                        zsv_ext1 = zsb + 1;
                    }
                    else if ((c & 0x02) == 0)
                    {
                        dx_ext1 = dx0 - 1 - _squishConst3D;
                        dy_ext1 = dy0 + 1 - _squishConst3D;
                        dz_ext1 = dz0 - 1 - _squishConst3D;
                        xsv_ext1 = xsb + 1;
                        ysv_ext1 = ysb - 1;
                        zsv_ext1 = zsb + 1;
                    }
                    else
                    {
                        dx_ext1 = dx0 - 1 - _squishConst3D;
                        dy_ext1 = dy0 - 1 - _squishConst3D;
                        dz_ext1 = dz0 + 1 - _squishConst3D;
                        xsv_ext1 = xsb + 1;
                        ysv_ext1 = ysb + 1;
                        zsv_ext1 = zsb - 1;
                    }
                }
            }
            else
            {
                // One point on (0,0,0) side, one point on (1,1,1) side
                byte c1, c2;
                if (aIsFurtherSide)
                {
                    c1 = aPoint;
                    c2 = bPoint;
                }
                else
                {
                    c1 = bPoint;
                    c2 = aPoint;
                }

                // One contribution is a permutation of (1,1,-1)
                if ((c1 & 0x01) == 0)
                {
                    dx_ext0 = dx0 + 1 - _squishConst3D;
                    dy_ext0 = dy0 - 1 - _squishConst3D;
                    dz_ext0 = dz0 - 1 - _squishConst3D;
                    xsv_ext0 = xsb - 1;
                    ysv_ext0 = ysb + 1;
                    zsv_ext0 = zsb + 1;
                }
                else if ((c1 & 0x02) == 0)
                {
                    dx_ext0 = dx0 - 1 - _squishConst3D;
                    dy_ext0 = dy0 + 1 - _squishConst3D;
                    dz_ext0 = dz0 - 1 - _squishConst3D;
                    xsv_ext0 = xsb + 1;
                    ysv_ext0 = ysb - 1;
                    zsv_ext0 = zsb + 1;
                }
                else
                {
                    dx_ext0 = dx0 - 1 - _squishConst3D;
                    dy_ext0 = dy0 - 1 - _squishConst3D;
                    dz_ext0 = dz0 + 1 - _squishConst3D;
                    xsv_ext0 = xsb + 1;
                    ysv_ext0 = ysb + 1;
                    zsv_ext0 = zsb - 1;
                }

                // One contribution is a permutation of (0,0,2)
                dx_ext1 = dx0 - 2 * _squishConst3D;
                dy_ext1 = dy0 - 2 * _squishConst3D;
                dz_ext1 = dz0 - 2 * _squishConst3D;
                xsv_ext1 = xsb;
                ysv_ext1 = ysb;
                zsv_ext1 = zsb;
                if ((c2 & 0x01) != 0)
                {
                    dx_ext1 -= 2;
                    xsv_ext1 += 2;
                }
                else if ((c2 & 0x02) != 0)
                {
                    dy_ext1 -= 2;
                    ysv_ext1 += 2;
                }
                else
                {
                    dz_ext1 -= 2;
                    zsv_ext1 += 2;
                }
            }

            // Contribution (1,0,0)
            const T dx1 = dx0 - 1 - _squishConst3D;
            const T dy1 = dy0 - 0 - _squishConst3D;
            const T dz1 = dz0 - 0 - _squishConst3D;
            T attn1 = 2 - dx1 * dx1 - dy1 * dy1 - dz1 * dz1;
            if (attn1 > 0)
            {
                attn1 *= attn1;
                value += attn1 * attn1 * extrapolate(
                    xsb + 1, ysb + 0, zsb + 0, dx1, dy1, dz1);
            }

            // Contribution (0,1,0)
            const T dx2 = dx0 - 0 - _squishConst3D;
            const T dy2 = dy0 - 1 - _squishConst3D;
            const T dz2 = dz1;
            T attn2 = 2 - dx2 * dx2 - dy2 * dy2 - dz2 * dz2;
            if (attn2 > 0)
            {
                attn2 *= attn2;
                value += attn2 * attn2 * extrapolate(
                    xsb + 0, ysb + 1, zsb + 0, dx2, dy2, dz2);
            }

            // Contribution (0,0,1)
            const T dx3 = dx2;
            const T dy3 = dy1;
            const T dz3 = dz0 - 1 - _squishConst3D;
            T attn3 = 2 - dx3 * dx3 - dy3 * dy3 - dz3 * dz3;
            if (attn3 > 0)
            {
                attn3 *= attn3;
                value += attn3 * attn3 * extrapolate(
                    xsb + 0, ysb + 0, zsb + 1, dx3, dy3, dz3);
            }

            // Contribution (1,1,0)
            const T dx4 = dx0 - 1 - 2 * _squishConst3D;
            const T dy4 = dy0 - 1 - 2 * _squishConst3D;
            const T dz4 = dz0 - 0 - 2 * _squishConst3D;
            T attn4 = 2 - dx4 * dx4 - dy4 * dy4 - dz4 * dz4;
            if (attn4 > 0)
            {
                attn4 *= attn4;
                value += attn4 * attn4 * extrapolate(
                    xsb + 1, ysb + 1, zsb + 0, dx4, dy4, dz4);
            }

            // Contribution (1,0,1)
            const T dx5 = dx4;
            const T dy5 = dy0 - 0 - 2 * _squishConst3D;
            const T dz5 = dz0 - 1 - 2 * _squishConst3D;
            T attn5 = 2 - dx5 * dx5 - dy5 * dy5 - dz5 * dz5;
            if (attn5 > 0)
            {
                attn5 *= attn5;
                value += attn5 * attn5 * extrapolate(
                    xsb + 1, ysb + 0, zsb + 1, dx5, dy5, dz5);
            }

            // Contribution (0,1,1)
            const T dx6 = dx0 - 0 - 2 * _squishConst3D;
            const T dy6 = dy4;
            const T dz6 = dz5;
            T attn6 = 2 - dx6 * dx6 - dy6 * dy6 - dz6 * dz6;
            if (attn6 > 0)
            {
                attn6 *= attn6;
                value += attn6 * attn6 * extrapolate(
                    xsb + 0, ysb + 1, zsb + 1, dx6, dy6, dz6);
            }
        }

        // First extra vertex
        T attn_ext0 = 2 - dx_ext0 * dx_ext0 - dy_ext0 * dy_ext0 - dz_ext0 * dz_ext0;
        if (attn_ext0 > 0)
        {
            attn_ext0 *= attn_ext0;
            value += attn_ext0 * attn_ext0 * extrapolate(
                xsv_ext0, ysv_ext0, zsv_ext0, dx_ext0, dy_ext0, dz_ext0);
        }

        // Second extra vertex
        T attn_ext1 = 2 - dx_ext1 * dx_ext1 - dy_ext1 * dy_ext1 - dz_ext1 * dz_ext1;
        if (attn_ext1 > 0)
        {
            attn_ext1 *= attn_ext1;
            value += attn_ext1 * attn_ext1 * extrapolate(
                xsv_ext1, ysv_ext1, zsv_ext1, dx_ext1, dy_ext1, dz_ext1);
        }

        return value / _normConst3D;
    }

    /**
     * Computes and returns 4D noise.
     *
     * Parameters:
     *     x = The first coordinate from where noise will be taken.
     *     y = The second coordinate from where noise will be taken.
     *     z = The third coordinate from where noise will be taken.
     *     w = The fourth coordinate from where noise will be taken.
     *
     * Returns: The noise at the requested coordinates.
     */
    public T noise(T x, T y, T z, T w) const
    {
        // Place input coordinates on simplectic honeycomb
        const T stretchOffset = (x + y + z + w) * _stretchConst4D;
        const T xs = x + stretchOffset;
        const T ys = y + stretchOffset;
        const T zs = z + stretchOffset;
        const T ws = w + stretchOffset;

        // Floor to get simplectic honeycomb coordinates of rhombo-hypercube
        // super-cell origin.
        const xsb = fastFloor(xs);
        const ysb = fastFloor(ys);
        const zsb = fastFloor(zs);
        const wsb = fastFloor(ws);

        // Skew out to get actual coordinates of stretched rhombo-hypercube
        // origin. We'll need these later
        const T squishOffset = (xsb + ysb + zsb + wsb) * _squishConst4D;
        const T xb = xsb + squishOffset;
        const T yb = ysb + squishOffset;
        const T zb = zsb + squishOffset;
        const T wb = wsb + squishOffset;

        // Compute simplectic honeycomb coordinates relative to
        // rhombo-hypercube origin
        const T xins = xs - xsb;
        const T yins = ys - ysb;
        const T zins = zs - zsb;
        const T wins = ws - wsb;

        // Sum those together to get a value that determines which region we're in
        const T inSum = xins + yins + zins + wins;

        // Positions relative to origin point
        T dx0 = x - xb;
        T dy0 = y - yb;
        T dz0 = z - zb;
        T dw0 = w - wb;

        // We'll be defining these inside the next block and using them afterwards
        T dx_ext0, dy_ext0, dz_ext0, dw_ext0;
        T dx_ext1, dy_ext1, dz_ext1, dw_ext1;
        T dx_ext2, dy_ext2, dz_ext2, dw_ext2;
        int xsv_ext0, ysv_ext0, zsv_ext0, wsv_ext0;
        int xsv_ext1, ysv_ext1, zsv_ext1, wsv_ext1;
        int xsv_ext2, ysv_ext2, zsv_ext2, wsv_ext2;

        T value = 0;

        if (inSum <= 1)
        {
            // We're inside the pentachoron (4-Simplex) at (0,0,0,0)

            // Determine which two of (0,0,0,1), (0,0,1,0), (0,1,0,0), (1,0,0,0)
            // are closest
            byte aPoint = 0x01;
            T aScore = xins;
            byte bPoint = 0x02;
            T bScore = yins;
            if (aScore >= bScore && zins > bScore)
            {
                bScore = zins;
                bPoint = 0x04;
            }
            else if (aScore < bScore && zins > aScore)
            {
                aScore = zins;
                aPoint = 0x04;
            }
            if (aScore >= bScore && wins > bScore)
            {
                bScore = wins;
                bPoint = 0x08;
            }
            else if (aScore < bScore && wins > aScore)
            {
                aScore = wins;
                aPoint = 0x08;
            }

            // Now we determine the three lattice points not part of the
            // pentachoron that may contribute.  This depends on the closest
            // two pentachoron vertices, including (0,0,0,0)
            const T uins = 1 - inSum;
            if (uins > aScore || uins > bScore)
            {
                // (0,0,0,0) is one of the closest two pentachoron vertices

                // Our other closest vertex is the closest out of a and b.
                const byte c = bScore > aScore ? bPoint : aPoint;
                if ((c & 0x01) == 0)
                {
                    xsv_ext0 = xsb - 1;
                    xsv_ext1 = xsv_ext2 = xsb;
                    dx_ext0 = dx0 + 1;
                    dx_ext1 = dx_ext2 = dx0;
                }
                else
                {
                    xsv_ext0 = xsv_ext1 = xsv_ext2 = xsb + 1;
                    dx_ext0 = dx_ext1 = dx_ext2 = dx0 - 1;
                }

                if ((c & 0x02) == 0)
                {
                    ysv_ext0 = ysv_ext1 = ysv_ext2 = ysb;
                    dy_ext0 = dy_ext1 = dy_ext2 = dy0;
                    if ((c & 0x01) == 0x01)
                    {
                        ysv_ext0 -= 1;
                        dy_ext0 += 1;
                    }
                    else
                    {
                        ysv_ext1 -= 1;
                        dy_ext1 += 1;
                    }
                }
                else
                {
                    ysv_ext0 = ysv_ext1 = ysv_ext2 = ysb + 1;
                    dy_ext0 = dy_ext1 = dy_ext2 = dy0 - 1;
                }

                if ((c & 0x04) == 0)
                {
                    zsv_ext0 = zsv_ext1 = zsv_ext2 = zsb;
                    dz_ext0 = dz_ext1 = dz_ext2 = dz0;
                    if ((c & 0x03) != 0)
                    {
                        if ((c & 0x03) == 0x03)
                        {
                            zsv_ext0 -= 1;
                            dz_ext0 += 1;
                        }
                        else
                        {
                            zsv_ext1 -= 1;
                            dz_ext1 += 1;
                        }
                    }
                    else
                    {
                        zsv_ext2 -= 1;
                        dz_ext2 += 1;
                    }
                }
                else
                {
                    zsv_ext0 = zsv_ext1 = zsv_ext2 = zsb + 1;
                    dz_ext0 = dz_ext1 = dz_ext2 = dz0 - 1;
                }

                if ((c & 0x08) == 0)
                {
                    wsv_ext0 = wsv_ext1 = wsb;
                    wsv_ext2 = wsb - 1;
                    dw_ext0 = dw_ext1 = dw0;
                    dw_ext2 = dw0 + 1;
                }
                else
                {
                    wsv_ext0 = wsv_ext1 = wsv_ext2 = wsb + 1;
                    dw_ext0 = dw_ext1 = dw_ext2 = dw0 - 1;
                }
            }
            else
            {
                // (0,0,0,0) is not one of the closest two pentachoron vertices

                // Our three extra vertices are determined by the closest two
                const byte c = aPoint | bPoint;

                if ((c & 0x01) == 0)
                {
                    xsv_ext0 = xsv_ext2 = xsb;
                    xsv_ext1 = xsb - 1;
                    dx_ext0 = dx0 - 2 * _squishConst4D;
                    dx_ext1 = dx0 + 1 - _squishConst4D;
                    dx_ext2 = dx0 - _squishConst4D;
                }
                else
                {
                    xsv_ext0 = xsv_ext1 = xsv_ext2 = xsb + 1;
                    dx_ext0 = dx0 - 1 - 2 * _squishConst4D;
                    dx_ext1 = dx_ext2 = dx0 - 1 - _squishConst4D;
                }

                if ((c & 0x02) == 0)
                {
                    ysv_ext0 = ysv_ext1 = ysv_ext2 = ysb;
                    dy_ext0 = dy0 - 2 * _squishConst4D;
                    dy_ext1 = dy_ext2 = dy0 - _squishConst4D;
                    if ((c & 0x01) == 0x01)
                    {
                        ysv_ext1 -= 1;
                        dy_ext1 += 1;
                    }
                    else
                    {
                        ysv_ext2 -= 1;
                        dy_ext2 += 1;
                    }
                }
                else
                {
                    ysv_ext0 = ysv_ext1 = ysv_ext2 = ysb + 1;
                    dy_ext0 = dy0 - 1 - 2 * _squishConst4D;
                    dy_ext1 = dy_ext2 = dy0 - 1 - _squishConst4D;
                }

                if ((c & 0x04) == 0)
                {
                    zsv_ext0 = zsv_ext1 = zsv_ext2 = zsb;
                    dz_ext0 = dz0 - 2 * _squishConst4D;
                    dz_ext1 = dz_ext2 = dz0 - _squishConst4D;
                    if ((c & 0x03) == 0x03)
                    {
                        zsv_ext1 -= 1;
                        dz_ext1 += 1;
                    }
                    else
                    {
                        zsv_ext2 -= 1;
                        dz_ext2 += 1;
                    }
                }
                else
                {
                    zsv_ext0 = zsv_ext1 = zsv_ext2 = zsb + 1;
                    dz_ext0 = dz0 - 1 - 2 * _squishConst4D;
                    dz_ext1 = dz_ext2 = dz0 - 1 - _squishConst4D;
                }

                if ((c & 0x08) == 0)
                {
                    wsv_ext0 = wsv_ext1 = wsb;
                    wsv_ext2 = wsb - 1;
                    dw_ext0 = dw0 - 2 * _squishConst4D;
                    dw_ext1 = dw0 - _squishConst4D;
                    dw_ext2 = dw0 + 1 - _squishConst4D;
                }
                else
                {
                    wsv_ext0 = wsv_ext1 = wsv_ext2 = wsb + 1;
                    dw_ext0 = dw0 - 1 - 2 * _squishConst4D;
                    dw_ext1 = dw_ext2 = dw0 - 1 - _squishConst4D;
                }
            }

            // Contribution (0,0,0,0)
            T attn0 = 2 - dx0 * dx0 - dy0 * dy0 - dz0 * dz0 - dw0 * dw0;
            if (attn0 > 0)
            {
                attn0 *= attn0;
                value += attn0 * attn0 * extrapolate(
                    xsb + 0, ysb + 0, zsb + 0, wsb + 0, dx0, dy0, dz0, dw0);
            }

            // Contribution (1,0,0,0)
            const T dx1 = dx0 - 1 - _squishConst4D;
            const T dy1 = dy0 - 0 - _squishConst4D;
            const T dz1 = dz0 - 0 - _squishConst4D;
            const T dw1 = dw0 - 0 - _squishConst4D;
            T attn1 = 2 - dx1 * dx1 - dy1 * dy1 - dz1 * dz1 - dw1 * dw1;
            if (attn1 > 0)
            {
                attn1 *= attn1;
                value += attn1 * attn1 * extrapolate(
                    xsb + 1, ysb + 0, zsb + 0, wsb + 0, dx1, dy1, dz1, dw1);
            }

            // Contribution (0,1,0,0)
            const T dx2 = dx0 - 0 - _squishConst4D;
            const T dy2 = dy0 - 1 - _squishConst4D;
            const T dz2 = dz1;
            const T dw2 = dw1;
            T attn2 = 2 - dx2 * dx2 - dy2 * dy2 - dz2 * dz2 - dw2 * dw2;
            if (attn2 > 0)
            {
                attn2 *= attn2;
                value += attn2 * attn2 * extrapolate(
                    xsb + 0, ysb + 1, zsb + 0, wsb + 0, dx2, dy2, dz2, dw2);
            }

            // Contribution (0,0,1,0)
            const T dx3 = dx2;
            const T dy3 = dy1;
            const T dz3 = dz0 - 1 - _squishConst4D;
            const T dw3 = dw1;
            T attn3 = 2 - dx3 * dx3 - dy3 * dy3 - dz3 * dz3 - dw3 * dw3;
            if (attn3 > 0)
            {
                attn3 *= attn3;
                value += attn3 * attn3 * extrapolate(
                    xsb + 0, ysb + 0, zsb + 1, wsb + 0, dx3, dy3, dz3, dw3);
            }

            // Contribution (0,0,0,1)
            const T dx4 = dx2;
            const T dy4 = dy1;
            const T dz4 = dz1;
            const T dw4 = dw0 - 1 - _squishConst4D;
            T attn4 = 2 - dx4 * dx4 - dy4 * dy4 - dz4 * dz4 - dw4 * dw4;
            if (attn4 > 0)
            {
                attn4 *= attn4;
                value += attn4 * attn4 * extrapolate(
                    xsb + 0, ysb + 0, zsb + 0, wsb + 1, dx4, dy4, dz4, dw4);
            }
        }
        else if (inSum >= 3)
        {
            // We're inside the pentachoron (4-Simplex) at (1,1,1,1)

            // Determine which two of (1,1,1,0), (1,1,0,1), (1,0,1,1),
            // (0,1,1,1) are closest
            byte aPoint = 0x0E;
            T aScore = xins;
            byte bPoint = 0x0D;
            T bScore = yins;
            if (aScore <= bScore && zins < bScore)
            {
                bScore = zins;
                bPoint = 0x0B;
            }
            else if (aScore > bScore && zins < aScore)
            {
                aScore = zins;
                aPoint = 0x0B;
            }

            if (aScore <= bScore && wins < bScore)
            {
                bScore = wins;
                bPoint = 0x07;
            }
            else if (aScore > bScore && wins < aScore)
            {
                aScore = wins;
                aPoint = 0x07;
            }

            // Now we determine the three lattice points not part of the
            // pentachoron that may contribute.  This depends on the closest two
            // pentachoron vertices, including (0,0,0,0)
            const uins = 4 - inSum;
            if (uins < aScore || uins < bScore)
            {
                // (1,1,1,1) is one of the closest two pentachoron vertices

                // Our other closest vertex is the closest out of a and b
                const byte c = bScore < aScore ? bPoint : aPoint;

                if ((c & 0x01) != 0)
                {
                    xsv_ext0 = xsb + 2;
                    xsv_ext1 = xsv_ext2 = xsb + 1;
                    dx_ext0 = dx0 - 2 - 4 * _squishConst4D;
                    dx_ext1 = dx_ext2 = dx0 - 1 - 4 * _squishConst4D;
                }
                else
                {
                    xsv_ext0 = xsv_ext1 = xsv_ext2 = xsb;
                    dx_ext0 = dx_ext1 = dx_ext2 = dx0 - 4 * _squishConst4D;
                }

                if ((c & 0x02) != 0)
                {
                    ysv_ext0 = ysv_ext1 = ysv_ext2 = ysb + 1;
                    dy_ext0 = dy_ext1 = dy_ext2 = dy0 - 1 - 4 * _squishConst4D;
                    if ((c & 0x01) != 0)
                    {
                        ysv_ext1 += 1;
                        dy_ext1 -= 1;
                    }
                    else
                    {
                        ysv_ext0 += 1;
                        dy_ext0 -= 1;
                    }
                }
                else
                {
                    ysv_ext0 = ysv_ext1 = ysv_ext2 = ysb;
                    dy_ext0 = dy_ext1 = dy_ext2 = dy0 - 4 * _squishConst4D;
                }

                if ((c & 0x04) != 0)
                {
                    zsv_ext0 = zsv_ext1 = zsv_ext2 = zsb + 1;
                    dz_ext0 = dz_ext1 = dz_ext2 = dz0 - 1 - 4 * _squishConst4D;
                    if ((c & 0x03) != 0x03)
                    {
                        if ((c & 0x03) == 0)
                        {
                            zsv_ext0 += 1;
                            dz_ext0 -= 1;
                        }
                        else
                        {
                            zsv_ext1 += 1;
                            dz_ext1 -= 1;
                        }
                    }
                    else
                    {
                        zsv_ext2 += 1;
                        dz_ext2 -= 1;
                    }
                }
                else
                {
                    zsv_ext0 = zsv_ext1 = zsv_ext2 = zsb;
                    dz_ext0 = dz_ext1 = dz_ext2 = dz0 - 4 * _squishConst4D;
                }

                if ((c & 0x08) != 0)
                {
                    wsv_ext0 = wsv_ext1 = wsb + 1;
                    wsv_ext2 = wsb + 2;
                    dw_ext0 = dw_ext1 = dw0 - 1 - 4 * _squishConst4D;
                    dw_ext2 = dw0 - 2 - 4 * _squishConst4D;
                }
                else
                {
                    wsv_ext0 = wsv_ext1 = wsv_ext2 = wsb;
                    dw_ext0 = dw_ext1 = dw_ext2 = dw0 - 4 * _squishConst4D;
                }
            }
            else
            {
                // (1,1,1,1) is not one of the closest two pentachoron vertices

                // Our three extra vertices are determined by the closest two
                const byte c = aPoint & bPoint;

                if ((c & 0x01) != 0)
                {
                    xsv_ext0 = xsv_ext2 = xsb + 1;
                    xsv_ext1 = xsb + 2;
                    dx_ext0 = dx0 - 1 - 2 * _squishConst4D;
                    dx_ext1 = dx0 - 2 - 3 * _squishConst4D;
                    dx_ext2 = dx0 - 1 - 3 * _squishConst4D;
                }
                else
                {
                    xsv_ext0 = xsv_ext1 = xsv_ext2 = xsb;
                    dx_ext0 = dx0 - 2 * _squishConst4D;
                    dx_ext1 = dx_ext2 = dx0 - 3 * _squishConst4D;
                }

                if ((c & 0x02) != 0)
                {
                    ysv_ext0 = ysv_ext1 = ysv_ext2 = ysb + 1;
                    dy_ext0 = dy0 - 1 - 2 * _squishConst4D;
                    dy_ext1 = dy_ext2 = dy0 - 1 - 3 * _squishConst4D;
                    if ((c & 0x01) != 0)
                    {
                        ysv_ext2 += 1;
                        dy_ext2 -= 1;
                    }
                    else
                    {
                        ysv_ext1 += 1;
                        dy_ext1 -= 1;
                    }
                }
                else
                {
                    ysv_ext0 = ysv_ext1 = ysv_ext2 = ysb;
                    dy_ext0 = dy0 - 2 * _squishConst4D;
                    dy_ext1 = dy_ext2 = dy0 - 3 * _squishConst4D;
                }

                if ((c & 0x04) != 0)
                {
                    zsv_ext0 = zsv_ext1 = zsv_ext2 = zsb + 1;
                    dz_ext0 = dz0 - 1 - 2 * _squishConst4D;
                    dz_ext1 = dz_ext2 = dz0 - 1 - 3 * _squishConst4D;
                    if ((c & 0x03) != 0)
                    {
                        zsv_ext2 += 1;
                        dz_ext2 -= 1;
                    }
                    else
                    {
                        zsv_ext1 += 1;
                        dz_ext1 -= 1;
                    }
                }
                else
                {
                    zsv_ext0 = zsv_ext1 = zsv_ext2 = zsb;
                    dz_ext0 = dz0 - 2 * _squishConst4D;
                    dz_ext1 = dz_ext2 = dz0 - 3 * _squishConst4D;
                }

                if ((c & 0x08) != 0)
                {
                    wsv_ext0 = wsv_ext1 = wsb + 1;
                    wsv_ext2 = wsb + 2;
                    dw_ext0 = dw0 - 1 - 2 * _squishConst4D;
                    dw_ext1 = dw0 - 1 - 3 * _squishConst4D;
                    dw_ext2 = dw0 - 2 - 3 * _squishConst4D;
                }
                else
                {
                    wsv_ext0 = wsv_ext1 = wsv_ext2 = wsb;
                    dw_ext0 = dw0 - 2 * _squishConst4D;
                    dw_ext1 = dw_ext2 = dw0 - 3 * _squishConst4D;
                }
            }

            // Contribution (1,1,1,0)
            const T dx4 = dx0 - 1 - 3 * _squishConst4D;
            const T dy4 = dy0 - 1 - 3 * _squishConst4D;
            const T dz4 = dz0 - 1 - 3 * _squishConst4D;
            const T dw4 = dw0 - 3 * _squishConst4D;
            T attn4 = 2 - dx4 * dx4 - dy4 * dy4 - dz4 * dz4 - dw4 * dw4;
            if (attn4 > 0)
            {
                attn4 *= attn4;
                value += attn4 * attn4 * extrapolate(
                    xsb + 1, ysb + 1, zsb + 1, wsb + 0, dx4, dy4, dz4, dw4);
            }

            // Contribution (1,1,0,1)
            const T dx3 = dx4;
            const T dy3 = dy4;
            const T dz3 = dz0 - 3 * _squishConst4D;
            const T dw3 = dw0 - 1 - 3 * _squishConst4D;
            T attn3 = 2 - dx3 * dx3 - dy3 * dy3 - dz3 * dz3 - dw3 * dw3;
            if (attn3 > 0)
            {
                attn3 *= attn3;
                value += attn3 * attn3 * extrapolate(
                    xsb + 1, ysb + 1, zsb + 0, wsb + 1, dx3, dy3, dz3, dw3);
            }

            // Contribution (1,0,1,1)
            const T dx2 = dx4;
            const T dy2 = dy0 - 3 * _squishConst4D;
            const T dz2 = dz4;
            const T dw2 = dw3;
            T attn2 = 2 - dx2 * dx2 - dy2 * dy2 - dz2 * dz2 - dw2 * dw2;
            if (attn2 > 0)
            {
                attn2 *= attn2;
                value += attn2 * attn2 * extrapolate(
                    xsb + 1, ysb + 0, zsb + 1, wsb + 1, dx2, dy2, dz2, dw2);
            }

            // Contribution (0,1,1,1)
            const T dx1 = dx0 - 3 * _squishConst4D;
            const T dz1 = dz4;
            const T dy1 = dy4;
            const T dw1 = dw3;
            T attn1 = 2 - dx1 * dx1 - dy1 * dy1 - dz1 * dz1 - dw1 * dw1;
            if (attn1 > 0)
            {
                attn1 *= attn1;
                value += attn1 * attn1 * extrapolate(
                    xsb + 0, ysb + 1, zsb + 1, wsb + 1, dx1, dy1, dz1, dw1);
            }

            // Contribution (1,1,1,1)
            dx0 = dx0 - 1 - 4 * _squishConst4D;
            dy0 = dy0 - 1 - 4 * _squishConst4D;
            dz0 = dz0 - 1 - 4 * _squishConst4D;
            dw0 = dw0 - 1 - 4 * _squishConst4D;
            T attn0 = 2 - dx0 * dx0 - dy0 * dy0 - dz0 * dz0 - dw0 * dw0;
            if (attn0 > 0)
            {
                attn0 *= attn0;
                value += attn0 * attn0 * extrapolate(
                    xsb + 1, ysb + 1, zsb + 1, wsb + 1, dx0, dy0, dz0, dw0);
            }
        }
        else if (inSum <= 2)
        {
            // We're inside the first dispentachoron (Rectified 4-Simplex)
            T aScore;
            byte aPoint;
            bool aIsBiggerSide = true;
            T bScore;
            byte bPoint;
            bool bIsBiggerSide = true;

            // Decide between (1,1,0,0) and (0,0,1,1)
            if (xins + yins > zins + wins)
            {
                aScore = xins + yins;
                aPoint = 0x03;
            }
            else
            {
                aScore = zins + wins;
                aPoint = 0x0C;
            }

            // Decide between (1,0,1,0) and (0,1,0,1)
            if (xins + zins > yins + wins)
            {
                bScore = xins + zins;
                bPoint = 0x05;
            }
            else
            {
                bScore = yins + wins;
                bPoint = 0x0A;
            }

            // Closer between (1,0,0,1) and (0,1,1,0) will replace the
            // further of a and b, if closer
            if (xins + wins > yins + zins)
            {
                const T score = xins + wins;
                if (aScore >= bScore && score > bScore)
                {
                    bScore = score;
                    bPoint = 0x09;
                }
                else if (aScore < bScore && score > aScore)
                {
                    aScore = score;
                    aPoint = 0x09;
                }
            }
            else
            {
                const T score = yins + zins;
                if (aScore >= bScore && score > bScore)
                {
                    bScore = score;
                    bPoint = 0x06;
                }
                else if (aScore < bScore && score > aScore)
                {
                    aScore = score;
                    aPoint = 0x06;
                }
            }

            // Decide if (1,0,0,0) is closer
            const T p1 = 2 - inSum + xins;
            if (aScore >= bScore && p1 > bScore)
            {
                bScore = p1;
                bPoint = 0x01;
                bIsBiggerSide = false;
            }
            else if (aScore < bScore && p1 > aScore)
            {
                aScore = p1;
                aPoint = 0x01;
                aIsBiggerSide = false;
            }

            // Decide if (0,1,0,0) is closer
            const T p2 = 2 - inSum + yins;
            if (aScore >= bScore && p2 > bScore)
            {
                bScore = p2;
                bPoint = 0x02;
                bIsBiggerSide = false;
            }
            else if (aScore < bScore && p2 > aScore)
            {
                aScore = p2;
                aPoint = 0x02;
                aIsBiggerSide = false;
            }

            // Decide if (0,0,1,0) is closer
            const T p3 = 2 - inSum + zins;
            if (aScore >= bScore && p3 > bScore)
            {
                bScore = p3;
                bPoint = 0x04;
                bIsBiggerSide = false;
            }
            else if (aScore < bScore && p3 > aScore)
            {
                aScore = p3;
                aPoint = 0x04;
                aIsBiggerSide = false;
            }

            // Decide if (0,0,0,1) is closer
            const T p4 = 2 - inSum + wins;
            if (aScore >= bScore && p4 > bScore)
            {
                bScore = p4;
                bPoint = 0x08;
                bIsBiggerSide = false;
            }
            else if (aScore < bScore && p4 > aScore)
            {
                aScore = p4;
                aPoint = 0x08;
                aIsBiggerSide = false;
            }

            // Where each of the two closest points are determines how the
            // extra three vertices are calculated
            if (aIsBiggerSide == bIsBiggerSide)
            {
                if (aIsBiggerSide)
                {
                    //Both closest points on the bigger side
                    const byte c1 = aPoint | bPoint;
                    const byte c2 = aPoint & bPoint;
                    if ((c1 & 0x01) == 0)
                    {
                        xsv_ext0 = xsb;
                        xsv_ext1 = xsb - 1;
                        dx_ext0 = dx0 - 3 * _squishConst4D;
                        dx_ext1 = dx0 + 1 - 2 * _squishConst4D;
                    }
                    else
                    {
                        xsv_ext0 = xsv_ext1 = xsb + 1;
                        dx_ext0 = dx0 - 1 - 3 * _squishConst4D;
                        dx_ext1 = dx0 - 1 - 2 * _squishConst4D;
                    }

                    if ((c1 & 0x02) == 0)
                    {
                        ysv_ext0 = ysb;
                        ysv_ext1 = ysb - 1;
                        dy_ext0 = dy0 - 3 * _squishConst4D;
                        dy_ext1 = dy0 + 1 - 2 * _squishConst4D;
                    }
                    else
                    {
                        ysv_ext0 = ysv_ext1 = ysb + 1;
                        dy_ext0 = dy0 - 1 - 3 * _squishConst4D;
                        dy_ext1 = dy0 - 1 - 2 * _squishConst4D;
                    }

                    if ((c1 & 0x04) == 0)
                    {
                        zsv_ext0 = zsb;
                        zsv_ext1 = zsb - 1;
                        dz_ext0 = dz0 - 3 * _squishConst4D;
                        dz_ext1 = dz0 + 1 - 2 * _squishConst4D;
                    }
                    else
                    {
                        zsv_ext0 = zsv_ext1 = zsb + 1;
                        dz_ext0 = dz0 - 1 - 3 * _squishConst4D;
                        dz_ext1 = dz0 - 1 - 2 * _squishConst4D;
                    }

                    if ((c1 & 0x08) == 0)
                    {
                        wsv_ext0 = wsb;
                        wsv_ext1 = wsb - 1;
                        dw_ext0 = dw0 - 3 * _squishConst4D;
                        dw_ext1 = dw0 + 1 - 2 * _squishConst4D;
                    }
                    else
                    {
                        wsv_ext0 = wsv_ext1 = wsb + 1;
                        dw_ext0 = dw0 - 1 - 3 * _squishConst4D;
                        dw_ext1 = dw0 - 1 - 2 * _squishConst4D;
                    }

                    // One combination is a permutation of (0,0,0,2) based on c2
                    xsv_ext2 = xsb;
                    ysv_ext2 = ysb;
                    zsv_ext2 = zsb;
                    wsv_ext2 = wsb;
                    dx_ext2 = dx0 - 2 * _squishConst4D;
                    dy_ext2 = dy0 - 2 * _squishConst4D;
                    dz_ext2 = dz0 - 2 * _squishConst4D;
                    dw_ext2 = dw0 - 2 * _squishConst4D;

                    if ((c2 & 0x01) != 0)
                    {
                        xsv_ext2 += 2;
                        dx_ext2 -= 2;
                    }
                    else if ((c2 & 0x02) != 0)
                    {
                        ysv_ext2 += 2;
                        dy_ext2 -= 2;
                    }
                    else if ((c2 & 0x04) != 0)
                    {
                        zsv_ext2 += 2;
                        dz_ext2 -= 2;
                    }
                    else
                    {
                        wsv_ext2 += 2;
                        dw_ext2 -= 2;
                    }

                }
                else
                {
                    // Both closest points on the smaller side

                    // One of the two extra points is (0,0,0,0)
                    xsv_ext2 = xsb;
                    ysv_ext2 = ysb;
                    zsv_ext2 = zsb;
                    wsv_ext2 = wsb;
                    dx_ext2 = dx0;
                    dy_ext2 = dy0;
                    dz_ext2 = dz0;
                    dw_ext2 = dw0;

                    // Other two points are based on the omitted axes
                    const byte c = aPoint | bPoint;

                    if ((c & 0x01) == 0)
                    {
                        xsv_ext0 = xsb - 1;
                        xsv_ext1 = xsb;
                        dx_ext0 = dx0 + 1 - _squishConst4D;
                        dx_ext1 = dx0 - _squishConst4D;
                    }
                    else
                    {
                        xsv_ext0 = xsv_ext1 = xsb + 1;
                        dx_ext0 = dx_ext1 = dx0 - 1 - _squishConst4D;
                    }

                    if ((c & 0x02) == 0)
                    {
                        ysv_ext0 = ysv_ext1 = ysb;
                        dy_ext0 = dy_ext1 = dy0 - _squishConst4D;
                        if ((c & 0x01) == 0x01)
                        {
                            ysv_ext0 -= 1;
                            dy_ext0 += 1;
                        }
                        else
                        {
                            ysv_ext1 -= 1;
                            dy_ext1 += 1;
                        }
                    }
                    else
                    {
                        ysv_ext0 = ysv_ext1 = ysb + 1;
                        dy_ext0 = dy_ext1 = dy0 - 1 - _squishConst4D;
                    }

                    if ((c & 0x04) == 0)
                    {
                        zsv_ext0 = zsv_ext1 = zsb;
                        dz_ext0 = dz_ext1 = dz0 - _squishConst4D;
                        if ((c & 0x03) == 0x03)
                        {
                            zsv_ext0 -= 1;
                            dz_ext0 += 1;
                        }
                        else
                        {
                            zsv_ext1 -= 1;
                            dz_ext1 += 1;
                        }
                    }
                    else
                    {
                        zsv_ext0 = zsv_ext1 = zsb + 1;
                        dz_ext0 = dz_ext1 = dz0 - 1 - _squishConst4D;
                    }

                    if ((c & 0x08) == 0)
                    {
                        wsv_ext0 = wsb;
                        wsv_ext1 = wsb - 1;
                        dw_ext0 = dw0 - _squishConst4D;
                        dw_ext1 = dw0 + 1 - _squishConst4D;
                    }
                    else
                    {
                        wsv_ext0 = wsv_ext1 = wsb + 1;
                        dw_ext0 = dw_ext1 = dw0 - 1 - _squishConst4D;
                    }
                }
            }
            else
            {
                // One point on each "side"
                byte c1, c2;
                if (aIsBiggerSide)
                {
                    c1 = aPoint;
                    c2 = bPoint;
                }
                else
                {
                    c1 = bPoint;
                    c2 = aPoint;
                }

                // Two contributions are the bigger-sided point with each 0
                // replaced with -1
                if ((c1 & 0x01) == 0)
                {
                    xsv_ext0 = xsb - 1;
                    xsv_ext1 = xsb;
                    dx_ext0 = dx0 + 1 - _squishConst4D;
                    dx_ext1 = dx0 - _squishConst4D;
                }
                else
                {
                    xsv_ext0 = xsv_ext1 = xsb + 1;
                    dx_ext0 = dx_ext1 = dx0 - 1 - _squishConst4D;
                }

                if ((c1 & 0x02) == 0)
                {
                    ysv_ext0 = ysv_ext1 = ysb;
                    dy_ext0 = dy_ext1 = dy0 - _squishConst4D;
                    if ((c1 & 0x01) == 0x01)
                    {
                        ysv_ext0 -= 1;
                        dy_ext0 += 1;
                    }
                    else
                    {
                        ysv_ext1 -= 1;
                        dy_ext1 += 1;
                    }
                }
                else
                {
                    ysv_ext0 = ysv_ext1 = ysb + 1;
                    dy_ext0 = dy_ext1 = dy0 - 1 - _squishConst4D;
                }

                if ((c1 & 0x04) == 0)
                {
                    zsv_ext0 = zsv_ext1 = zsb;
                    dz_ext0 = dz_ext1 = dz0 - _squishConst4D;
                    if ((c1 & 0x03) == 0x03)
                    {
                        zsv_ext0 -= 1;
                        dz_ext0 += 1;
                    }
                    else
                    {
                        zsv_ext1 -= 1;
                        dz_ext1 += 1;
                    }
                }
                else
                {
                    zsv_ext0 = zsv_ext1 = zsb + 1;
                    dz_ext0 = dz_ext1 = dz0 - 1 - _squishConst4D;
                }

                if ((c1 & 0x08) == 0)
                {
                    wsv_ext0 = wsb;
                    wsv_ext1 = wsb - 1;
                    dw_ext0 = dw0 - _squishConst4D;
                    dw_ext1 = dw0 + 1 - _squishConst4D;
                }
                else
                {
                    wsv_ext0 = wsv_ext1 = wsb + 1;
                    dw_ext0 = dw_ext1 = dw0 - 1 - _squishConst4D;
                }

                // One contribution is a permutation of (0,0,0,2) based on
                // the smaller-sided point
                xsv_ext2 = xsb;
                ysv_ext2 = ysb;
                zsv_ext2 = zsb;
                wsv_ext2 = wsb;
                dx_ext2 = dx0 - 2 * _squishConst4D;
                dy_ext2 = dy0 - 2 * _squishConst4D;
                dz_ext2 = dz0 - 2 * _squishConst4D;
                dw_ext2 = dw0 - 2 * _squishConst4D;

                if ((c2 & 0x01) != 0)
                {
                    xsv_ext2 += 2;
                    dx_ext2 -= 2;
                }
                else if ((c2 & 0x02) != 0)
                {
                    ysv_ext2 += 2;
                    dy_ext2 -= 2;
                }
                else if ((c2 & 0x04) != 0)
                {
                    zsv_ext2 += 2;
                    dz_ext2 -= 2;
                }
                else
                {
                    wsv_ext2 += 2;
                    dw_ext2 -= 2;
                }
            }

            // Contribution (1,0,0,0)
            const T dx1 = dx0 - 1 - _squishConst4D;
            const T dy1 = dy0 - 0 - _squishConst4D;
            const T dz1 = dz0 - 0 - _squishConst4D;
            const T dw1 = dw0 - 0 - _squishConst4D;
            T attn1 = 2 - dx1 * dx1 - dy1 * dy1 - dz1 * dz1 - dw1 * dw1;
            if (attn1 > 0)
            {
                attn1 *= attn1;
                value += attn1 * attn1 * extrapolate(
                    xsb + 1, ysb + 0, zsb + 0, wsb + 0, dx1, dy1, dz1, dw1);
            }

            // Contribution (0,1,0,0)
            const T dx2 = dx0 - 0 - _squishConst4D;
            const T dy2 = dy0 - 1 - _squishConst4D;
            const T dz2 = dz1;
            const T dw2 = dw1;
            T attn2 = 2 - dx2 * dx2 - dy2 * dy2 - dz2 * dz2 - dw2 * dw2;
            if (attn2 > 0)
            {
                attn2 *= attn2;
                value += attn2 * attn2 * extrapolate(
                    xsb + 0, ysb + 1, zsb + 0, wsb + 0, dx2, dy2, dz2, dw2);
            }

            // Contribution (0,0,1,0)
            const T dx3 = dx2;
            const T dy3 = dy1;
            const T dz3 = dz0 - 1 - _squishConst4D;
            const T dw3 = dw1;
            T attn3 = 2 - dx3 * dx3 - dy3 * dy3 - dz3 * dz3 - dw3 * dw3;
            if (attn3 > 0)
            {
                attn3 *= attn3;
                value += attn3 * attn3 * extrapolate(
                    xsb + 0, ysb + 0, zsb + 1, wsb + 0, dx3, dy3, dz3, dw3);
            }

            // Contribution (0,0,0,1)
            const T dx4 = dx2;
            const T dy4 = dy1;
            const T dz4 = dz1;
            const T dw4 = dw0 - 1 - _squishConst4D;
            T attn4 = 2 - dx4 * dx4 - dy4 * dy4 - dz4 * dz4 - dw4 * dw4;
            if (attn4 > 0)
            {
                attn4 *= attn4;
                value += attn4 * attn4 * extrapolate(
                    xsb + 0, ysb + 0, zsb + 0, wsb + 1, dx4, dy4, dz4, dw4);
            }

            // Contribution (1,1,0,0)
            const T dx5 = dx0 - 1 - 2 * _squishConst4D;
            const T dy5 = dy0 - 1 - 2 * _squishConst4D;
            const T dz5 = dz0 - 0 - 2 * _squishConst4D;
            const T dw5 = dw0 - 0 - 2 * _squishConst4D;
            T attn5 = 2 - dx5 * dx5 - dy5 * dy5 - dz5 * dz5 - dw5 * dw5;
            if (attn5 > 0)
            {
                attn5 *= attn5;
                value += attn5 * attn5 * extrapolate(
                    xsb + 1, ysb + 1, zsb + 0, wsb + 0, dx5, dy5, dz5, dw5);
            }

            // Contribution (1,0,1,0)
            const T dx6 = dx0 - 1 - 2 * _squishConst4D;
            const T dy6 = dy0 - 0 - 2 * _squishConst4D;
            const T dz6 = dz0 - 1 - 2 * _squishConst4D;
            const T dw6 = dw0 - 0 - 2 * _squishConst4D;
            T attn6 = 2 - dx6 * dx6 - dy6 * dy6 - dz6 * dz6 - dw6 * dw6;
            if (attn6 > 0)
            {
                attn6 *= attn6;
                value += attn6 * attn6 * extrapolate(
                    xsb + 1, ysb + 0, zsb + 1, wsb + 0, dx6, dy6, dz6, dw6);
            }

            // Contribution (1,0,0,1)
            const T dx7 = dx0 - 1 - 2 * _squishConst4D;
            const T dy7 = dy0 - 0 - 2 * _squishConst4D;
            const T dz7 = dz0 - 0 - 2 * _squishConst4D;
            const T dw7 = dw0 - 1 - 2 * _squishConst4D;
            T attn7 = 2 - dx7 * dx7 - dy7 * dy7 - dz7 * dz7 - dw7 * dw7;
            if (attn7 > 0)
            {
                attn7 *= attn7;
                value += attn7 * attn7 * extrapolate(
                    xsb + 1, ysb + 0, zsb + 0, wsb + 1, dx7, dy7, dz7, dw7);
            }

            // Contribution (0,1,1,0)
            const T dx8 = dx0 - 0 - 2 * _squishConst4D;
            const T dy8 = dy0 - 1 - 2 * _squishConst4D;
            const T dz8 = dz0 - 1 - 2 * _squishConst4D;
            const T dw8 = dw0 - 0 - 2 * _squishConst4D;
            T attn8 = 2 - dx8 * dx8 - dy8 * dy8 - dz8 * dz8 - dw8 * dw8;
            if (attn8 > 0)
            {
                attn8 *= attn8;
                value += attn8 * attn8 * extrapolate(
                    xsb + 0, ysb + 1, zsb + 1, wsb + 0, dx8, dy8, dz8, dw8);
            }

            // Contribution (0,1,0,1)
            const T dx9 = dx0 - 0 - 2 * _squishConst4D;
            const T dy9 = dy0 - 1 - 2 * _squishConst4D;
            const T dz9 = dz0 - 0 - 2 * _squishConst4D;
            const T dw9 = dw0 - 1 - 2 * _squishConst4D;
            T attn9 = 2 - dx9 * dx9 - dy9 * dy9 - dz9 * dz9 - dw9 * dw9;
            if (attn9 > 0)
            {
                attn9 *= attn9;
                value += attn9 * attn9 * extrapolate(
                    xsb + 0, ysb + 1, zsb + 0, wsb + 1, dx9, dy9, dz9, dw9);
            }

            // Contribution (0,0,1,1)
            const T dx10 = dx0 - 0 - 2 * _squishConst4D;
            const T dy10 = dy0 - 0 - 2 * _squishConst4D;
            const T dz10 = dz0 - 1 - 2 * _squishConst4D;
            const T dw10 = dw0 - 1 - 2 * _squishConst4D;
            T attn10 = 2 - dx10 * dx10 - dy10 * dy10 - dz10 * dz10 - dw10 * dw10;
            if (attn10 > 0)
            {
                attn10 *= attn10;
                value += attn10 * attn10 * extrapolate(
                    xsb + 0, ysb + 0, zsb + 1, wsb + 1, dx10, dy10, dz10, dw10);
            }
        }
        else
        {
            // We're inside the second dispentachoron (Rectified 4-Simplex)
            T aScore;
            byte aPoint;
            bool aIsBiggerSide = true;
            T bScore;
            byte bPoint;
            bool bIsBiggerSide = true;

            // Decide between (0,0,1,1) and (1,1,0,0)
            if (xins + yins < zins + wins)
            {
                aScore = xins + yins;
                aPoint = 0x0C;
            }
            else
            {
                aScore = zins + wins;
                aPoint = 0x03;
            }

            // Decide between (0,1,0,1) and (1,0,1,0)
            if (xins + zins < yins + wins)
            {
                bScore = xins + zins;
                bPoint = 0x0A;
            }
            else
            {
                bScore = yins + wins;
                bPoint = 0x05;
            }

            // Closer between (0,1,1,0) and (1,0,0,1) will replace the further
            // of a and b, if closer
            if (xins + wins < yins + zins)
            {
                const T score = xins + wins;
                if (aScore <= bScore && score < bScore)
                {
                    bScore = score;
                    bPoint = 0x06;
                }
                else if (aScore > bScore && score < aScore)
                {
                    aScore = score;
                    aPoint = 0x06;
                }
            }
            else
            {
                const T score = yins + zins;
                if (aScore <= bScore && score < bScore)
                {
                    bScore = score;
                    bPoint = 0x09;
                }
                else if (aScore > bScore && score < aScore)
                {
                    aScore = score;
                    aPoint = 0x09;
                }
            }

            // Decide if (0,1,1,1) is closer
            const T p1 = 3 - inSum + xins;
            if (aScore <= bScore && p1 < bScore)
            {
                bScore = p1;
                bPoint = 0x0E;
                bIsBiggerSide = false;
            }
            else if (aScore > bScore && p1 < aScore)
            {
                aScore = p1;
                aPoint = 0x0E;
                aIsBiggerSide = false;
            }

            // Decide if (1,0,1,1) is closer
            const T p2 = 3 - inSum + yins;
            if (aScore <= bScore && p2 < bScore)
            {
                bScore = p2;
                bPoint = 0x0D;
                bIsBiggerSide = false;
            }
            else if (aScore > bScore && p2 < aScore)
            {
                aScore = p2;
                aPoint = 0x0D;
                aIsBiggerSide = false;
            }

            // Decide if (1,1,0,1) is closer
            const T p3 = 3 - inSum + zins;
            if (aScore <= bScore && p3 < bScore)
            {
                bScore = p3;
                bPoint = 0x0B;
                bIsBiggerSide = false;
            }
            else if (aScore > bScore && p3 < aScore)
            {
                aScore = p3;
                aPoint = 0x0B;
                aIsBiggerSide = false;
            }

            // Decide if (1,1,1,0) is closer
            const T p4 = 3 - inSum + wins;
            if (aScore <= bScore && p4 < bScore)
            {
                bScore = p4;
                bPoint = 0x07;
                bIsBiggerSide = false;
            }
            else if (aScore > bScore && p4 < aScore)
            {
                aScore = p4;
                aPoint = 0x07;
                aIsBiggerSide = false;
            }

            // Where each of the two closest points are determines how the extra
            // three vertices are calculated
            if (aIsBiggerSide == bIsBiggerSide)
            {
                if (aIsBiggerSide)
                {
                    // Both closest points on the bigger side
                    const byte c1 = aPoint & bPoint;
                    const byte c2 = aPoint | bPoint;

                    // Two contributions are permutations of (0,0,0,1) and
                    // (0,0,0,2) based on c1
                    xsv_ext0 = xsv_ext1 = xsb;
                    ysv_ext0 = ysv_ext1 = ysb;
                    zsv_ext0 = zsv_ext1 = zsb;
                    wsv_ext0 = wsv_ext1 = wsb;
                    dx_ext0 = dx0 - _squishConst4D;
                    dy_ext0 = dy0 - _squishConst4D;
                    dz_ext0 = dz0 - _squishConst4D;
                    dw_ext0 = dw0 - _squishConst4D;
                    dx_ext1 = dx0 - 2 * _squishConst4D;
                    dy_ext1 = dy0 - 2 * _squishConst4D;
                    dz_ext1 = dz0 - 2 * _squishConst4D;
                    dw_ext1 = dw0 - 2 * _squishConst4D;

                    if ((c1 & 0x01) != 0)
                    {
                        xsv_ext0 += 1;
                        dx_ext0 -= 1;
                        xsv_ext1 += 2;
                        dx_ext1 -= 2;
                    }
                    else if ((c1 & 0x02) != 0)
                    {
                        ysv_ext0 += 1;
                        dy_ext0 -= 1;
                        ysv_ext1 += 2;
                        dy_ext1 -= 2;
                    }
                    else if ((c1 & 0x04) != 0)
                    {
                        zsv_ext0 += 1;
                        dz_ext0 -= 1;
                        zsv_ext1 += 2;
                        dz_ext1 -= 2;
                    }
                    else
                    {
                        wsv_ext0 += 1;
                        dw_ext0 -= 1;
                        wsv_ext1 += 2;
                        dw_ext1 -= 2;
                    }

                    // One contribution is a permutation of (1,1,1,-1) based on c2
                    xsv_ext2 = xsb + 1;
                    ysv_ext2 = ysb + 1;
                    zsv_ext2 = zsb + 1;
                    wsv_ext2 = wsb + 1;
                    dx_ext2 = dx0 - 1 - 2 * _squishConst4D;
                    dy_ext2 = dy0 - 1 - 2 * _squishConst4D;
                    dz_ext2 = dz0 - 1 - 2 * _squishConst4D;
                    dw_ext2 = dw0 - 1 - 2 * _squishConst4D;

                    if ((c2 & 0x01) == 0)
                    {
                        xsv_ext2 -= 2;
                        dx_ext2 += 2;
                    }
                    else if ((c2 & 0x02) == 0)
                    {
                        ysv_ext2 -= 2;
                        dy_ext2 += 2;
                    }
                    else if ((c2 & 0x04) == 0)
                    {
                        zsv_ext2 -= 2;
                        dz_ext2 += 2;
                    }
                    else
                    {
                        wsv_ext2 -= 2;
                        dw_ext2 += 2;
                    }
                }
                else
                {
                    // Both closest points on the smaller side

                    // One of the two extra points is (1,1,1,1)
                    xsv_ext2 = xsb + 1;
                    ysv_ext2 = ysb + 1;
                    zsv_ext2 = zsb + 1;
                    wsv_ext2 = wsb + 1;
                    dx_ext2 = dx0 - 1 - 4 * _squishConst4D;
                    dy_ext2 = dy0 - 1 - 4 * _squishConst4D;
                    dz_ext2 = dz0 - 1 - 4 * _squishConst4D;
                    dw_ext2 = dw0 - 1 - 4 * _squishConst4D;

                    // Other two points are based on the shared axes
                    const byte c = aPoint & bPoint;

                    if ((c & 0x01) != 0)
                    {
                        xsv_ext0 = xsb + 2;
                        xsv_ext1 = xsb + 1;
                        dx_ext0 = dx0 - 2 - 3 * _squishConst4D;
                        dx_ext1 = dx0 - 1 - 3 * _squishConst4D;
                    }
                    else
                    {
                        xsv_ext0 = xsv_ext1 = xsb;
                        dx_ext0 = dx_ext1 = dx0 - 3 * _squishConst4D;
                    }

                    if ((c & 0x02) != 0)
                    {
                        ysv_ext0 = ysv_ext1 = ysb + 1;
                        dy_ext0 = dy_ext1 = dy0 - 1 - 3 * _squishConst4D;
                        if ((c & 0x01) == 0)
                        {
                            ysv_ext0 += 1;
                            dy_ext0 -= 1;
                        }
                        else
                        {
                            ysv_ext1 += 1;
                            dy_ext1 -= 1;
                        }
                    }
                    else
                    {
                        ysv_ext0 = ysv_ext1 = ysb;
                        dy_ext0 = dy_ext1 = dy0 - 3 * _squishConst4D;
                    }

                    if ((c & 0x04) != 0)
                    {
                        zsv_ext0 = zsv_ext1 = zsb + 1;
                        dz_ext0 = dz_ext1 = dz0 - 1 - 3 * _squishConst4D;
                        if ((c & 0x03) == 0)
                        {
                            zsv_ext0 += 1;
                            dz_ext0 -= 1;
                        }
                        else
                        {
                            zsv_ext1 += 1;
                            dz_ext1 -= 1;
                        }
                    }
                    else
                    {
                        zsv_ext0 = zsv_ext1 = zsb;
                        dz_ext0 = dz_ext1 = dz0 - 3 * _squishConst4D;
                    }

                    if ((c & 0x08) != 0)
                    {
                        wsv_ext0 = wsb + 1;
                        wsv_ext1 = wsb + 2;
                        dw_ext0 = dw0 - 1 - 3 * _squishConst4D;
                        dw_ext1 = dw0 - 2 - 3 * _squishConst4D;
                    }
                    else
                    {
                        wsv_ext0 = wsv_ext1 = wsb;
                        dw_ext0 = dw_ext1 = dw0 - 3 * _squishConst4D;
                    }
                }
            }
            else
            {
                // One point on each "side"
                byte c1, c2;
                if (aIsBiggerSide)
                {
                    c1 = aPoint;
                    c2 = bPoint;
                }
                else
                {
                    c1 = bPoint;
                    c2 = aPoint;
                }

                // Two contributions are the bigger-sided point with each 1
                // replaced with 2
                if ((c1 & 0x01) != 0)
                {
                    xsv_ext0 = xsb + 2;
                    xsv_ext1 = xsb + 1;
                    dx_ext0 = dx0 - 2 - 3 * _squishConst4D;
                    dx_ext1 = dx0 - 1 - 3 * _squishConst4D;
                }
                else
                {
                    xsv_ext0 = xsv_ext1 = xsb;
                    dx_ext0 = dx_ext1 = dx0 - 3 * _squishConst4D;
                }

                if ((c1 & 0x02) != 0)
                {
                    ysv_ext0 = ysv_ext1 = ysb + 1;
                    dy_ext0 = dy_ext1 = dy0 - 1 - 3 * _squishConst4D;
                    if ((c1 & 0x01) == 0)
                    {
                        ysv_ext0 += 1;
                        dy_ext0 -= 1;
                    }
                    else
                    {
                        ysv_ext1 += 1;
                        dy_ext1 -= 1;
                    }
                }
                else
                {
                    ysv_ext0 = ysv_ext1 = ysb;
                    dy_ext0 = dy_ext1 = dy0 - 3 * _squishConst4D;
                }

                if ((c1 & 0x04) != 0)
                {
                    zsv_ext0 = zsv_ext1 = zsb + 1;
                    dz_ext0 = dz_ext1 = dz0 - 1 - 3 * _squishConst4D;
                    if ((c1 & 0x03) == 0)
                    {
                        zsv_ext0 += 1;
                        dz_ext0 -= 1;
                    }
                    else
                    {
                        zsv_ext1 += 1;
                        dz_ext1 -= 1;
                    }
                }
                else
                {
                    zsv_ext0 = zsv_ext1 = zsb;
                    dz_ext0 = dz_ext1 = dz0 - 3 * _squishConst4D;
                }

                if ((c1 & 0x08) != 0)
                {
                    wsv_ext0 = wsb + 1;
                    wsv_ext1 = wsb + 2;
                    dw_ext0 = dw0 - 1 - 3 * _squishConst4D;
                    dw_ext1 = dw0 - 2 - 3 * _squishConst4D;
                }
                else
                {
                    wsv_ext0 = wsv_ext1 = wsb;
                    dw_ext0 = dw_ext1 = dw0 - 3 * _squishConst4D;
                }

                // One contribution is a permutation of (1,1,1,-1) based on the
                // smaller-sided point
                xsv_ext2 = xsb + 1;
                ysv_ext2 = ysb + 1;
                zsv_ext2 = zsb + 1;
                wsv_ext2 = wsb + 1;
                dx_ext2 = dx0 - 1 - 2 * _squishConst4D;
                dy_ext2 = dy0 - 1 - 2 * _squishConst4D;
                dz_ext2 = dz0 - 1 - 2 * _squishConst4D;
                dw_ext2 = dw0 - 1 - 2 * _squishConst4D;

                if ((c2 & 0x01) == 0)
                {
                    xsv_ext2 -= 2;
                    dx_ext2 += 2;
                }
                else if ((c2 & 0x02) == 0)
                {
                    ysv_ext2 -= 2;
                    dy_ext2 += 2;
                }
                else if ((c2 & 0x04) == 0)
                {
                    zsv_ext2 -= 2;
                    dz_ext2 += 2;
                }
                else
                {
                    wsv_ext2 -= 2;
                    dw_ext2 += 2;
                }
            }

            // Contribution (1,1,1,0)
            const T dx4 = dx0 - 1 - 3 * _squishConst4D;
            const T dy4 = dy0 - 1 - 3 * _squishConst4D;
            const T dz4 = dz0 - 1 - 3 * _squishConst4D;
            const T dw4 = dw0 - 3 * _squishConst4D;
            T attn4 = 2 - dx4 * dx4 - dy4 * dy4 - dz4 * dz4 - dw4 * dw4;
            if (attn4 > 0)
            {
                attn4 *= attn4;
                value += attn4 * attn4 * extrapolate(
                    xsb + 1, ysb + 1, zsb + 1, wsb + 0, dx4, dy4, dz4, dw4);
            }

            // Contribution (1,1,0,1)
            const T dx3 = dx4;
            const T dy3 = dy4;
            const T dz3 = dz0 - 3 * _squishConst4D;
            const T dw3 = dw0 - 1 - 3 * _squishConst4D;
            T attn3 = 2 - dx3 * dx3 - dy3 * dy3 - dz3 * dz3 - dw3 * dw3;
            if (attn3 > 0)
            {
                attn3 *= attn3;
                value += attn3 * attn3 * extrapolate(
                    xsb + 1, ysb + 1, zsb + 0, wsb + 1, dx3, dy3, dz3, dw3);
            }

            // Contribution (1,0,1,1)
            const T dx2 = dx4;
            const T dy2 = dy0 - 3 * _squishConst4D;
            const T dz2 = dz4;
            const T dw2 = dw3;
            T attn2 = 2 - dx2 * dx2 - dy2 * dy2 - dz2 * dz2 - dw2 * dw2;
            if (attn2 > 0)
            {
                attn2 *= attn2;
                value += attn2 * attn2 * extrapolate(
                    xsb + 1, ysb + 0, zsb + 1, wsb + 1, dx2, dy2, dz2, dw2);
            }

            // Contribution (0,1,1,1)
            const T dx1 = dx0 - 3 * _squishConst4D;
            const T dz1 = dz4;
            const T dy1 = dy4;
            const T dw1 = dw3;
            T attn1 = 2 - dx1 * dx1 - dy1 * dy1 - dz1 * dz1 - dw1 * dw1;
            if (attn1 > 0)
            {
                attn1 *= attn1;
                value += attn1 * attn1 * extrapolate(
                    xsb + 0, ysb + 1, zsb + 1, wsb + 1, dx1, dy1, dz1, dw1);
            }

            // Contribution (1,1,0,0)
            const T dx5 = dx0 - 1 - 2 * _squishConst4D;
            const T dy5 = dy0 - 1 - 2 * _squishConst4D;
            const T dz5 = dz0 - 0 - 2 * _squishConst4D;
            const T dw5 = dw0 - 0 - 2 * _squishConst4D;
            T attn5 = 2 - dx5 * dx5 - dy5 * dy5 - dz5 * dz5 - dw5 * dw5;
            if (attn5 > 0)
            {
                attn5 *= attn5;
                value += attn5 * attn5 * extrapolate(
                    xsb + 1, ysb + 1, zsb + 0, wsb + 0, dx5, dy5, dz5, dw5);
            }

            // Contribution (1,0,1,0)
            const T dx6 = dx0 - 1 - 2 * _squishConst4D;
            const T dy6 = dy0 - 0 - 2 * _squishConst4D;
            const T dz6 = dz0 - 1 - 2 * _squishConst4D;
            const T dw6 = dw0 - 0 - 2 * _squishConst4D;
            T attn6 = 2 - dx6 * dx6 - dy6 * dy6 - dz6 * dz6 - dw6 * dw6;
            if (attn6 > 0)
            {
                attn6 *= attn6;
                value += attn6 * attn6 * extrapolate(
                    xsb + 1, ysb + 0, zsb + 1, wsb + 0, dx6, dy6, dz6, dw6);
            }

            // Contribution (1,0,0,1)
            const T dx7 = dx0 - 1 - 2 * _squishConst4D;
            const T dy7 = dy0 - 0 - 2 * _squishConst4D;
            const T dz7 = dz0 - 0 - 2 * _squishConst4D;
            const T dw7 = dw0 - 1 - 2 * _squishConst4D;
            T attn7 = 2 - dx7 * dx7 - dy7 * dy7 - dz7 * dz7 - dw7 * dw7;
            if (attn7 > 0)
            {
                attn7 *= attn7;
                value += attn7 * attn7 * extrapolate(
                    xsb + 1, ysb + 0, zsb + 0, wsb + 1, dx7, dy7, dz7, dw7);
            }

            // Contribution (0,1,1,0)
            const T dx8 = dx0 - 0 - 2 * _squishConst4D;
            const T dy8 = dy0 - 1 - 2 * _squishConst4D;
            const T dz8 = dz0 - 1 - 2 * _squishConst4D;
            const T dw8 = dw0 - 0 - 2 * _squishConst4D;
            T attn8 = 2 - dx8 * dx8 - dy8 * dy8 - dz8 * dz8 - dw8 * dw8;
            if (attn8 > 0)
            {
                attn8 *= attn8;
                value += attn8 * attn8 * extrapolate(
                    xsb + 0, ysb + 1, zsb + 1, wsb + 0, dx8, dy8, dz8, dw8);
            }

            // Contribution (0,1,0,1)
            const T dx9 = dx0 - 0 - 2 * _squishConst4D;
            const T dy9 = dy0 - 1 - 2 * _squishConst4D;
            const T dz9 = dz0 - 0 - 2 * _squishConst4D;
            const T dw9 = dw0 - 1 - 2 * _squishConst4D;
            T attn9 = 2 - dx9 * dx9 - dy9 * dy9 - dz9 * dz9 - dw9 * dw9;
            if (attn9 > 0)
            {
                attn9 *= attn9;
                value += attn9 * attn9 * extrapolate(
                    xsb + 0, ysb + 1, zsb + 0, wsb + 1, dx9, dy9, dz9, dw9);
            }

            // Contribution (0,0,1,1)
            const T dx10 = dx0 - 0 - 2 * _squishConst4D;
            const T dy10 = dy0 - 0 - 2 * _squishConst4D;
            const T dz10 = dz0 - 1 - 2 * _squishConst4D;
            const T dw10 = dw0 - 1 - 2 * _squishConst4D;
            T attn10 = 2 - dx10 * dx10 - dy10 * dy10 - dz10 * dz10 - dw10 * dw10;
            if (attn10 > 0)
            {
                attn10 *= attn10;
                value += attn10 * attn10 * extrapolate(
                    xsb + 0, ysb + 0, zsb + 1, wsb + 1, dx10, dy10, dz10, dw10);
            }
        }

        // First extra vertex
        T attn_ext0 = 2 - dx_ext0 * dx_ext0 - dy_ext0 * dy_ext0 - dz_ext0
            * dz_ext0 - dw_ext0 * dw_ext0;

        if (attn_ext0 > 0)
        {
            attn_ext0 *= attn_ext0;
            value += attn_ext0 * attn_ext0 * extrapolate(
                xsv_ext0, ysv_ext0, zsv_ext0, wsv_ext0, dx_ext0, dy_ext0, dz_ext0, dw_ext0);
        }

        // Second extra vertex
        T attn_ext1 = 2 - dx_ext1 * dx_ext1 - dy_ext1 * dy_ext1 - dz_ext1
            * dz_ext1 - dw_ext1 * dw_ext1;

        if (attn_ext1 > 0)
        {
            attn_ext1 *= attn_ext1;
            value += attn_ext1 * attn_ext1 * extrapolate(
                xsv_ext1, ysv_ext1, zsv_ext1, wsv_ext1, dx_ext1, dy_ext1, dz_ext1, dw_ext1);
        }

        // Third extra vertex
        T attn_ext2 = 2 - dx_ext2 * dx_ext2 - dy_ext2 * dy_ext2 - dz_ext2
            * dz_ext2 - dw_ext2 * dw_ext2;

        if (attn_ext2 > 0)
        {
            attn_ext2 *= attn_ext2;
            value += attn_ext2 * attn_ext2 * extrapolate(
                xsv_ext2, ysv_ext2, zsv_ext2, wsv_ext2, dx_ext2, dy_ext2, dz_ext2, dw_ext2);
        }

        return value / _normConst4D;
    }

    //
    // Helpers
    //

    /**
     * Computes the floor of a given number.
     *
     * This is way faster than simply calling `std.math.floor()` and casting to
     * an `int`. I (LMB) did a couple of benchmarks with DMD 2.060, using flags
     * `-O -inline`. Overall, noise generation was almost 10% faster when using
     * `fastFloor()` instead of `std.math.floor()`.
     */
    private pure nothrow int fastFloor(double x) const
    {
        return x > 0
            ? cast(int)(x)
            : cast(int)(x-1);
    }

    private nothrow T extrapolate(int xsb, int ysb, T dx, T dy) const
    {
        const ix = xsb & 0xFF;
        const iy = (_perm[ix] + ysb) & 0xFF;
        const index = _perm[iy] & 0x0E;

        return _gradients2D[index + 0]  * dx
            + _gradients2D[index + 1]  * dy;
    }

    private nothrow T extrapolate(int xsb, int ysb, int zsb, T dx, T dy, T dz) const
    {
        const ix = xsb & 0xFF;
        const iy = (_perm[ix] + ysb) & 0xFF;
        const iz = (_perm[iy] + zsb) & 0xFF;
        const index = _permGradIndex3D[iz];

        return _gradients3D[index + 0] * dx
            + _gradients3D[index + 1] * dy
            + _gradients3D[index + 2] * dz;
    }

    private nothrow T extrapolate(int xsb, int ysb, int zsb, int wsb,
                                  T dx, T dy, T dz, T dw) const
    {
        const ix = xsb & 0xFF;
        const iy = (_perm[ix] + ysb) & 0xFF;
        const iz = (_perm[iy] + zsb) & 0xFF;
        const iw = (_perm[iz] + wsb) & 0xFF;
        const index = _perm[iw] & 0xFC;

        return _gradients4D[index + 0]  * dx
            + _gradients4D[index + 1] * dy
            + _gradients4D[index + 2] * dz
            + _gradients4D[index + 3] * dw;
    }

    //
    // The noise generator state
    //
    private short[256] _perm;
    private short[256] _permGradIndex3D;


    //
    // Assorted constants used throughout the code
    //
    private enum
    {
        _stretchConst2D = (1 / sqrt(2+1.0) - 1) / 2,
        _stretchConst3D = (1 / sqrt(3+1.0) - 1) / 3,
        _stretchConst4D = (1 / sqrt(4+1.0) - 1) / 4,

        _squishConst2D = (sqrt(2+1.0) - 1) / 2,
        _squishConst3D = (sqrt(3+1.0) - 1) / 3,
        _squishConst4D = (sqrt(4+1.0) - 1) / 4,

        _normConst2D = 47.0,
        _normConst3D = 103.0,
        _normConst4D = 30.0,

        /**
         * Gradients for 2D. They approximate the directions to the vertices
         * of an octagon from the center.
         */
        _gradients2D = [
             5,  2,      2,  5,
            -5,  2,     -2,  5,
             5, -2,      2, -5,
            -5, -2,     -2, -5 ],

        /**
         * Gradients for 3D. They approximate the directions to the vertices
         * of a rhombicuboctahedron from the center, skewed so that the
         * triangular and square facets can be inscribed inside circles of
         * the same radius.
         */
        _gradients3D = [
            -11,  4,  4,     -4,  11,  4,    -4,  4,  11,
             11,  4,  4,      4,  11,  4,     4,  4,  11,
            -11, -4,  4,     -4, -11,  4,    -4, -4,  11,
             11, -4,  4,      4, -11,  4,     4, -4,  11,
            -11,  4, -4,     -4,  11, -4,    -4,  4, -11,
             11,  4, -4,      4,  11, -4,     4,  4, -11,
            -11, -4, -4,     -4, -11, -4,    -4, -4, -11,
             11, -4, -4,      4, -11, -4,     4, -4, -11 ],

        /**
         * Gradients for 4D. They approximate the directions to the vertices
         * of a disprismatotesseractihexadecachoron from the center, skewed
         * so that the tetrahedral and cubic facets can be inscribed inside
         * spheres of the same radius
         */
        _gradients4D = [
             3,  1,  1,  1,    1,  3,  1,  1,    1,  1,  3,  1,    1,  1,  1,  3,
            -3,  1,  1,  1,   -1,  3,  1,  1,   -1,  1,  3,  1,   -1,  1,  1,  3,
             3, -1,  1,  1,    1, -3,  1,  1,    1, -1,  3,  1,    1, -1,  1,  3,
            -3, -1,  1,  1,   -1, -3,  1,  1,   -1, -1,  3,  1,   -1, -1,  1,  3,
             3,  1, -1,  1,    1,  3, -1,  1,    1,  1, -3,  1,    1,  1, -1,  3,
            -3,  1, -1,  1,   -1,  3, -1,  1,   -1,  1, -3,  1,   -1,  1, -1,  3,
             3, -1, -1,  1,    1, -3, -1,  1,    1, -1, -3,  1,    1, -1, -1,  3,
            -3, -1, -1,  1,   -1, -3, -1,  1,   -1, -1, -3,  1,   -1, -1, -1,  3,
             3,  1,  1, -1,    1,  3,  1, -1,    1,  1,  3, -1,    1,  1,  1, -3,
            -3,  1,  1, -1,   -1,  3,  1, -1,   -1,  1,  3, -1,   -1,  1,  1, -3,
             3, -1,  1, -1,    1, -3,  1, -1,    1, -1,  3, -1,    1, -1,  1, -3,
            -3, -1,  1, -1,   -1, -3,  1, -1,   -1, -1,  3, -1,   -1, -1,  1, -3,
             3,  1, -1, -1,    1,  3, -1, -1,    1,  1, -3, -1,    1,  1, -1, -3,
            -3,  1, -1, -1,   -1,  3, -1, -1,   -1,  1, -3, -1,   -1,  1, -1, -3,
             3, -1, -1, -1,    1, -3, -1, -1,    1, -1, -3, -1,    1, -1, -1, -3,
            -3, -1, -1, -1,   -1, -3, -1, -1,   -1, -1, -3, -1,   -1, -1, -1, -3 ],
    }
}



// -----------------------------------------------------------------------------
// Unit tests
// -----------------------------------------------------------------------------

// Just in case, ensure that the constants have the same value as the ones in
// Kurt's Java reference implementation (which are either hardcoded or in a
// different form as I used here)
unittest
{
    enum epsilon = 1e-10;
    alias osn = OpenSimplexNoiseGenerator!double;

    assertClose(osn._stretchConst2D, -0.211324865405187, epsilon);
    assertClose(osn._stretchConst3D, -1.0/6, epsilon);
    assertClose(osn._stretchConst4D, -0.138196601125011, epsilon);

    assertClose(osn._squishConst2D, 0.366025403784439, epsilon);
    assertClose(osn._squishConst3D, 1.0/3, epsilon);
    assertClose(osn._squishConst4D, 0.309016994374947, epsilon);
}


// Construct with a default seed, check if some values in `_perm` match those of
// the reference Java implementation
unittest
{
    auto ng = OpenSimplexNoiseGenerator!double(0);
    assert(ng._perm[0] == 254);
    assert(ng._perm[12] == 152);
    assert(ng._perm[48] == 38);
    assert(ng._perm[77] == 150);
    assert(ng._perm[152] == 218);
    assert(ng._perm[199] == 217);
    assert(ng._perm[222] == 172);
    assert(ng._perm[255] == 211);
}


// Construct with a non default seed, check if some values in `_perm` match
// those of the reference Java implementation
unittest
{
    auto ng = OpenSimplexNoiseGenerator!real(171);
    assert(ng._perm[0] == 222);
    assert(ng._perm[12] == 65);
    assert(ng._perm[48] == 52);
    assert(ng._perm[77] == 225);
    assert(ng._perm[152] == 15);
    assert(ng._perm[199] == 38);
    assert(ng._perm[222] == 1);
    assert(ng._perm[255] == 46);
}


// Construct with the default seed, check if some values in `_permGradIndex3D`
// match those of the reference Java implementation
unittest
{
    auto ng = OpenSimplexNoiseGenerator!double(0);
    assert(ng._permGradIndex3D[0] == 42);
    assert(ng._permGradIndex3D[12] == 24);
    assert(ng._permGradIndex3D[48] == 42);
    assert(ng._permGradIndex3D[77] == 18);
    assert(ng._permGradIndex3D[152] == 6);
    assert(ng._permGradIndex3D[199] == 3);
    assert(ng._permGradIndex3D[222] == 12);
    assert(ng._permGradIndex3D[255] == 57);
}


// Construct with a non default seed, check if some values in `permGradIndex3D`
// match those of the reference Java implementation
unittest
{
    auto ng = OpenSimplexNoiseGenerator!float(171);
    assert(ng._permGradIndex3D[0] == 18);
    assert(ng._permGradIndex3D[12] == 51);
    assert(ng._permGradIndex3D[48] == 12);
    assert(ng._permGradIndex3D[77] == 27);
    assert(ng._permGradIndex3D[152] == 45);
    assert(ng._permGradIndex3D[199] == 42);
    assert(ng._permGradIndex3D[222] == 3);
    assert(ng._permGradIndex3D[255] == 66);
}


// Construct with a default seed, generate noise at certain coordinates; compare
// with the values in the reference Java implementation
unittest
{
    enum epsilon = 1e-10;
    const ng = OpenSimplexNoiseGenerator!double(0);

    assertClose(ng.noise(  0.1,   -0.5),  0.16815495823682902, epsilon);
    assertClose(ng.noise(  0.3,   -0.5), -0.11281949225360029, epsilon);
    assertClose(ng.noise(-10.5,    0.0), -0.37687315318724424, epsilon);
    assertClose(ng.noise(108.2,  -77.7),  0.21990349345573232, epsilon);

    assertClose(ng.noise( 0.1,  0.2, -0.3),  0.09836613421359222, epsilon);
    assertClose(ng.noise(11.1, -0.2, -4.4), -0.25745726578628725, epsilon);
    assertClose(ng.noise(-0.7,  0.9,  1.0), -0.14212747572815548, epsilon);
    assertClose(ng.noise( 0.3,  0.7,  0.2),  0.60269370138511320, epsilon);

    assertClose(ng.noise( 0.5,  0.6,  0.7,  0.8), 0.032961823285107585, epsilon);
    assertClose(ng.noise(70.2, -0.2, 10.7,  0.4), 0.038545368047082425, epsilon);
    assertClose(ng.noise(-9.9,  1.3,  0.0, -0.7), 0.309010265232531170, epsilon);
    assertClose(ng.noise( 0.0,  0.0, 99.9,  0.9), 0.102975407300067490, epsilon);
}


// Construct with a non default seed, generate noise at certain coordinates;
// compare with the values in the reference Java implementation
unittest
{
    enum epsilon = 1e-10;

    // And, just for a change, allocate on the heap
    const ng = new OpenSimplexNoiseGenerator!double(88);

    assertClose(ng.noise(  5.1,   5.1), -0.09484174826559418, epsilon);
    assertClose(ng.noise(  1.1,  -3.1), -0.07713472832667981, epsilon);
    assertClose(ng.noise(111.2, -13.5), -0.59882723790502210, epsilon);
    assertClose(ng.noise(  0.0,  -0.1),  0.16709963561090702, epsilon);

    assertClose(ng.noise( 0.0, -0.3,  0.0), -0.37499018382847904, epsilon);
    assertClose(ng.noise( 1.3,  8.9,  0.0),  0.38463514563106793, epsilon);
    assertClose(ng.noise(-2.2, -1.1, 10.9), -0.31665633373446817, epsilon);
    assertClose(ng.noise( 0.5,  0.6,  0.7),  0.42277598705501640, epsilon);

    assertClose(ng.noise(-0.6,  0.6, -0.6,  0.6),  0.18250580763268456, epsilon);
    assertClose(ng.noise(10.0, 20.0, 30.0, 40.0), -0.29147410304623306, epsilon);
    assertClose(ng.noise( 0.5,  0.0,  0.0,  0.0),  0.08398241210986652, epsilon);
    assertClose(ng.noise(-0.8,  7.7, -7.7, 33.3), -0.20662241504474765, epsilon);
}

version(ExtraUnitTests)
{
    // Now, let's test the results thoroughly, comparing lots of generated values
    // with values from the reference Java implementation.
    unittest
    {
        import std.math: abs;
        import sbxs.noise.test_data.open_simplex_noise_data;

        // These epsilons are quite large; I expected that this would produce values
        // really close to those generated by the reference Java
        // implementation. According to my debugging, there are, it seems, some
        // subtle ways in which floating point computations differ between D and
        // Java. And this causes some really devious differences in which code paths
        // are taken, which ultimately leads to "errors" much larger than I
        // originally expected. (But then, what do I know about IEEE 754?)
        //
        // This implementation should work for any purposes, but it would be nice to
        // use much smaller epsilons here.
        enum epsilon = 2e-2;
        enum almostZero = 1e-3;

        size_t i;

        // 2D
        auto ng = OpenSimplexNoiseGenerator!double(778899);
        i = 0;

        foreach (x; -6..7) foreach (y; -6..7)
        {
            const n = ng.noise(x/2.2, y/2.2);

            if (abs(expected2D[i]) < almostZero)
                assertSmall(n, epsilon);
            else
                assertClose(n, expected2D[i], epsilon);

            ++i;
        }

        // 3D
        ng = OpenSimplexNoiseGenerator!double(102938);
        i = 0;

        foreach(x; -6..7) foreach(y; -6..7) foreach(z; -6..7)
        {
            const n = ng.noise(x/2.2, y/2.2, z/2.2);

            if (abs(expected3D[i]) < almostZero)
                assertSmall(n, epsilon);
            else
                assertClose(n, expected3D[i], epsilon);

            ++i;
        }

        // 4D
        ng = OpenSimplexNoiseGenerator!double(657483);
        i = 0;

        foreach(x; -6..7) foreach(y; -6..7) foreach(z; -6..7) foreach(w; -6..7)
        {
            const n = ng.noise(x/2.2, y/2.2, z/2.2, w/2.2);

            if (abs(expected4D[i]) < almostZero)
                assertSmall(n, epsilon);
            else
                assertClose(n, expected4D[i], epsilon);

            ++i;
        }
    }
} // version (ExtraUnitTests)
