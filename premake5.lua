workspace "SBXS"
    configurations { "Test" }
    location "build"
    filter "configurations:Test"
        buildoptions {"-unittest"}

project "UnitTests"
    language "D"
    kind "ConsoleApp"
    files {"src/run_unit_tests.d", "src/sbxs/**.d"}
