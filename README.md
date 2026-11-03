# gdext-call-cost

I wanted to know when it is actually worth moving GDScript code into a C++ GDExtension, so I built a tiny extension with [godot-cpp](https://github.com/godotengine/godot-cpp) and timed it against plain GDScript in Godot 4.7.2.

The extension (`src/call_cost.cpp`) exposes one class, `CallCost`, with three methods:

- `add_one(int)`: does almost nothing, so timing it measures the cost of the call itself
- `sum_packed(PackedFloat64Array)`: sums an array in one call
- `sum_range(int)`: a numeric loop in one call

`project/bench.gd` runs each case 7 times over N = 1,000,000 items and prints the median. It also checks that `sum_packed` matches the GDScript sum.

## Results

Godot 4.7.2-stable official editor binary, run headless on an Apple Silicon Mac. Extension built with `target=template_release`, godot-cpp at `e103d34` with `api_version=4.7`.

| Case | ms for 1M | ns per item |
| --- | ---: | ---: |
| Empty GDScript loop (baseline) | 6.3 | 6.3 |
| Call a GDScript function `add_one` 1M times | 49.0 | 49.0 |
| Call `CallCost.add_one` 1M times, typed variable | 13.0 | 13.0 |
| Call `CallCost.add_one` 1M times, untyped variable | 57.5 | 57.5 |
| Sum a PackedFloat64Array in a GDScript loop | 6.7 | 6.7 |
| `CallCost.sum_packed` (one call) | 0.46 | 0.46 |
| Numeric loop in GDScript | 10.8 | 10.8 |
| `CallCost.sum_range` (one call) | 0.53 | 0.53 |

What I took from this:

- Calling into a GDExtension from GDScript is cheap if the variable is typed (`var cc: CallCost`). In my run it was about 3.8x cheaper than calling a GDScript function.
- The same call through an untyped variable was about 4.4x slower than the typed one, and a bit slower than calling a GDScript function. My understanding is that a typed variable lets GDScript call the method directly instead of going through the generic Variant call.
- Moving a whole loop into C++ is where the big win is: about 15x and 20x for these two loops, because the per-item work never crosses the boundary.

Numbers moved by a few percent between runs; the ordering was the same every time.

## Build profiles

godot-cpp can generate bindings for only the engine classes you list in a build profile. This extension only needs `RefCounted`, so I compared a full build with a trimmed one (clean build each time, `scons -j8 platform=macos target=template_release`, universal binary):

| | Full bindings | Build profile |
| --- | ---: | ---: |
| Build time | 93 s | 5 s |
| `libgodot-cpp` static library | 82.7 MB | 3.1 MB |
| Final extension binary | 298,544 bytes | 298,528 bytes |

The final binary barely changes because the linker already drops unused code, so the profile mostly saves build time.

One thing I ran into: a profile with only `"enabled_classes": ["RefCounted"]` fails to compile:

```
godot-cpp/src/core/print_string.cpp:33:10: fatal error: 'godot_cpp/classes/os.hpp' file not found
```

`src/core/print_string.cpp` includes `os.hpp`, but `build_profile.py` doesn't add `OS` to the classes it always keeps (it does for `ClassDB`, `FileAccess`, `Image` and a few others). Adding `"OS"` to the profile works around it, which is what `build_profile.json` here does.

## Running it

```
git clone --recursive https://github.com/Mohith26/gdext-call-cost
cd gdext-call-cost
pip install scons
scons platform=macos target=template_release build_profile=build_profile.json
godot --headless --path project --script res://bench.gd
```

The `.gdextension` file points both debug and release at the release build, since the official editor binary loads the debug entry. Only macOS was tested.
