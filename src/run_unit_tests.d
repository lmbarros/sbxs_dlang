/**
 * This doesn't do nothing interesting. This is intended to be linked with all
 * SBXS sources and compiled with the `-unittest` flag. Then, running this will
 * run the library unit tests.
 *
 * License: MIT License, see the `LICENSE` file.
 *
 * Authors: Leandro Motta Barros.
 */

/**
 * Just prints a message telling what tests have run. If any test fails, we'll
 * get a nice stack trace before `main()` even runs.
 */
void main()
{
    import std.stdio: writeln;

    version (unittest)
    {
        version (ExtraUnitTests)
        {
            writeln("All tests passed!");
        }
        else
        {
            writeln("Normal tests passed! (Didn't run the extra ones.)");
        }
    }
    else
    {
        writeln("NO TESTS RAN! (This was not compiled with unit tests enabled.)");
    }
}
