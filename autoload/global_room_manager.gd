extends Node

enum RoomType {
	ROOM_OUTSIDE = -1,
	ROOM_DIRT = 0,
	ROOM_VAULTDOOR = 1,
	ROOM_ELEVATOR = 2,
	ROOM_LIVING_ROOM = 3,
	ROOM_POWER_GENERATOR = 4,
	ROOM_DINER = 5,
	ROOM_WATER_TREATMENT = 6,
	ROOM_STORAGE_ROOM = 7,
	ROOM_MEDBAY = 8,
	ROOM_SCIENCE_LAB = 9,
	ROOM_OVERSEER_OFFICE = 10,
	ROOM_RADIO_STUDIO = 11,
	ROOM_WEAPON_WORKSHOP = 12,
	ROOM_OUTFIT_WORKSHOP = 13
}

var RoomLogic: Dictionary = {
	RoomType.ROOM_VAULTDOOR: VaultDoor,
	RoomType.ROOM_ELEVATOR: ElevatorShaft,
	RoomType.ROOM_LIVING_ROOM: LivingRoom,
	RoomType.ROOM_POWER_GENERATOR: PowerGenerator,
	RoomType.ROOM_DINER: Diner,
	RoomType.ROOM_WATER_TREATMENT: WaterTreatment
}

const BUILD_LOCATION := preload("res://prefabs/shelter/BuildLocation.tscn")

const _rooms_scene: Dictionary = {
	RoomType.ROOM_DIRT: preload("res://assets/meshes/dirt.glb"),
	RoomType.ROOM_VAULTDOOR: preload("res://prefabs/rooms/VaultDoor.tscn"),
	RoomType.ROOM_ELEVATOR: preload("res://prefabs/rooms/ElevatorMiddle.tscn"),
	RoomType.ROOM_LIVING_ROOM:
	{
		1: preload("res://prefabs/rooms/base_room/BaseRoom1L.tscn"),
		2: preload("res://prefabs/rooms/base_room/BaseRoom2L.tscn"),
		3: preload("res://prefabs/rooms/base_room/BaseRoom3L.tscn")
	},
	RoomType.ROOM_POWER_GENERATOR:
	{
		1: preload("res://prefabs/rooms/base_room/BaseRoom1L.tscn"),
		2: preload("res://prefabs/rooms/base_room/BaseRoom2L.tscn"),
		3: preload("res://prefabs/rooms/base_room/BaseRoom3L.tscn")
	},
	RoomType.ROOM_DINER:
	{
		1: preload("res://prefabs/rooms/base_room/BaseRoom1L.tscn"),
		2: preload("res://prefabs/rooms/base_room/BaseRoom2L.tscn"),
		3: preload("res://prefabs/rooms/base_room/BaseRoom3L.tscn")
	},
	RoomType.ROOM_WATER_TREATMENT:
	{
		1: preload("res://prefabs/rooms/base_room/BaseRoom1L.tscn"),
		2: preload("res://prefabs/rooms/base_room/BaseRoom2L.tscn"),
		3: preload("res://prefabs/rooms/base_room/BaseRoom3L.tscn")
	}
}

var _slot_markers: Dictionary = {}


func _ready() -> void:
	_load_slot_markers()


func get_build_location() -> Node3D:
	var location: Node3D = BUILD_LOCATION.instantiate()
	return location


func get_selector(size: int) -> Node3D:
	var scene: PackedScene
	match size:
		1:
			scene = preload("res://assets/meshes/ui/selector_1l.glb")
		2:
			scene = preload("res://assets/meshes/ui/selector_2l.glb")
		3:
			scene = preload("res://assets/meshes/ui/selector_3l.glb")

	assert(scene != null, "Can't find selector for the size %s" % size)

	var selector = scene.instantiate()
	return selector


func get_room_scene(room_type: RoomType, size: int = -1) -> Node3D:
	assert(_rooms_scene.has(room_type), "Can't find scene for room %s" % room_type)

	var scene: PackedScene
	if _rooms_scene[room_type] is Dictionary:
		scene = _rooms_scene[room_type][size]
	else:
		scene = _rooms_scene[room_type]

	var room: Node3D = scene.instantiate()
	return room


func get_abstract_room(room_type: RoomType) -> GDScript:
	assert(RoomLogic.has(room_type), "Can't find abstract room for room %s" % room_type)
	return RoomLogic[room_type]


func get_palette_room_name(room_type: RoomType, size: int = 1) -> String:
	return "%s-%s" % [room_type, size]


func build_palette() -> ScenePalette:
	var pal: ScenePalette = ScenePalette.new()

	for room_type: RoomType in _rooms_scene.keys():
		if _rooms_scene[room_type] is Dictionary:
			for size: int in _rooms_scene[room_type]:
				pal.create_item()
				var room_name: String = get_palette_room_name(room_type, size)
				var pal_index = pal.size() - 1

				pal.set_item_scene(pal_index, _rooms_scene[room_type][size])
				pal.set_item_name(pal_index, room_name)

			continue

		pal.create_item()
		var room_name: String = get_palette_room_name(room_type)
		var pal_index = pal.size() - 1

		pal.set_item_scene(pal_index, _rooms_scene[room_type])
		pal.set_item_name(pal_index, room_name)

	return pal


func _load_slot_markers() -> void:
	for key in _rooms_scene.keys():
		if _rooms_scene[key] is PackedScene:
			var room: Node3D = _rooms_scene[key].instantiate()
			_slot_markers[key] = _get_marker_positions_from_node(room)
			room.queue_free()
			continue

		if _rooms_scene[key] is not Dictionary:
			push_error("Invalid room scene type at %s" % key)
			continue

		_slot_markers[key] = {}
		for idx: int in _rooms_scene[key]:
			var room: Node3D = _rooms_scene[key][idx].instantiate()
			_slot_markers[key][idx] = _get_marker_positions_from_node(room)
			room.queue_free()


func _get_marker_positions_from_node(node: Node3D) -> Array:
	var positions = []
	var markers: Node = node.get_node_or_null("SlotMarkers")
	if markers != null:
		for marker: Marker3D in markers.get_children():
			positions.append(marker.position)
	return positions


func get_spots(room_type: RoomType, size: int = -1) -> Array:
	assert(_slot_markers.has(room_type), "Can't find spots for room %s" % room_type)

	var spots: Array = []
	if _slot_markers[room_type] is Dictionary:
		spots = _slot_markers[room_type][size]
	else:
		spots = _slot_markers[room_type]

	return spots
