class_name DwellerNavigation
extends RefCounted

var _dweller: Dweller


func _init(dweller: Dweller) -> void:
	_dweller = dweller


func calculate_path(target_room: AbstractRoom) -> MapPath:
	"""Compute a MapPath towards the target room and update room bindings."""
	if _dweller == null or target_room == null:
		return null

	var matrix: Matrix = _dweller.get_matrix()
	if matrix == null:
		return null

	var start_cell: Vector2i = _dweller.get_matrix_cell()
	var destination_cell: Vector2i = _dweller.get_room_entry_cell(target_room)

	var path: MapPath = _dweller.best_path(start_cell, destination_cell)
	if path == null:
		return null

	_assign_room(target_room)
	return path


func cancel(clear_assignment: bool = false) -> void:
	if clear_assignment and _dweller.assigned_room != null:
		_dweller.assigned_room._forget_dweller(_dweller)
		_dweller.assigned_room = null


func _assign_room(target_room: AbstractRoom) -> void:
	var previous_room: AbstractRoom = _dweller.assigned_room
	if previous_room != null and previous_room != target_room:
		previous_room._forget_dweller(_dweller)

	_dweller.assigned_room = target_room
	target_room._register_dweller(_dweller)
