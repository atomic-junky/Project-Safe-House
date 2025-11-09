class_name Navigation
extends RefCounted

## Navigation component - pure data consumed by systems/Dweller bridge

enum NavState { IDLE, TRAVELING, ARRIVED }

var current_state: NavState = NavState.IDLE
var target_room: AbstractRoom = null
var current_room: AbstractRoom = null
var map_path: MapPath = null
var current_target_pos: Vector3 = Vector3.ZERO
var is_waiting: bool = false
var waiting_reason: StringName = &""


func reset() -> void:
	"""Reset navigation data to its default state."""
	current_state = NavState.IDLE
	target_room = null
	map_path = null
	current_target_pos = Vector3.ZERO
	is_waiting = false
	waiting_reason = &""
