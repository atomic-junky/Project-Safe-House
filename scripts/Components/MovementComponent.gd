class_name MovementComponent extends Component
## Component that handles dweller movement and pathfinding.
##
## This component manages navigation, path calculation, and movement behavior.


## Signal emitted when dweller reaches destination
signal destination_reached

## Signal emitted when dweller starts moving
signal movement_started

## Signal emitted when path changes
signal path_updated(new_path: MapPath)


## Movement speeds
const MAX_HORIZONTAL_SPEED: float = 1.5
const MAX_VERTICAL_SPEED: float = 0.5

## Navigation agent reference
var navigation_agent: NavigationAgent3D

## Current movement path
var current_path: MapPath

## Whether dweller is currently traveling
var is_traveling: bool = false

## Current velocity
var velocity: Vector3 = Vector3.ZERO


## Initialize the movement component
func _initialize() -> void:
	super._initialize()
	navigation_agent = entity.get_node_or_null("NavigationAgent3D")


## Calculate best path from start to end position
func calculate_path(start: Vector2i, end: Vector2i) -> MapPath:
	var shelter_entity = _get_shelter()
	if not shelter_entity:
		return null
	
	var matrix: Matrix = shelter_entity._matrix
	var scene_map = _get_scene_map()
	
	if not scene_map:
		return null
	
	var cell_size = scene_map.cell_size
	var astar = matrix._build_astar_path()
	
	var start_index = Matrix._vector_to_astar_id(start)
	var end_index = Matrix._vector_to_astar_id(end)
	
	return MapPath.new(astar, start_index, end_index, cell_size, matrix)


## Set a new path for the dweller
func set_path(path: MapPath) -> void:
	current_path = path
	is_traveling = true
	path_updated.emit(path)
	movement_started.emit()


## Move towards a target position
func move_to_position(delta: float, target_pos: Vector3, 
					  h_speed: float = MAX_HORIZONTAL_SPEED, 
					  v_speed: float = MAX_VERTICAL_SPEED) -> void:
	if not entity is Node3D:
		return
	
	entity.global_position.y = move_toward(entity.global_position.y, target_pos.y, delta * v_speed)
	entity.global_position.z = move_toward(entity.global_position.z, target_pos.z, delta * h_speed)
	entity.global_position.x = move_toward(entity.global_position.x, target_pos.x, delta * h_speed)
	
	# Update body facing direction
	_update_facing_direction(target_pos)


## Update which direction the dweller is facing
func _update_facing_direction(target_pos: Vector3) -> void:
	var body_node = entity.get_node_or_null("Body")
	if not body_node:
		return
	
	if target_pos.z > entity.global_position.z:
		body_node.scale.x = -1
	elif target_pos.z < entity.global_position.z:
		body_node.scale.x = 1


## Stop movement
func stop_movement() -> void:
	is_traveling = false
	velocity = Vector3.ZERO
	current_path = null
	destination_reached.emit()


## Get the shelter core node
func _get_shelter() -> Node:
	return entity.get_parent().get_parent()


## Get the scene map
func _get_scene_map() -> Node:
	return entity.get_tree().current_scene.find_child("AutoSceneMap")


## Get matrix position of the dweller
func get_matrix_position() -> Vector2i:
	if not entity is Node3D:
		return Vector2i.ZERO
	
	var shelter_map = entity.get_tree().current_scene.find_child("SceneMap")
	if not shelter_map:
		return Vector2i.ZERO
	
	var z = floori((entity.position.z / shelter_map.cell_size.z) * -1)
	var y = roundi((entity.position.y) / shelter_map.cell_size.y)
	return Vector2i(z, y)


## Check if close enough to target
func is_at_position(target: Vector3, threshold: float = 0.1) -> bool:
	if not entity is Node3D:
		return false
	return entity.global_position.distance_to(target) < threshold
