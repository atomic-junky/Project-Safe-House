extends Node


const _meshes = {
	DEFAULT={
		name="default",
		path="res://assets/meshes/rooms/base_1l_room.glb"
	},
	DIRT={
		name="dirt",
		path="res://assets/meshes/dirt.glb"
	},
	POINTER_1L={
		name="pointer_1l",
		path="res://assets/meshes/ui/selector_1l.glb"
	},
	POINTER_2L={
		name="pointer_2l",
		path="res://assets/meshes/ui/selector_2l.glb"
	},
	POINTER_3L={
		name="pointer_3l",
		path="res://assets/meshes/ui/selector_3l.glb"
	},
	BUILD_LOCATION = {
		name="build_location",
		path="res://objects/map_scenes/shelter/BuildLocation.tscn"
	},
	VAULTDOOR = {
		name="vaultdoor",
		path="res://objects/map_scenes/shelter/rooms/VaultDoor.tscn"
	},
	ELEVATOR_TOP = {
		name="elevator_top",
		path="res://objects/map_scenes/shelter/rooms/ElevatorMiddle.tscn"
	},
	ELEVATOR_MIDDLE = {
		name="elevator_middle",
		path="res://objects/map_scenes/shelter/rooms/ElevatorMiddle.tscn"
	},
	ELEVATOR_BOTTOM = {
		name="elevator_bottom",
		path="res://objects/map_scenes/shelter/rooms/ElevatorMiddle.tscn"
	},
	LIVING_ROOM_1L = {
		name="living_room_1l",
		path="res://assets/meshes/rooms/base_1l_room.glb"
	},
	LIVING_ROOM_2L = {
		name="living_room_2l",
		path="res://assets/meshes/rooms/base_2l_room.glb"
	},
	LIVING_ROOM_3L = {
		name="living_room_3l",
		path="res://assets/meshes/rooms/base_3l_room.glb"
	}
}

var _slot_markers = {}


func _ready():
	load_slot_markers()


func load_slot_markers():
	for key in _meshes.keys():
		var el = _meshes[key]
		var scene = load(el.path).instantiate()

		var markers = scene.get_node_or_null("SlotMarkers")
		if markers == null:
			continue

		var positions = []
		for marker in markers.get_children():
			positions.append(marker.position)

		_slot_markers[el.name] = positions

		scene.queue_free()


func get_spots(room_name: String):
	return _slot_markers[room_name]


func build_palette() -> ScenePalette:
	var pal: ScenePalette = ScenePalette.new()

	for el in _meshes.values():
		pal.create_item()

		var pal_index = pal.size()-1
		var scene = load(el.path)

		pal.set_item_scene(pal_index, scene)
		pal.set_item_name(pal_index, el.name)

	return pal

