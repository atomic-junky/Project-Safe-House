@tool
@icon("scene_map.svg")
class_name SceneMap
extends Node3D

signal palette_changed
signal cell_size_changed
signal cell_center_changed

const ScenePalette := preload("scene_palette.gd")
const INVALID_CELL_ITEM := -1

# Palette containing scenes that should be instanced in this grid.
var palette: ScenePalette = ScenePalette.new():
	set = _set_palette

# Size of each cell in the grid.  Should match the size of the scenes in the
# attached palette.
var cell_size: Vector3 = Vector3(2, 2, 2):
	set = _set_cell_size

# If true, scenes are centered within the cell on the X axis.  Otherwise, they
# will start at X = 0 within the cell.
var cell_center_x: bool = true:
	set = _set_cell_center_x

# If true, scenes are centered within the cell on the Y axis.  Otherwise, they
# will start at Y = 0 within the cell.
var cell_center_y: bool = true:
	set = _set_cell_center_y

# If true, scenes are centered within the cell on the Z axis.  Otherwise, they
# will start at Z = 0 within the cell.
var cell_center_z: bool = true:
	set = _set_cell_center_z

# Contains a sparse collection of filled cells with the Id of the scene in the palette.
# key: Vector3
# value: { itemId: int, path: NodePath, orientation: Quat }
var cell_map: Dictionary = {}

# Whether a layout is currently pending.
var layout_pending: bool = false


func _get_property_list() -> Array:
	return [
		{"name": "SceneMap", "type": TYPE_NIL, "usage": PROPERTY_USAGE_CATEGORY},
		{
			"name": "palette",
			"type": TYPE_OBJECT,
			"hint": PROPERTY_HINT_RESOURCE_TYPE,
			"hint_string": "ScenePalette"
		},
		{"name": "Cell", "type": TYPE_NIL, "usage": PROPERTY_USAGE_GROUP, "hint_string": "cell_"},
		{"name": "cell_size", "type": TYPE_VECTOR3},
		{"name": "cell_center_x", "type": TYPE_BOOL},
		{"name": "cell_center_y", "type": TYPE_BOOL},
		{"name": "cell_center_z", "type": TYPE_BOOL},
		{"name": "cell_map", "type": TYPE_DICTIONARY, "usage": PROPERTY_USAGE_STORAGE}
	]


func _set_palette(value: ScenePalette) -> void:
	if palette != value:
		if palette && palette.is_connected("changed", Callable(_on_palette_changed)):
			palette.disconnect("changed", Callable(_on_palette_changed))

		palette = value

		if palette && !palette.is_connected("changed", Callable(_on_palette_changed)):
			palette.connect("changed", Callable(_on_palette_changed))

		_on_palette_changed()


func _set_cell_size(value: Vector3) -> void:
	value = value.floor()

	if cell_size != value:
		cell_size = value
		emit_signal("cell_size_changed")
		_request_layout()


func _set_cell_center_x(value: bool) -> void:
	if cell_center_x != value:
		cell_center_x = value
		emit_signal("cell_center_changed")
		_request_layout()


func _set_cell_center_y(value: bool) -> void:
	if cell_center_y != value:
		cell_center_y = value
		emit_signal("cell_center_changed")
		_request_layout()


func _set_cell_center_z(value: bool) -> void:
	if cell_center_z != value:
		cell_center_z = value
		emit_signal("cell_center_changed")
		_request_layout()


# Set a cell in the map to contain the scene in the palette as indicated by item_id.
# @param p_coordinate Vector3 specifying the x, y, and z coordinates of the cell.
# @param p_item_id ID of the scene to place at this cell.
# @param p_orientation Quaternion specifying how the item is oriented.
# @returns True if the item was removed or placed, false if item was already present when placing.
func set_cell_item(
	p_coordinate: Vector3, p_item_id: int, p_orientation: Quaternion = Quaternion.IDENTITY
) -> bool:
	var coordinate = p_coordinate.floor()

	if (
		get_cell_item_id(coordinate) == p_item_id
		&& get_cell_item_orientation(coordinate).is_equal_approx(p_orientation)
	):
		return false

	if p_item_id == INVALID_CELL_ITEM:
		return _remove_instance(coordinate)

	if cell_map.has(coordinate):
		_remove_instance(coordinate)

	return _place_instance(coordinate, p_item_id, p_orientation)


