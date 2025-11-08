class_name BuildManager extends Node
## Manager for build mode and room construction.
##
## This manager handles build mode UI, build location highlighting,
## and room construction placement.


## Signal emitted when build mode is enabled
signal build_mode_enabled(room_type: int)

## Signal emitted when build mode is disabled
signal build_mode_disabled

## Signal emitted when a build location is shown
signal build_location_shown(x: int, y: int)

## Signal emitted when build locations are cleared
signal build_locations_cleared


## Reference to the matrix
var matrix: Matrix

## Reference to the scene map
var scene_map: AutoSceneMap

## Reference to the room manager
var room_manager: RoomManager

## Currently selected room type for building
var selected_room_type: int = -1

## Whether build mode is active
var is_build_mode_active: bool = false


## Initialize the build manager
func _init(matrix_ref: Matrix, scene_map_ref: AutoSceneMap, room_mgr: RoomManager) -> void:
	matrix = matrix_ref
	scene_map = scene_map_ref
	room_manager = room_mgr


## Enable build mode for a specific room type
func enable_build_mode(room_type: int) -> void:
	selected_room_type = room_type
	is_build_mode_active = true
	
	# Show valid build locations
	_show_build_locations(room_type)
	
	build_mode_enabled.emit(room_type)


## Disable build mode
func disable_build_mode() -> void:
	selected_room_type = -1
	is_build_mode_active = false
	
	# Clear build location highlights
	_clear_build_locations()
	
	build_mode_disabled.emit()


## Attempt to build a room at the specified position
func build_room_at(x: int, y: int) -> bool:
	if not is_build_mode_active:
		return false
	
	if not room_manager.is_valid_build_location(x, y, selected_room_type):
		return false
	
	# Create the room
	var room = _create_room_from_type(selected_room_type)
	if not room:
		return false
	
	# Add to matrix
	var success = room_manager.add_room(room, [Vector2(x, y)])
	
	if success:
		disable_build_mode()
	
	return success


## Create a room instance from room type
func _create_room_from_type(room_type: int) -> RoomEntity:
	var room_class = RoomPicker.pick(room_type)
	if room_class:
		return room_class.new()
	return null


## Show valid build locations for a room type
func _show_build_locations(room_type: int) -> void:
	if not matrix or not scene_map:
		return
	
	for y in matrix.size.y:
		for x in matrix.size.x:
			if room_manager.is_valid_build_location(x, y, room_type):
				_place_build_location(x, y)
				build_location_shown.emit(x, y)


## Place a build location marker
func _place_build_location(x: int, y: int) -> void:
	if not scene_map or not matrix:
		return
	
	var coordinate = Vector3i(
		0, matrix.size.y - y - 1, -x
	)
	
	scene_map.set_cell_item(coordinate, MeshLink._meshes.BUILD_LOCATION.name)


## Clear all build location markers
func _clear_build_locations() -> void:
	if not scene_map:
		return
	
	# Remove all build location meshes
	var item_id = scene_map._get_item_index(MeshLink._meshes.BUILD_LOCATION.name)
	
	# Get all cells with build locations and remove them
	var cells_to_remove = []
	for cell in scene_map.get_used_cells():
		if scene_map.get_cell_item(cell) == item_id:
			cells_to_remove.append(cell)
	
	for cell in cells_to_remove:
		scene_map.set_cell_item(cell, -1)
	
	build_locations_cleared.emit()


## Check if position is valid for current build mode
func is_valid_position(x: int, y: int) -> bool:
	if not is_build_mode_active:
		return false
	
	return room_manager.is_valid_build_location(x, y, selected_room_type)
