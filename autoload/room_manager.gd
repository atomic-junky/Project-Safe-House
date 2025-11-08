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

var room_definitions: Dictionary = {}

var scene_cache: Dictionary = {}

const BUILD_LOCATION := preload("res://prefabs/shelter/BuildLocation.tscn")


func _ready() -> void:
	_initialize_room_definitions()


func _initialize_room_definitions():
	var base_scenes_dict: Dictionary = {
		1: preload("res://prefabs/rooms/base_room/BaseRoom1L.tscn"),
		2: preload("res://prefabs/rooms/base_room/BaseRoom2L.tscn"),
		3: preload("res://prefabs/rooms/base_room/BaseRoom3L.tscn"),
	}

	_add_room_definition(
		RoomType.ROOM_DIRT, "Dirt", {1: preload("res://assets/meshes/dirt.glb")}, null
	)

	_add_room_definition(
		RoomType.ROOM_VAULTDOOR,
		"VaultDoor",
		{2: preload("res://prefabs/rooms/VaultDoor.tscn")},
		VaultDoor
	)

	_add_room_definition(
		RoomType.ROOM_ELEVATOR,
		"Elevator",
		{1: preload("res://prefabs/rooms/ElevatorMiddle.tscn")},
		ElevatorShaft
	)

	_add_room_definition(RoomType.ROOM_LIVING_ROOM, "Living Room", base_scenes_dict, LivingRoom)
	_add_room_definition(
		RoomType.ROOM_POWER_GENERATOR, "Power Generator", base_scenes_dict, PowerGenerator
	)
	_add_room_definition(RoomType.ROOM_DINER, "Diner", base_scenes_dict, Diner)
	_add_room_definition(
		RoomType.ROOM_WATER_TREATMENT, "Water Treatment", base_scenes_dict, WaterTreatment
	)


func _add_room_definition(
	room_type: RoomType, room_name: String, scenes: Dictionary, logic_class: GDScript
):
	room_definitions[room_type] = {"name": room_name, "scenes": scenes, "logic_class": logic_class}


func create_room(room_type: RoomType, size: int = 1) -> Node3D:
	var definition = room_definitions.get(room_type)
	if not definition:
		push_error("Room type %s not found" % room_type)
		return null

	if size not in definition.sizes:
		push_error("Size %d not available for room %s" % [size, room_type])
		return null

	var room_scene = _get_room_scene(room_type, size)
	var room_instance = room_scene.instantiate()

	if definition.logic_class:
		var logic = definition.logic_class.new()
		room_instance.add_child(logic)

	return room_instance


func _get_room_scene(room_type: RoomType, size: int) -> PackedScene:
	var cache_key = "%s%d" % [room_type, size]

	if cache_key in scene_cache:
		return scene_cache[cache_key]

	var definition = room_definitions[room_type]
	var scene: PackedScene

	if not "scenes" in definition or not definition.scenes.has(size):
		var room_name: String = str(RoomType.find_key(room_type))
		push_error("Can't find the scene for the room %s with the size %s." % [room_name, size])
		return null
	scene = definition.scenes[size]

	scene_cache[cache_key] = scene
	return scene


func get_room_name(room_type: RoomType) -> String:
	var definition = room_definitions.get(room_type, {})
	return definition.get("name", "Unknown Room")


func get_available_sizes(room_type: RoomType) -> Array:
	var definition = room_definitions.get(room_type, {})
	return definition.get("sizes", [])


func is_expandable(room_type: RoomType) -> bool:
	var definition = room_definitions.get(room_type, {})
	return definition.get("expandable", false)


func get_build_location() -> Node3D:
	return BUILD_LOCATION.instantiate()


func get_selector(size: int) -> Node3D:
	var selector_scenes = {
		1: preload("res://assets/meshes/ui/selector_1l.glb"),
		2: preload("res://assets/meshes/ui/selector_2l.glb"),
		3: preload("res://assets/meshes/ui/selector_3l.glb")
	}

	var scene = selector_scenes.get(size)
	if not scene:
		push_error("No selector found for size %d" % size)
		return null

	return scene.instantiate()


func get_dweller_spots(room_type: RoomType, size: int = 1) -> Array[Vector3]:
	var room = create_room(room_type, size)
	var spots = _extract_spots_from_room(room)
	room.queue_free()
	return spots


func _extract_spots_from_room(room: Node3D) -> Array[Vector3]:
	var spots: Array[Vector3] = []
	var markers_node = room.get_node_or_null("SlotMarkers")

	if markers_node:
		for child in markers_node.get_children():
			if child is Marker3D:
				spots.append(child.position)

	return spots


func get_buildable_rooms() -> Array[Dictionary]:
	var buildable_rooms: Array[Dictionary] = []

	for room_type in room_definitions.keys():
		if room_type == RoomType.ROOM_OUTSIDE or room_type == RoomType.ROOM_DIRT:
			continue

		var definition = room_definitions[room_type]
		for size in definition.sizes:
			buildable_rooms.append(
				{
					"type": room_type,
					"size": size,
					"name": "%s (%dx1)" % [definition.name, size],
					"expandable": definition.get("expandable", false)
				}
			)

	return buildable_rooms


func get_palette_room_name(room_type: RoomType, size: int = 1) -> String:
	var room_name: String = str(RoomType.find_key(room_type))
	return "%s_%s" % [room_name, size]


func build_palette() -> ScenePalette:
	var pal: ScenePalette = ScenePalette.new()

	for room_type: RoomType in room_definitions.keys():
		for size: int in room_definitions[room_type].scenes.keys():
			pal.create_item()
			var room_name: String = get_palette_room_name(room_type, size)
			var pal_index = pal.size() - 1

			pal.set_item_scene(pal_index, room_definitions[room_type].scenes[size])
			pal.set_item_name(pal_index, room_name)
	return pal
