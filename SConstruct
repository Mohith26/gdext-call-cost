#!/usr/bin/env python
# Builds the CallCost GDExtension against godot-cpp, targeting the Godot 4.7 API.
env = SConscript("godot-cpp/SConstruct", {"api_version": "4.7"})

env.Append(CPPPATH=["src/"])
sources = Glob("src/*.cpp")

if env["platform"] == "macos":
    library = env.SharedLibrary(
        "project/bin/libcallcost.{}.{}.framework/libcallcost.{}.{}".format(
            env["platform"], env["target"], env["platform"], env["target"]
        ),
        source=sources,
    )
else:
    library = env.SharedLibrary(
        "project/bin/libcallcost{}{}".format(env["suffix"], env["SHLIBSUFFIX"]),
        source=sources,
    )

Default(library)