# Gets the palette ID of the item at the indicated coordinates.
# @param p_coordinate Vector3 specifying the x, y, and z coordinates of the cell.
# @returns ID of the item if a cell is present, -1 if not.
func get_cell_item_id(p_coordinate: Vector3) -> int:
	var coordinate = p_coordinate.floor()

	if cell_map.has(coordinate):
		var data := cell_map.get(coordinate) as Dictionary
		return data.itemId

	return INVALID_CELL_ITEM


# Gets the saved orientation of the item at the indicated coordinates.
# @param p_coordinate Vector3 specifying the x, y, and z coordinates of the cell.
# @returns Quaternion specifying how the item is oriented.
func get_cell_item_orientation(p_coordinate: Vector3) -> Quaternion:
	var coordinate = p_coordinate.floor()

	if cell_map.has(coordinate):
		var data := cell_map.get(coordinate) as Dictionary
		return data.orientation

	return Quaternion.IDENTITY


# Gets the position of the cell in relation to this SceneMap.
# @param p_coordinate Vector3 specifying the x, y, and z coordinates of the cell.
# @returns Position of the cell in the coordinate space of the SceneMap.
func get_cell_position(p_coordinate: Vector3) -> Vector3:
	var cell_location := p_coordinate

	if cell_center_x:
		cell_location.x += 0.5
	if cell_center_y:
		cell_location.y += 0.5
	if cell_center_z:
		cell_location.z += 0.5

	cell_location *= cell_size
	return cell_location


# Clear all cells of the SceneMap.
func clear():
	for coordinate in cell_map:
		_remove_instance(coordinate)


func _request_layout() -> void:
	if layout_pending:
		return

	layout_pending = true
	call_deferred("_layout")


func _layout() -> void:
	for coordinate in cell_map:
		var data := cell_map.get(coordinate) as Dictionary
		var spatial := get_node(data.path) as Node3D
		if spatial:
			spatial.position = get_cell_position(coordinate)

	layout_pending = false


func _remove_instance(coordinate: Vector3) -> bool:
	var data := cell_map.get(coordinate) as Dictionary
	var node := get_node_or_null(data.path)
	if !node:
		push_error("Could not find scene at %s (%s) to remove." % [data.path, coordinate])
		cell_map.erase(coordinate)
		return false

	self.remove_child(node)
	node.queue_free()

	cell_map.erase(coordinate)
	return true


func _place_instance(coordinate: Vector3, item_id: int, orientation: Quaternion) -> bool:
	var scene: PackedScene = palette.get_item_scene(item_id)
	if !scene:
		push_error("Missing scene for item %s at cell %s" % [item_id, coordinate])
		return false

	var node := scene.instantiate(
		(
			PackedScene.GEN_EDIT_STATE_INSTANCE
			if Engine.is_editor_hint()
			else PackedScene.GEN_EDIT_STATE_DISABLED
		)
	)
	var item_name := palette.get_item_name(item_id)
	if item_name:
		node.name = item_name

	var spatial := node as Node3D
	if spatial:
		spatial.transform = Transform3D(Basis(orientation), get_cell_position(coordinate))

	self.add_child(node, true)

	# Climb the nodes above us, looking for an owner to attach to.
	var parent: Node = self
	while parent:
		if parent.owner:
			node.owner = parent.owner
			break
		parent = parent.get_parent()

	cell_map[coordinate] = {
		"itemId": item_id, "path": self.get_path_to(node), "orientation": orientation
	}

	return true


func _rebuild() -> void:
	var cells := cell_map.keys()
	for cell in cells:
		var data := cell_map.get(cell) as Dictionary
		var item_id := data.itemId as int
		var orientation := data.orientation as Quaternion

		_remove_instance(cell)
		_place_instance(cell, item_id, orientation)


func _on_palette_changed():
	emit_signal("palette_changed", palette)
	_rebuild()
