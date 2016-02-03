/**
 * The Corrected Block Tiny Encryption Algorithm (AKA XXTEA).
 *
 * I know just about nothing of cryptography. As far as I checked, this doesn't
 * seem to be particularly safe. It's not exactly trivial to break either, so it
 * shall suffice for encrypting non-critical things, like saved games.
 *
 * License: MIT License, see the `LICENSE` file.
 *
 * Authors: D version by Leandro Motta Barros, adapted from code available at
 * the Wikipedia.
 *
 * See_Also: https://en.wikipedia.org/wiki/XXTEA
 *
 * TODO: Someday I may try to make this more idiomatic, make it range-based and
 *     the like.
 */

module sbxs.crypto.xxtea;


/**
 * Encrypts data using the Corrected Block TEA (XXTEA) algorithm.
 *
 * Parameters:
 *     data = The data to be encrypted; encryption happens in-place, that is,
 *         `data` is replaced with its encrypted version. `data` must be at
 *         least two words (`uint`s) long.
 *     key = The encryption key.
 *
 * Returns:
 *     For convenience, returns `data`.
 */
public uint[] xxteaEncrypt(uint[] data, const uint[4] key)
in
{
    assert(data.length > 1);
    assert(data.length < uint.max);
}
body
{
    enum delta = 0x9e3779b9;
    const n = cast(uint)(data.length);

    uint rounds = 6 + 52/n;
    uint sum = 0;
    uint y;
    uint z = data[n-1];

    do
    {
        sum += delta;
        uint e = (sum >> 2) & 3;
        uint p;

        for (p = 0; p < n-1; ++p)
        {
            y = data[p+1];
            z = data[p] += (z>>5^y<<2) + (y>>3^z<<4)^(sum^y) + (key[p&3^e]^z);
        }

        y = data[0];
        z = data[n-1] += (z>>5^y<<2) + (y>>3^z<<4)^(sum^y) + (key[p&3^e]^z);
    }
    while (--rounds);

    return data;
}


/**
 * Decrypts data using the Corrected Block TEA (XXTEA) algorithm.
 *
 * Parameters:
 *     data = The data to be decrypted; decryption happens in-place, that is,
 *         `data` is replaced with its decrypted version. `data` must be at
 *         least two words (`uint`s) long.
 *     key = The decryption key.
 *
 * Returns:
 *     For convenience, returns `data`.
 */
public uint[] xxteaDecrypt(uint[] data, const uint[4] key)
in
{
    assert(data.length > 1);
    assert(data.length < uint.max);
}
body
{
    enum delta = 0x9e3779b9;
    const n = cast(uint)(data.length);

    uint rounds = 6 + 52/n;
    uint sum = rounds * delta;
    uint y= data[0];
    uint z;

    do
    {
        uint e = (sum >> 2) & 3;
        uint p;
        for (p = n-1; p > 0; --p)
       {
           z = data[p-1];
           y = data[p] -= ((z>>5^y<<2) + (y>>3^z<<4))
               ^ ((sum^y) + (key[(p&3)^e] ^ z));
       }

        z = data[n-1];
        y = data[0] -= ((z>>5^y<<2) + (y>>3^z<<4))
            ^ ((sum^y) + (key[(p&3)^e] ^ z));
    }
    while ((sum -= delta) != 0);

    return data[];
}


// This tests XXTEA with some data I made up. Just encrypt, decrypt and compare.
unittest
{
    void test(const uint[] originalData, uint[4] goodKey, uint[4] badKey)
    {
        auto encryptedData = originalData.dup;
        xxteaEncrypt(encryptedData, goodKey);
        assert(encryptedData != originalData);

        auto decryptedData = encryptedData.dup;
        assert(xxteaDecrypt(decryptedData, goodKey) == originalData);
        assert(decryptedData == originalData);

        auto badlyDecryptedData = encryptedData.dup;
        assert(xxteaDecrypt(badlyDecryptedData, badKey) != originalData);
        assert(badlyDecryptedData != originalData);
    }

    test([ 0, 0 ],
         [ 1, 2, 3, 4 ],
         [ 1, 2, 3, 3 ]);

    test([ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19 ],
         [ 111, 2222, 333333, 4444444 ],
         [ 111, 2222, 333533, 4444444 ]);

    test([ 97633784, 77774267, 535676, 753219, 10874, 57, 132432, 811, 34145 ],
         [ 555518, 7436, 526, 2 ],
         [ 8834, 426, 100000, 96 ]);
}


// This tests XXTEA with some test vectors provided by Mike Amling at
// http://www.derkeiler.com/Newsgroups/sci.crypt/2005-06/1514.html.
unittest
{
    void test(const uint[] originalData,
              uint[4] key,
              const uint[] expectedEncryptedData)
    {
        auto encryptedData = originalData.dup;
        xxteaEncrypt(encryptedData, key);
        assert(encryptedData == expectedEncryptedData);

        auto decryptedData = encryptedData.dup;
        xxteaDecrypt(decryptedData, key);
        assert(decryptedData == originalData);
    }

    test([ 0x00000000, 0x00000000, 0x00000000, 0x00000000,
           0x00000000, 0x00000000, 0x00000000, 0x00000000,
           0x00000000, 0x00000000, 0x00000000, 0x00000000,
           0x00000000, 0x00000000, 0x00000000, 0x00000000 ],

         [ 0x00000000, 0x00000000, 0x00000000, 0x00000000 ],

         [ 0xD663E385, 0xC326BA9F, 0xD3F2C118, 0x73C298AC,
           0x4629C79B, 0xEE869228, 0xFBE0F405, 0x02438C0C,
           0x87FBD5B5, 0x96C895E5, 0x4D1774D2, 0x06C49A54,
           0x39D73C8B, 0x7253DC0B, 0xE9EBA545, 0x17B92604 ]);


    test([ 0x85CCECD1, 0x0809F039, 0xAD150CEE, 0xCD8830E1,
           0xEAF7490A, 0x90531F68, 0x1D5246B7, 0x895E0689,
           0x060295DC, 0xF320E434, 0xEB7AD0FC, 0x945A57A4,
           0xBD17190B, 0x528372B4, 0x7683242C, 0x5941CC15 ],

         [ 0xE53080F1, 0xA36EDB72, 0x01C5FFF1, 0x6ED711AE ],

         [ 0x6260A64D, 0x73F40272, 0x202EE7DE, 0x2B28DB44,
           0xE8DBED1E, 0xEEF43389, 0x98176333, 0x79C82F11,
           0xE458561A, 0x1D8D6F80, 0x5FDB9E43, 0xA499A307,
           0xFFC5DE6D, 0x1F4FAD68, 0x8D729B94, 0xFA27B0E6]);
}
