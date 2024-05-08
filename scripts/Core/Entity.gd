class_name Entity
extends Node3D


@export var machine: StateMachine

signal elevator_transfer

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


func move_to_position(delta: float, target_pos: Vector3, speed: float):
	global_position.y = move_toward(global_position.y, target_pos.y, delta * speed)
	global_position.z = move_toward(global_position.z, target_pos.z, delta * speed)
	global_position.x = move_toward(global_position.x, target_pos.x, delta * speed)
