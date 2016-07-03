/**
 * The abysmal Indigest hashing algorithm.
 *
 * You probably shouldn't use this.
 *
 * This a hashing (digest) algorithm I created myself. There is absolutely
 * no rational thought here. I just tried some operations more or less
 * randomly until I got something that worked for me.
 *
 * I know nearly nothing about security, but one thing I know is that any
 * decent digest algorithm has a lot of thought behind them. So, this is
 * absolutely not adequate for any minimally serious application.
 *
 * I know nothing about
 * cryptography, and everything I did here is nearly random. trial and error
 * attempts.
 *
 * License: MIT License, see the `LICENSE` file.
 *
 * Authors: Leandro Motta Barros.
 */

module sbxs.crypto.indigest;


/**
 * Computes a digest of the input data using the abysmal Indigest hashing
 * algorithm.
 *
 * You probably shouldn't use this.
 *
 * This a hashing (digest) algorithm I created myself. There is absolutely
 * no rational thought here. I just tried some operations more or less
 * randomly until I got something that worked for me.
 *
 * I know nearly nothing about security, but one thing I know is that any
 * decent digest algorithm has a lot of thought behind them. So, this is
 * absolutely not adequate for any minimally serious application.
 *
 * So, why did I write this? Because I needed a digest algorithm callable
 * in compile-time (CTFE), because I didn't care if it was terrible, and
 * because I wanted to shift and rotate some bits.
 *
 * Parameters:
 *     data = The data to be digested.
 *
 * Returns:
 *     A 128-bit digest of `data`.
 */
public ubyte[16] indigest(string data) pure nothrow
{
    // Some random bytes from random.org (not very scientific, uh?).
    static immutable ubyte[256] table = [
        186, 227, 253, 238, 134, 106,  58, 250, 232,  88, 215,  15, 124, 238,  18,  58,
        178, 244,  60,  15,  16,  65, 113, 164,   6, 220, 122, 235,  85,  90,  79,  40,
        226,  50, 172, 182, 233, 211, 168, 135, 180, 190, 188, 165, 145, 139, 202, 212,
        32,    8, 193,   0, 147, 150, 139,  51, 174, 163, 100, 182,  55, 199,  27, 105,
        12,  132, 136, 155, 205,  66, 176,  30, 124, 244, 247, 231,  92,  97, 172, 162,
        249, 204, 120, 234, 177, 228,  24, 185, 161, 143, 141, 117, 186, 226,  66, 136,
        108, 121, 106, 151, 170, 200,  26, 208, 138, 190, 144,  23, 133,  21, 228,  95,
        99,  118, 130, 183, 213, 123, 231,  44, 210, 149,  74, 161, 222, 252,  87,  70,
        105, 187, 226, 214, 119,  25,  73,  52, 208, 124,  36, 228,  83, 188,  29,  72,
        82,   56, 252,  32, 213,  65,  45, 190, 172, 246, 183,  89,  26,  39, 211, 244,
        37,  192, 117,  67, 214, 243, 110,  96,  64, 174, 107,  76, 232, 181, 183, 207,
        176, 211, 60,  207, 122, 142,  41,  35, 138,  60, 198, 202, 197,  44,  32,   2,
        198, 245, 150, 170,  64, 249, 240, 147,  55, 199, 214, 135, 102, 188,  80, 111,
        97,  222,  21,  16, 149,  29,  64, 229,  55, 197,  51, 132,  89,  87, 197, 197,
        234,  59,  74,  62, 108, 174,   5, 183,  82,  62,  49,  13,  73, 250, 112,  23,
        67,   44, 155,  27, 165, 221, 116, 198,  62, 100, 235, 121,  64, 225, 149, 227,
    ];

    /// Rotate `x` left by `y` bits.
    uint rol(uint x, uint y) pure nothrow
    {
        return y == 0
            ? x
            : (x << y) | (x >> (32 - y));
    }

    /// Rotate `x` right by `y` bits.
    uint ror(uint x, uint y) pure nothrow
    {
        return y == 0
            ? x
            : (x >> y) | (x << (32 - y));
    }

    // Initial value also taken from random.org.
    uint[4] hash = [ 0x6f37f670, 0x9a869618, 0x79c4ccf9, 0x0cafd4a5 ];

    // Length of input
    const len = data.length;

    // Length of table
    const tLen = table.length;

    // One round of execution
    void doRound(int roundNumber) nothrow
    {
        import std.range: iota;
        const tableIndex = (hash[0] + hash[1] + hash[2] + hash[3] + roundNumber) % tLen;

        uint i = len == 0 ? 0 : table[tableIndex] % len;

        foreach (dummy; iota(len))
        {
            hash[0] = hash[2] + ((table[data[i] % tLen]) << 8) + (data[i] << 24);
            hash[1] = rol(hash[0], table[hash[2] % tLen] % 32);
            hash[2] += hash[3] + data[table[hash[1] % tLen] % len];
            hash[3] = ror(hash[2], table[hash[0] % tLen] % 32);

            i = (i + 1) % len;
        }
    }

    // Eight rounds sounds good
    for (auto i = 0; i < 8; ++i)
        doRound(i);

    // Swap byte order if needed and we are done!
    if (!__ctfe)
    {
        version(BigEndian)
        {
            import std.bitmanip: swapEndian;
            for (auto i = 0; i < 4; ++i)
                hash[i] = swapEndian(hash[i]);
        }
        return cast(ubyte[16])hash;
    }
    else
    {
        return [ cast(ubyte)(hash[0] & 0x0000_00ff),
                 cast(ubyte)((hash[0] & 0x0000_ff00) >> 8),
                 cast(ubyte)((hash[0] & 0x00ff_0000) >> 16),
                 cast(ubyte)((hash[0] & 0xff00_0000) >> 24),

                 cast(ubyte)(hash[1] & 0x0000_00ff),
                 cast(ubyte)((hash[1] & 0x0000_ff00) >> 8),
                 cast(ubyte)((hash[1] & 0x00ff_0000) >> 16),
                 cast(ubyte)((hash[1] & 0xff00_0000) >> 24),

                 cast(ubyte)(hash[2] & 0x0000_00ff),
                 cast(ubyte)((hash[2] & 0x0000_ff00) >> 8),
                 cast(ubyte)((hash[2] & 0x00ff_0000) >> 16),
                 cast(ubyte)((hash[2] & 0xff00_0000) >> 24),

                 cast(ubyte)(hash[3] & 0x0000_00ff),
                 cast(ubyte)((hash[3] & 0x0000_ff00) >> 8),
                 cast(ubyte)((hash[3] & 0x00ff_0000) >> 16),
                 cast(ubyte)((hash[3] & 0xff00_0000) >> 24) ];
    }
}


