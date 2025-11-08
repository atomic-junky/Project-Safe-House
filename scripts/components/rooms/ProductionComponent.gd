class_name ProductionComponent
extends "res://scripts/components/Component.gd"

@export var resource_type: String = ""
@export var base_output_per_minute: float = 0.0
@export var efficiency_multiplier: float = 1.0

var _accumulator: float = 0.0


func _initialize() -> void:
	_accumulator = 0.0


func _update(delta: float) -> void:
	_accumulator += delta * _per_second_yield()


func _cleanup() -> void:
	_accumulator = 0.0


func consume_yield() -> float:
	var amount: float = _accumulator
	_accumulator = 0.0
	return amount


func _per_second_yield() -> float:
	if base_output_per_minute <= 0.0:
		return 0.0
	return (base_output_per_minute / 60.0) * max(efficiency_multiplier, 0.0)
