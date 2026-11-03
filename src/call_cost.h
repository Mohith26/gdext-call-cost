#pragma once

#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/variant/packed_float64_array.hpp>

namespace godot {

// A few deliberately tiny methods, so the benchmark measures the cost of calling
// into a GDExtension from GDScript rather than the work done inside the call.
class CallCost : public RefCounted {
	GDCLASS(CallCost, RefCounted);

protected:
	static void _bind_methods();

public:
	int64_t add_one(int64_t p_value) const;
	double sum_packed(const PackedFloat64Array &p_values) const;
	double sum_range(int64_t p_count) const;
};

} // namespace godot
