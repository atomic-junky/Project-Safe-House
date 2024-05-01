extends Node3D
class_name AutoSceneMap


@onready var _scene_map: SceneMap = $SceneMap
@onready var cell_size: Vector3 :
	get:
		return _scene_map.cell_size


func _ready():
	var pal: ScenePalette = MeshLink.build_palette()
	_scene_map.palette = pal

	_scene_map.cell_size = Vector3(2, 2, 3)


# Clear all cells of the SceneMap.
func clear():
	for coordinate in _scene_map.cell_map.keys():
		_scene_map._remove_instance(coordinate)


func _get_item_index(item_name: String) -> int:
	for index in _scene_map.palette.items:
		var _name = _scene_map.palette.get_item_name(index)

		if _name == item_name:
			return index
	return -1


func set_cell_item(
	p_coordinate: Vector3, p_item_name: String, p_orientation: Quaternion = Quaternion.IDENTITY
) -> bool:
	var p_item_id = _get_item_index(p_item_name)
	return _scene_map.set_cell_item(p_coordinate, p_item_id, p_orientation)