unittest
{
    assert(indigest("") ==    x"70f6376f 1896869a f9ccc479 a5d4af0c");
    assert(indigest(" ") ==   x"14b8a131 a13114b8 385bd679 d679385b");
    assert(indigest("  ") ==  x"7afa898d 36eae927 72bf10ff 2fc4bfdc");
    assert(indigest("   ") == x"b0622378 2378b062 d48b38a8 38a8d48b");

    assert(indigest("The book is on the table")
        == x"4f83bbfa 3f0deeea e1f511d6 787d8475");
    assert(indigest("the book is on the table")
        == x"d417a1f0 22149efa 78897751 8bc24bbc");
    assert(indigest("The book is on the table.")
        == x"ef1b0751 8d83a8f7 c8dd04b1 6291bb09");
    assert(indigest("the book is on the table.")
        == x"f431008a 913e0640 62dcf90b e3ce5f10");

    assert(indigest("foo") == x"85d6b4f9 ad69f30b 4d8500cf e7a64280");
    assert(indigest("fooo") == x"c7df1768 be403bfe 447adf79 3b8f48ef");
    assert(indigest("foooo") == x"68f6f905 17a0d9e7 d02e622e 8b980bb4");
    assert(indigest("ffoo") == x"f5be1ce2 de9743bc 98ce23db c6741ed9");
    assert(indigest("fffoo") == x"af353587 9ac3d79a 607a6c8b d816c1f4");

    assert(indigest(
`As armas e os barões assinalados
Que da Ocidental praia Lusitana,
Por mares nunca dantes navegados
Passaram ainda além da Taprobana,
Em perigos e guerras esforçados
Mais do que prometia a força humana,
E entre gente remota edificaram
Novo Reino, que tanto sublimaram;

E também as memórias gloriosas
Daqueles Reis que foram dilatando
A Fé, o Império, e as terras viciosas
De África e de Ásia andaram devastando,
E aqueles que por obras valerosas
Se vão da lei da Morte libertando,
Cantando espalharei por toda parte,
Se a tanto me ajudar o engenho e arte.`)
    == x"b2107e39 0be19723 3faa487e f7a38ae4");
}


// Run at compile time
unittest
{
    enum digest = indigest("The book is on the table");
    static assert(digest == x"4f83bbfa 3f0deeea e1f511d6 787d8475");
}
