class_name RoomManager extends Node
## Manager for room placement, removal, and updates.
##
## This manager handles all room-related operations in the vault,
## separating concerns from the main Shelter controller.


## Signal emitted when a room is added
signal room_added(room: RoomEntity)

## Signal emitted when a room is removed
signal room_removed(room: RoomEntity)

## Signal emitted when rooms need visual update
signal rooms_updated


## Reference to the matrix
var matrix: Matrix

## Reference to the scene map
var scene_map: AutoSceneMap

## Reference to the shelter core
var shelter: Node3D


## Initialize the room manager
func _init(shelter_node: Node3D, matrix_ref: Matrix, scene_map_ref: AutoSceneMap) -> void:
	shelter = shelter_node
	matrix = matrix_ref
	scene_map = scene_map_ref
	
	if matrix:
		matrix.room_removed.connect(_on_matrix_room_removed)


## Add a room to the vault
func add_room(room: RoomEntity, positions: Array[Vector2]) -> bool:
	if not matrix:
		return false
	
	var success = matrix.add_room(room, positions)
	
	if success:
		if room.get_parent() != shelter:
			shelter.add_child(room)
		room_added.emit(room)
	
	return success


## Remove a room from the vault
func remove_room(room: RoomEntity) -> bool:
	if not matrix:
		return false
	
	if not room.can_be_destroyed():
		return false
	
	matrix.remove_room(room)
	room_removed.emit(room)
	return true


## Update all room visuals in the scene
func update_room_visuals() -> void:
	if not scene_map or not matrix:
		return
	
	scene_map.clear()
	
	for y in range(matrix.size.y):
		for z in range(matrix.size.x):
			var room = matrix.get_room_at_first_position(z, y)
			
			# Place dirt if no room
			if room == null or room is EmptyLocation:
				if not matrix._is_room_at(z, y):
					_place_room_mesh(y, z, MeshLink._meshes.DIRT.name)
				continue
			
			# Place room mesh
			if room.get_parent() != shelter:
				shelter.add_child(room)
			
			_place_room_mesh(y, z, room.mesh.name, room)
	
	rooms_updated.emit()


## Place a room mesh in the scene map
func _place_room_mesh(y: int, z: int, mesh_name: String, room: RoomEntity = null) -> void:
	var coordinate = Vector3i(
		0, matrix.size.y - y - 1, -z
	)
	
	scene_map.set_cell_item(coordinate, mesh_name)
	
	if room != null and room.visual:
		var node = scene_map._get_cell_node(coordinate)
		room.visual.set_room_node(node)


## Get room at specific position
func get_room_at(x: int, y: int) -> RoomEntity:
	if matrix:
		return matrix.get_room_at(x, y)
	return null


## Check if a position is valid for building
func is_valid_build_location(x: int, y: int, room_type: int) -> bool:
	if not matrix:
		return false
	
	var room = matrix.get_room_at(x, y)
	if room != null and not (room is EmptyLocation):
		return false
	
	var prev_room = matrix.get_room_at(x - 1, y) if x > 0 else null
	var next_room = matrix.get_room_at(x + 1, y) if x < matrix.size.x else null
	var top_room = matrix.get_room_at(x, y - 1) if y > 0 else null
	var bottom_room = matrix.get_room_at(x, y + 1) if y < matrix.size.y else null
	
	# Elevator can only connect vertically
	if room_type == RoomList.ELEVATOR:
		if (top_room != null and top_room is ElevatorShaft) or \
		   (bottom_room != null and bottom_room is ElevatorShaft):
			return true
		return false
	
	# Other rooms need horizontal connection
	if prev_room != null or next_room != null:
		return true
	
	return false


## Handle room removal from matrix
func _on_matrix_room_removed() -> void:
	update_room_visuals()
