workspace "SBXS"
    language "D"
    configurations { "Test" }
    includedirs { "src", "deps/Derelict*/source" }
    versionconstants { "HasSDL2", "HasAllegro5" }
    filter "configurations:Test"
        flags { "UnitTest", "CodeCoverage" }
        optimize "Off"

project "sbxs"
    kind "StaticLib"
    files { "src/sbxs/**.d" }

project "UnitTests"
    kind "ConsoleApp"
    files { "src/run_unit_tests.d", "src/sbxs/**.d", "deps/DerelictUtil/source/**.d" }
    removefiles { "src/sbxs/engine/backend" }
    removeversionconstants { "HasSDL2", "HasAllegro5" }
    versionconstants { "LongRunningUnitTests" }

project "SampleMazeSDL2"
    kind "ConsoleApp"
    files { "samples/maze_sdl2/**.d", "deps/DerelictUtil/source/**.d", "deps/DerelictSDL2/source/**.d", "deps/DerelictGL3/source/**.d" }
    links "sbxs"

project "SampleMazeAllegro5"
    kind "ConsoleApp"
    files { "samples/maze_allegro5/**.d", "deps/DerelictUtil/source/**.d", "deps/DerelictAllegro5/source/**.d", "deps/DerelictGL3/source/**.d" }
    links "sbxs"
