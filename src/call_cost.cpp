#include "call_cost.h"

#include <godot_cpp/core/class_db.hpp>

using namespace godot;

void CallCost::_bind_methods() {
	ClassDB::bind_method(D_METHOD("add_one", "value"), &CallCost::add_one);
	ClassDB::bind_method(D_METHOD("sum_packed", "values"), &CallCost::sum_packed);
	ClassDB::bind_method(D_METHOD("sum_range", "count"), &CallCost::sum_range);
}

int64_t CallCost::add_one(int64_t p_value) const {
	return p_value + 1;
}

double CallCost::sum_packed(const PackedFloat64Array &p_values) const {
	const double *ptr = p_values.ptr();
	const int64_t size = p_values.size();
	double total = 0.0;
	for (int64_t i = 0; i < size; i++) {
		total += ptr[i];
	}
	return total;
}

double CallCost::sum_range(int64_t p_count) const {
	double total = 0.0;
	for (int64_t i = 0; i < p_count; i++) {
		total += double(i) * 0.5;
	}
	return total;
}
