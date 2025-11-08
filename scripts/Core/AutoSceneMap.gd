class_name AutoSceneMap
extends Node3D

@onready var _scene_map: SceneMap = $SceneMap


func _ready() -> void:
	var pal: ScenePalette = GlobalRoomManager.build_palette()
	_scene_map.palette = pal

	_scene_map.cell_size = Vector3(2, 2, 3)


# Clear all cells of the SceneMap.
func clear():
	for coordinate in _get_coordinates():
		_scene_map._remove_instance(coordinate)


func _get_coordinates():
	return _scene_map.cell_map.keys()


func _get_item_index(item_name: String) -> int:
	for index in _scene_map.palette.items:
		var palette_item_name = _scene_map.palette.get_item_name(index)

		if palette_item_name == item_name:
			return index
	return -1


func _get_cell(item_id: int):
	for key in _scene_map.cell_map.keys():
		var cell = _scene_map.cell_map[key]
		if cell.itemId == item_id:
			return key


func set_cell_item(
	p_coordinate: Vector3, p_item_name: String, p_orientation: Quaternion = Quaternion.IDENTITY
) -> bool:
	var p_item_id = _get_item_index(p_item_name)
	return _scene_map.set_cell_item(p_coordinate, p_item_id, p_orientation, p_item_name)


func _remove_instance(coordinate: Vector3) -> bool:
	return _scene_map._remove_instance(coordinate)


func get_cell(p_coordinate: Vector3):
	var coordinate = p_coordinate.floor()

	if _scene_map.cell_map.has(coordinate):
		var data := _scene_map.cell_map.get(coordinate) as Dictionary
		return data


func _get_cell_node(p_coordinate: Vector3):
	var coordinate = p_coordinate.floor()

	if _scene_map.cell_map.has(coordinate):
		var data := _scene_map.cell_map.get(coordinate) as Dictionary
		return _scene_map.get_node(data.path)


func get_cell_size() -> Vector3:
	return _scene_map.cell_size


func get_cell_position(coordinate: Vector3) -> Vector3:
	return _scene_map.get_cell_position(coordinate)


func add_temporary_node(node: Node3D, coordinate: Vector3) -> Node3D:
	if node == null:
		return null
	var spatial := node as Node3D
	if spatial == null:
		node.queue_free()
		return null
	spatial.position = _scene_map.get_cell_position(coordinate)
	_scene_map.add_child(spatial, true)

	var parent: Node = self
	while parent:
		if parent.owner:
			spatial.owner = parent.owner
			break
		parent = parent.get_parent()

	return spatial
