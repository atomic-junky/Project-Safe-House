class_name RoomEntity extends Node
## Modular room entity using component-based architecture.
##
## This class represents a room in the vault, using composition instead of inheritance.
## Rooms are configured with components and data resources for flexibility and reusability.


## Signal emitted when room is destroyed
signal room_destroyed(room: RoomEntity)

## Signal emitted when room size changes
signal room_resized(new_size: int)


## Unique identifier for this room instance
var id: String = UUID.v4()

## Room data resource containing static room properties
var room_data: RoomData

## Grid positions this room occupies
var positions: Array[Vector2] = []

## Region reference for pathfinding
var region

## Reference to the matrix this room belongs to
var _matrix: Matrix

## Components
var workspace: WorkspaceComponent
var production: ProductionComponent
var upgrade: UpgradeComponent
var visual: VisualComponent


## Current room size (number of tiles)
var size: int:
	get:
		return len(positions)


## Room mesh based on size
var mesh: Dictionary:
	get:
		if visual:
			return visual.get_current_mesh()
		return {}


## Room node reference (delegated to visual component)
var room_node: Node3D:
	get:
		return visual.room_node if visual else null
	set(value):
		if visual:
			visual.set_room_node(value)


## Room position (delegated to visual component)
var position: Vector3:
	get:
		return visual.get_position() if visual else Vector3.ZERO


## Room global position (delegated to visual component)
var global_position: Vector3:
	get:
		return visual.get_global_position() if visual else Vector3.ZERO


## Initialize the room with data and components
func _init(data: RoomData = null) -> void:
	if data:
		room_data = data
		name = data.room_name
	
	_setup_components()
	
	Logger.info("Room(" + id + ") created: " + (room_data.room_name if room_data else "Unknown"))


## Set up default components
func _setup_components() -> void:
	# Create workspace component
	workspace = WorkspaceComponent.new()
	workspace.name = "WorkspaceComponent"
	add_child(workspace)
	
	# Create visual component
	visual = VisualComponent.new()
	visual.name = "VisualComponent"
	add_child(visual)
	
	if room_data:
		visual.setup_meshes(room_data.meshes)
	
	# Create upgrade component
	upgrade = UpgradeComponent.new()
	upgrade.name = "UpgradeComponent"
	if room_data:
		upgrade.base_upgrade_cost = room_data.build_cost
		upgrade.max_level = 3
	add_child(upgrade)


## Get a component by type
func get_component(component_type) -> Component:
	for child in get_children():
		if is_instance_of(child, component_type):
			return child
	return null


## Register a dweller to work in this room
func register_dweller(dweller: Dweller) -> bool:
	if not workspace:
		return false
	return workspace.register_dweller(dweller, size)


## Remove a dweller from this room
func forget_dweller(dweller: Dweller) -> void:
	if workspace:
		workspace.forget_dweller(dweller, size)


## Check if a dweller is working here
func has_dweller(dweller: Dweller) -> bool:
	if not workspace:
		return false
	return workspace.has_dweller(dweller, size)


## Check if the room is full
func is_full() -> bool:
	if not workspace:
		return false
	return workspace.is_full(size)


## Get work position for a dweller
func get_work_position(dweller: Dweller) -> Vector3:
	if not workspace:
		return Vector3.ZERO
	return workspace.get_work_position(dweller, size)


## Get navigation region
func get_navigation_region() -> NavigationRegion3D:
	if visual:
		return visual.get_navigation_region()
	return null


## Sort positions helper
func _sort_positions(a: Vector2, b: Vector2) -> bool:
	if a.x < b.x:
		return true
	return false


## Get the first position (leftmost)
func get_first_position() -> Vector2:
	if positions.is_empty():
		return Vector2.ZERO
	
	var result = positions.duplicate()
	result.sort_custom(_sort_positions)
	return result[0]


## Destroy this room
func destroy() -> void:
	if _matrix:
		_matrix.remove_room(self)
	room_destroyed.emit(self)


## Upgrade the room
func do_upgrade() -> bool:
	if upgrade:
		return upgrade.upgrade()
	return false


## Check if room can be destroyed
func can_be_destroyed() -> bool:
	if not room_data or not room_data.destroyable:
		return false
	
	# Check if destroying this room would disconnect parts of the vault
	if not _matrix:
		return true
	
	var astar: AStar2D = _matrix._build_astar_path()
	var end_index = Matrix._vector_to_astar_id(_matrix.get_start_room().positions[0])
	
	# Temporarily remove this room's points from the pathfinding
	for pos in positions:
		var s_index = Matrix._vector_to_astar_id(pos)
		astar.remove_point(s_index)
	
	# Check if neighbors can still reach the vault door
	var neighbors = [
		_matrix.get_room_at(positions[0].x - 1, positions[0].y),
		_matrix.get_room_at(positions.back().x + 1, positions.back().y)
	]
	
	# If this is an elevator, also check vertical neighbors
	if self is ElevatorShaft:
		neighbors.append_array([
			_matrix.get_room_at(positions[0].x, positions[0].y - 1),
			_matrix.get_room_at(positions.back().x, positions.back().y + 1)
		])
	
	for neighbor in neighbors:
		if neighbor == null or neighbor is EmptyLocation:
			continue
		
		var start_index = Matrix._vector_to_astar_id(neighbor.positions[0])
		if astar.get_point_path(start_index, end_index).size() <= 0:
			return false
	
	return true
