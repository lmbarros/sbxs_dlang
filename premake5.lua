workspace "SBXS"
    language "D"
    configurations { "Test" }
    location "build"
    filter "configurations:Test"
        flags { "UnitTest", "CodeCoverage" }
        optimize "Off"

project "UnitTests"
    kind "ConsoleApp"
    files {"src/run_unit_tests.d", "src/sbxs/**.d"}
    targetdir "build"
