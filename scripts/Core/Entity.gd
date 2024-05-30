class_name Entity
extends Node3D


@export var machine: StateMachine

signal elevator_transfer

@onready var _agent: NavigationAgent3D = get_node_or_null("NavigationAgent3D")

var vel: Vector3 = Vector3.ZERO

var id: String = UUID.v4()

var assigned_room = null
var is_traveling = false

var map_path: MapPath

var matrix_position:
	get:
		var shelter_map = get_tree().current_scene.find_child("SceneMap")
		var z = floori((position.z/ shelter_map.cell_size.z)*-1) # x axis
		var y = roundi((position.y)/ shelter_map.cell_size.y) # y axis
		return Vector2i(z, y)


func _ready():
	pass


func best_path(start, end) -> MapPath:
	var parent = _get_main_parent()

	var scene_map = get_tree().current_scene.find_child("AutoSceneMap")
	var cell_size = scene_map.cell_size

	var matrix: Matrix = parent._matrix
	
	var astar = matrix._build_astar_path()
	
	var start_index = Matrix._vector_to_astar_id(start)
	var end_index = Matrix._vector_to_astar_id(end)

	return MapPath.new(astar, start_index, end_index, cell_size, matrix)


func _get_main_parent():
	return get_parent().get_parent()


func _vector_to_id(vec):
	return int(str(vec.y) + str(vec.x))


func move_to_position(delta: float, target_pos: Vector3, h_speed: float=1.5, v_speed: float=0.5):
	# vel.x = appr(vel.x, h_speed, .05)
	# vel.y = appr(vel.y, v_speed, .05)
	# vel.z = appr(vel.z, h_speed, .05)

	# global_position.y = move_toward(global_position.y, target_pos.y, delta * vel.y)
	# global_position.z = move_toward(global_position.z, target_pos.z, delta * vel.z)
	# global_position.x = move_toward(global_position.x, target_pos.x, delta * vel.x)
	global_position.y = move_toward(global_position.y, target_pos.y, delta * v_speed)
	global_position.z = move_toward(global_position.z, target_pos.z, delta * h_speed)
	global_position.x = move_toward(global_position.x, target_pos.x, delta * h_speed)

	
func appr(val: float, target: float, amount: float):
	return max(val-amount, target) if val >= target else min(val+amount, target)


func _get_navigation_agent():
	return _agent