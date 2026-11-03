extends SceneTree
# Run with: godot --headless --path project --script res://bench.gd
# Compares doing small amounts of work in GDScript vs calling into a godot-cpp GDExtension.

const N := 1_000_000
const RUNS := 7

func gd_add_one(v: int) -> int:
	return v + 1

func median(xs: Array) -> float:
	xs.sort()
	return xs[xs.size() / 2]

func time_usec(c: Callable) -> float:
	var samples := []
	for r in RUNS:
		var t0 := Time.get_ticks_usec()
		c.call()
		samples.append(float(Time.get_ticks_usec() - t0))
	return median(samples)

func _init() -> void:
	var cc = ClassDB.instantiate("CallCost")
	if cc == null:
		push_error("CallCost class not found; is the extension built?")
		quit(1)
		return
	var typed: CallCost = cc
	var values := PackedFloat64Array()
	values.resize(N)
	for i in N:
		values[i] = float(i) * 0.5

	var results := {}
	# Baseline: an empty loop, so per-call numbers can be read with the loop cost in mind.
	results["empty loop"] = time_usec(func():
		var acc := 0
		for i in N:
			acc += i
	)
	results["GDScript func add_one x N"] = time_usec(func():
		var acc := 0
		for i in N:
			acc = gd_add_one(acc)
	)
	results["GDExtension add_one x N (typed)"] = time_usec(func():
		var acc := 0
		for i in N:
			acc = typed.add_one(acc)
	)
	results["GDExtension add_one x N (untyped Variant)"] = time_usec(func():
		var acc := 0
		for i in N:
			acc = cc.add_one(acc)
	)
	results["GDScript sum over PackedFloat64Array"] = time_usec(func():
		var s := 0.0
		for v in values:
			s += v
	)
	results["GDExtension sum_packed (1 call)"] = time_usec(func():
		var s: float = typed.sum_packed(values)
	)
	results["GDScript sum_range loop"] = time_usec(func():
		var s := 0.0
		for i in N:
			s += float(i) * 0.5
	)
	results["GDExtension sum_range (1 call)"] = time_usec(func():
		var s: float = typed.sum_range(N)
	)

	# Sanity: both paths compute the same thing.
	var gd_sum := 0.0
	for v in values:
		gd_sum += v
	print("check sum_packed matches: ", is_equal_approx(gd_sum, typed.sum_packed(values)))
	print("check add_one: ", typed.add_one(41) == 42)

	print("Godot ", Engine.get_version_info().string, ", N = ", N, ", median of ", RUNS, " runs")
	for k in results:
		var us: float = results[k]
		print("%-45s %10.2f ms  %8.2f ns/item" % [k, us / 1000.0, us * 1000.0 / N])
	quit(0)
