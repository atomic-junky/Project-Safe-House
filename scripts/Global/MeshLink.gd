extends Node

const _meshes: Dictionary = {
	DEFAULT = {name = "default", scene = preload("res://assets/meshes/rooms/base_1l_room.glb")},
	DIRT = {name = "dirt", scene = preload("res://assets/meshes/dirt.glb")},
	POINTER_1L = {name = "pointer_1l", scene = preload("res://assets/meshes/ui/selector_1l.glb")},
	POINTER_2L = {name = "pointer_2l", scene = preload("res://assets/meshes/ui/selector_2l.glb")},
	POINTER_3L = {name = "pointer_3l", scene = preload("res://assets/meshes/ui/selector_3l.glb")},
	BUILD_LOCATION =
	{
		name = "build_location",
		scene = preload("res://objects/map_scenes/shelter/BuildLocation.tscn")
	},
	VAULTDOOR =
	{name = "vaultdoor", scene = preload("res://objects/map_scenes/shelter/rooms/VaultDoor.tscn")},
	ELEVATOR_TOP =
	{
		name = "elevator_top",
		scene = preload("res://objects/map_scenes/shelter/rooms/ElevatorMiddle.tscn")
	},
	ELEVATOR_MIDDLE =
	{
		name = "elevator_middle",
		scene = preload("res://objects/map_scenes/shelter/rooms/ElevatorMiddle.tscn")
	},
	ELEVATOR_BOTTOM =
	{
		name = "elevator_bottom",
		scene = preload("res://objects/map_scenes/shelter/rooms/ElevatorMiddle.tscn")
	},
	LIVING_ROOM_1L =
	{
		name = "living_room_1l",
		scene = preload("res://objects/map_scenes/shelter/rooms/BaseRoom/BaseRoom1L.tscn")
	},
	LIVING_ROOM_2L =
	{
		name = "living_room_2l",
		scene = preload("res://objects/map_scenes/shelter/rooms/BaseRoom/BaseRoom2L.tscn")
	},
	LIVING_ROOM_3L =
	{
		name = "living_room_3l",
		scene = preload("res://objects/map_scenes/shelter/rooms/BaseRoom/BaseRoom3L.tscn")
	}
}

var _slot_markers: Dictionary = {}


func _ready() -> void:
	load_slot_markers()


func load_slot_markers() -> void:
	for key in _meshes.keys():
		var el: Dictionary = _meshes[key]
		var scene: Node3D = el.scene.instantiate()

		var markers: Node = scene.get_node_or_null("SlotMarkers")
		if markers == null:
			continue

		var positions = []
		for marker: Marker3D in markers.get_children():
			positions.append(marker.position)

		_slot_markers[el.name] = positions

		scene.queue_free()


func get_spots(room_name: String) -> Array:
	return _slot_markers[room_name]


func build_palette() -> ScenePalette:
	var pal: ScenePalette = ScenePalette.new()

	for el in _meshes.values():
		pal.create_item()

		var pal_index = pal.size() - 1
		var scene = el.scene

		pal.set_item_scene(pal_index, scene)
		pal.set_item_name(pal_index, el.name)

	return pal
