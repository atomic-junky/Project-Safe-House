class_name WorkspaceComponent
extends "res://scripts/components/Component.gd"

@export var max_workers: int = 1

var _spots: Array[Vector3] = []
var _assignments: Dictionary[String, Vector3] = {}


func _initialize() -> void:
	_spots.clear()
	_assignments.clear()


func _cleanup() -> void:
	_assignments.clear()


func add_spot(local_position: Vector3) -> void:
	if _spots.size() >= max_workers:
		return
	_spots.append(local_position)


func assign(dweller_id: String) -> Vector3:
	if _assignments.has(dweller_id):
		return _assignments[dweller_id]
	if _assignments.size() >= _spots.size():
		return Vector3.ZERO
	var next_spot: Vector3 = _spots[_assignments.size()]
	_assignments[dweller_id] = next_spot
	return next_spot


func release(dweller_id: String) -> void:
	_assignments.erase(dweller_id)


func is_full() -> bool:
	return _assignments.size() >= min(_spots.size(), max_workers)


func has(dweller_id: String) -> bool:
	return _assignments.has(dweller_id)
