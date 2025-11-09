@abstract
class_name ShelterEntity extends Node3D

@warning_ignore("unused_signal")
signal elevator_transfer

@export var machine: StateMachine

var vel: Vector3 = Vector3.ZERO
var id: String = UUID.v4()

var assigned_room: AbstractRoom

var map_path: MapPath

@onready var _agent: NavigationAgent3D = get_node_or_null("NavigationAgent3D")
@onready var _shelter: Shelter = _resolve_shelter()
@onready var _auto_scene_map: AutoSceneMap = _resolve_auto_scene_map()


func best_path(start: Vector2i, end: Vector2i) -> MapPath:
	var matrix: Matrix = get_matrix()
	if matrix == null:
		return null

	var astar: AStar2D = matrix._build_astar_path()
	var cell_size: Vector3 = get_cell_size()

	var start_index: int = Matrix._vector_to_astar_id(start)
	var end_index: int = Matrix._vector_to_astar_id(end)

	return MapPath.new(astar, start_index, end_index, cell_size, matrix)


func _get_main_parent() -> Node3D:
	return _shelter if _shelter else get_parent().get_parent()


func get_matrix_position() -> Vector2i:
	var cell_size: Vector3 = get_cell_size()
	if cell_size == Vector3.ZERO:
		return Vector2i.ZERO

	var z: int = 0
	var y: int = 0

	if !is_zero_approx(cell_size.z):
		z = floori((global_position.z / cell_size.z) * -1)
	if !is_zero_approx(cell_size.y):
		y = roundi(global_position.y / cell_size.y)

	return Vector2i(z, y)


func get_matrix_cell() -> Vector2i:
	var matrix: Matrix = get_matrix()
	if matrix == null:
		return Vector2i.ZERO

	var max_height := int(matrix.size.y)
	var grid_pos: Vector2i = get_matrix_position()
	return Vector2i(grid_pos.x, max_height - grid_pos.y - 1)


func get_room_entry_cell(room: AbstractRoom) -> Vector2i:
	if room == null or room.positions.is_empty():
		return Vector2i.ZERO
	var base: Vector2 = room.positions[0]
	return Vector2i(int(base.x), int(base.y))


func get_matrix_height() -> int:
	var matrix: Matrix = get_matrix()
	return int(matrix.size.y) if matrix != null else 0


func move_to_position(
	delta: float, target_pos: Vector3, h_speed: float = 1.5, v_speed: float = 0.5
) -> void:
	global_position.y = move_toward(global_position.y, target_pos.y, delta * v_speed)
	global_position.z = move_toward(global_position.z, target_pos.z, delta * h_speed)
	global_position.x = move_toward(global_position.x, target_pos.x, delta * h_speed)

	var body_node: Node3D = get_node_or_null("Body")
	if !body_node:
		return

	if target_pos.z > global_position.z:
		body_node.scale.x = -1
	elif target_pos.z < global_position.z:
		body_node.scale.x = 1


func appr(val: float, target: float, amount: float) -> float:
	return max(val - amount, target) if val >= target else min(val + amount, target)


func _get_navigation_agent() -> NavigationAgent3D:
	return _agent


func get_shelter() -> Shelter:
	return _shelter


func get_auto_scene_map() -> AutoSceneMap:
	return _auto_scene_map


func get_matrix() -> Matrix:
	if _shelter == null:
		return null
	if _shelter.has_method("get_matrix"):
		return _shelter.get_matrix()
	return _shelter._matrix if "_matrix" in _shelter else null


func get_cell_size() -> Vector3:
	if _auto_scene_map != null:
		return _auto_scene_map.get_cell_size()
	return Vector3.ONE


func _resolve_shelter() -> Shelter:
	var current: Node = self
	while current:
		if current is Shelter:
			return current
		current = current.get_parent()
	return null


func _resolve_auto_scene_map() -> AutoSceneMap:
	var shelter: Shelter = _shelter if _shelter else _resolve_shelter()
	if shelter == null:
		return null
	return shelter.get_node_or_null("AutoSceneMap") as AutoSceneMap


@abstract func is_traveling() -> bool
