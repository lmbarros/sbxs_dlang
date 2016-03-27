--
-- SBXS's build system
--
-- Available configurations:
--     - Release: optimized, no debug, no bounds checks, no unit tests, etc.
--     - Debug: no optimization, most unit tests.
--     - Test: all unit tests, even those marked with `version(ExtraUnitTests)`,
--       and code coverage.
--
-- Optional Libraries:
--     - SDL 2 [HasSDL2]: For the engine back end based on SDL 2.
--     - Allegro 5 [HasAllegro5]: For the engine back end based on Allegro 5.


-------------------------------------------------------------------------------
-- Handy constants
-------------------------------------------------------------------------------

-- All SBXS source files.
local filesSBXS = { "../src/sbxs/**.d" }


-- SBXS back ends source files.
local filesSBXSBackends = { "../src/sbxs/engine/backends/**.d" }


-- Files to be compiled in for SDL 2 support.
local filesSDL2 = {
    "../deps/DerelictUtil/source/**.d",
    "../deps/DerelictSDL2/source/**.d",
    "../deps/DerelictGL3/source/**.d"
}


-- Files to be compiled in for Allegro 5 support.
local filesAllegro5 = {
    "../deps/DerelictUtil/source/**.d",
    "../deps/DerelictAllegro5/source/**.d",
    "../deps/DerelictGL3/source/**.d"
}


-- Version constants for all the dependencies
local versionAllDeps = { "HasSDL2", "HasAllegro5" }



-------------------------------------------------------------------------------
-- General build settings
-------------------------------------------------------------------------------

workspace "SBXS"
    language "D"
    configurations { "Debug", "Release", "Test" }
    includedirs { "../src", "../deps/Derelict*/source" }
    versionconstants (versionAllDeps)
    flags { "MultiProcessorCompile" }
    warnings "Extra"
    targetdir "."

    filter "configurations:Debug or Test"
        flags { "UnitTest", "Symbols" }
        optimize "Off"

    filter "configurations:Test"
        flags { "CodeCoverage" }
        versionconstants { "ExtraUnitTests" }

    filter "configurations:Release"
        flags { "LinkTimeOptimization", "NoBoundsCheck" }
        optimize "Speed"



-------------------------------------------------------------------------------
-- Core stuff (library itself, tests...)
-------------------------------------------------------------------------------

--
-- Project sbxs: the static library
--
project "sbxs"
    kind "StaticLib"
    files (filesSBXS)

--
-- Project UnitTests: for running the unittests
--
project "UnitTests"
    kind "ConsoleApp"
    files "../src/run_unit_tests.d"
    files (filesSBXS)

    -- Always enable unit tests (even the extra ones) for this project
    flags { "UnitTest" }
    versionconstants { "ExtraUnitTests" }

    -- Don't test the back ends
    removefiles (filesSBXSBackends)
    removeversionconstants (versionAllDeps)



-------------------------------------------------------------------------------
-- Sample programs
-------------------------------------------------------------------------------

--
-- Project SampleMazeSDL2: simple maze game, for testing the SDL 2 back end
--
project "SampleMazeSDL2"
    kind "WindowedApp"
    files "../samples/maze/**.d"
    files (filesSDL2)
    versionconstants "UseSDL2"
    links "sbxs"

--
-- Project SampleMazeAllegro5: simple maze game, for testing the Allegro 5 back end
--
project "SampleMazeAllegro5"
    kind "WindowedApp"
    files "../samples/maze/**.d"
    files (filesAllegro5)
    versionconstants "UseAllegro5"
    links "sbxs"
