extends Node3D

class_name Entity


var is_outside: bool = true


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
