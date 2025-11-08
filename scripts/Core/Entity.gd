class_name ShelterEntity
extends Node3D

@warning_ignore("unused_signal")
signal elevator_transfer

@export var machine: StateMachine

var vel: Vector3 = Vector3.ZERO
var id: String = UUID.v4()

var assigned_room: AbstractRoom
var is_traveling: bool = false

var map_path: MapPath

@onready var _agent: NavigationAgent3D = get_node_or_null("NavigationAgent3D")

func best_path(start: Vector2i, end: Vector2i) -> MapPath:
	var parent: Node3D = _get_main_parent()

	var scene_map: SceneMap = get_tree().current_scene.find_child("SceneMap")
	var cell_size: Vector3 = scene_map.cell_size

	var matrix: Matrix = parent._matrix

	var astar: AStar2D = matrix._build_astar_path()

	var start_index: int = Matrix._vector_to_astar_id(start)
	var end_index: int = Matrix._vector_to_astar_id(end)

	return MapPath.new(astar, start_index, end_index, cell_size, matrix)


func _get_main_parent() -> Node3D:
	return get_parent().get_parent()


func _vector_to_id(vec: Vector2i) -> int:
	return int(str(vec.y) + str(vec.x))


func get_matrix_position() -> Vector2i:
	var shelter_map: SceneMap = get_tree().current_scene.find_child("SceneMap")
	var z: int = floori((position.z / shelter_map.cell_size.z) * -1)
	var y: int = roundi((position.y) / shelter_map.cell_size.y)
	return Vector2i(z, y)


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
