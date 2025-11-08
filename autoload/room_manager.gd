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

const BUILD_LOCATION := preload("res://prefabs/shelter/BuildLocation.tscn")

const _SELECTOR_SCENES := {
	1: preload("res://assets/meshes/ui/selector_1l.glb"),
	2: preload("res://assets/meshes/ui/selector_2l.glb"),
	3: preload("res://assets/meshes/ui/selector_3l.glb")
}

const _BASE_ROOM_SCENES := {
	1: preload("res://prefabs/rooms/base_room/BaseRoom1L.tscn"),
	2: preload("res://prefabs/rooms/base_room/BaseRoom2L.tscn"),
	3: preload("res://prefabs/rooms/base_room/BaseRoom3L.tscn")
}

var _ROOM_DATA := {
	RoomType.ROOM_OUTSIDE:
	{"name": "Outside", "scenes": {}, "logic_class": null, "expandable": false, "buildable": false},
	RoomType.ROOM_DIRT:
	{
		"name": "Dirt",
		"scenes": {1: preload("res://assets/meshes/dirt.glb")},
		"logic_class": null,
		"expandable": false,
		"buildable": false
	},
	RoomType.ROOM_VAULTDOOR:
	{
		"name": "Vault Door",
		"scenes": {2: preload("res://prefabs/rooms/VaultDoor.tscn")},
		"logic_class": VaultDoor,
		"expandable": false,
		"buildable": false
	},
	RoomType.ROOM_ELEVATOR:
	{
		"name": "Elevator",
		"scenes": {1: preload("res://prefabs/rooms/ElevatorMiddle.tscn")},
		"logic_class": ElevatorShaft,
		"expandable": false,
		"buildable": true
	},
	RoomType.ROOM_LIVING_ROOM:
	{
		"name": "Living Room",
		"scenes": _BASE_ROOM_SCENES,
		"logic_class": LivingRoom,
		"expandable": true,
		"buildable": true
	},
	RoomType.ROOM_POWER_GENERATOR:
	{
		"name": "Power Generator",
		"scenes": _BASE_ROOM_SCENES,
		"logic_class": PowerGenerator,
		"expandable": true,
		"buildable": true
	},
	RoomType.ROOM_DINER:
	{
		"name": "Diner",
		"scenes": _BASE_ROOM_SCENES,
		"logic_class": Diner,
		"expandable": true,
		"buildable": true
	},
	RoomType.ROOM_WATER_TREATMENT:
	{
		"name": "Water Treatment",
		"scenes": _BASE_ROOM_SCENES,
		"logic_class": WaterTreatment,
		"expandable": true,
		"buildable": true
	},
	RoomType.ROOM_STORAGE_ROOM:
	{
		"name": "Storage Room",
		"scenes": {},
		"logic_class": null,
		"expandable": false,
		"buildable": false
	},
	RoomType.ROOM_MEDBAY:
	{"name": "Medbay", "scenes": {}, "logic_class": null, "expandable": false, "buildable": false},
	RoomType.ROOM_SCIENCE_LAB:
	{
		"name": "Science Lab",
		"scenes": {},
		"logic_class": null,
		"expandable": false,
		"buildable": false
	},
	RoomType.ROOM_OVERSEER_OFFICE:
	{
		"name": "Overseer Office",
		"scenes": {},
		"logic_class": null,
		"expandable": false,
		"buildable": false
	},
	RoomType.ROOM_RADIO_STUDIO:
	{
		"name": "Radio Studio",
		"scenes": {},
		"logic_class": null,
		"expandable": false,
		"buildable": false
	},
	RoomType.ROOM_WEAPON_WORKSHOP:
	{
		"name": "Weapon Workshop",
		"scenes": {},
		"logic_class": null,
		"expandable": false,
		"buildable": false
	},
	RoomType.ROOM_OUTFIT_WORKSHOP:
	{
		"name": "Outfit Workshop",
		"scenes": {},
		"logic_class": null,
		"expandable": false,
		"buildable": false
	}
}

var _room_logic: Dictionary = {}
var _slot_markers: Dictionary = {}


func _ready() -> void:
	_populate_room_logic()
	_load_slot_markers()


func _populate_room_logic() -> void:
	_room_logic.clear()
	for room_type in _ROOM_DATA.keys():
		var definition: Dictionary = _ROOM_DATA[room_type]
		var logic_class: GDScript = definition.get("logic_class")
		if logic_class != null:
			_room_logic[room_type] = logic_class


func get_build_location() -> Node3D:
	return BUILD_LOCATION.instantiate()


func get_selector(size: int) -> Node3D:
	var scene: PackedScene = _SELECTOR_SCENES.get(size)
	assert(scene != null, "Can't find selector for the size %s" % size)
	return scene.instantiate()


func create_room(room_type: RoomType, size: int = 1) -> Node3D:
	var scene: PackedScene = _get_scene_for_size(room_type, size)
	if scene == null:
		return null
	var room_instance: Node3D = scene.instantiate()
	var logic_class: GDScript = get_abstract_room(room_type)
	if logic_class != null:
		var logic_instance: AbstractRoom = logic_class.new()
		room_instance.add_child(logic_instance)
	return room_instance


func get_room_scene(room_type: RoomType, size: int = -1) -> Node3D:
	var scene: PackedScene = _get_scene_for_size(room_type, size)
	if scene == null:
		return null
	return scene.instantiate()


func get_abstract_room(room_type: RoomType) -> GDScript:
	var logic_class: GDScript = _room_logic.get(room_type)
	if logic_class == null:
		push_error("Can't find abstract room for room %s" % room_type)
	return logic_class


func get_room_name(room_type: RoomType) -> String:
	var definition: Dictionary = _ROOM_DATA.get(room_type, {})
	return definition.get("name", "Unknown Room")


func get_available_sizes(room_type: RoomType) -> Array:
	var definition: Dictionary = _ROOM_DATA.get(room_type, {})
	var scenes: Dictionary = definition.get("scenes", {})
	var sizes: Array = scenes.keys()
	sizes.sort()
	return sizes


func is_expandable(room_type: RoomType) -> bool:
	var definition: Dictionary = _ROOM_DATA.get(room_type, {})
	return definition.get("expandable", false)


func get_buildable_rooms() -> Array[Dictionary]:
	var buildable_rooms: Array[Dictionary] = []
	for room_type in _ROOM_DATA.keys():
		var definition: Dictionary = _ROOM_DATA[room_type]
		if !definition.get("buildable", true):
			continue
		var scenes: Dictionary = definition.get("scenes", {})
		for size in scenes.keys():
			buildable_rooms.append(
				{
					"type": room_type,
					"size": size,
					"name": "%s (%dx1)" % [definition.get("name", room_type), size],
					"expandable": definition.get("expandable", false)
				}
			)
	return buildable_rooms


func get_palette_room_name(room_type: RoomType, size: int = 1) -> String:
	return "%s-%s" % [room_type, size]


func build_palette() -> ScenePalette:
	var pal: ScenePalette = ScenePalette.new()
	for room_type in _ROOM_DATA.keys():
		var definition: Dictionary = _ROOM_DATA[room_type]
		var scenes: Dictionary = definition.get("scenes", {})
		if scenes.is_empty():
			continue
		var sizes: Array = scenes.keys()
		sizes.sort()
		for size in sizes:
			pal.create_item()
			var pal_index: int = pal.size() - 1
			pal.set_item_scene(pal_index, scenes[size])
			pal.set_item_name(pal_index, get_palette_room_name(room_type, size))
	return pal


func get_spots(room_type: RoomType, size: int = -1) -> Array:
	var sized_positions = _slot_markers.get(room_type)
	if sized_positions == null:
		return []
	var target_size: int = size
	if target_size <= 0:
		var keys: Array = sized_positions.keys()
		keys.sort()
		if keys.is_empty():
			return []
		target_size = keys[0]
	return sized_positions.get(target_size, [])


func get_dweller_spots(room_type: RoomType, size: int = 1) -> Array[Vector3]:
	var spots: Array = get_spots(room_type, size)
	return spots.duplicate()


func _load_slot_markers() -> void:
	_slot_markers.clear()
	for room_type in _ROOM_DATA.keys():
		var definition: Dictionary = _ROOM_DATA[room_type]
		var scenes: Dictionary = definition.get("scenes", {})
		if scenes.is_empty():
			continue
		var sized_positions: Dictionary = {}
		for size in scenes.keys():
			var scene: PackedScene = scenes[size]
			if scene == null:
				continue
			var instance: Node3D = scene.instantiate()
			sized_positions[size] = _collect_marker_positions(instance)
			instance.queue_free()
		if !sized_positions.is_empty():
			_slot_markers[room_type] = sized_positions


func _collect_marker_positions(node: Node3D) -> Array:
	var positions: Array = []
	var markers: Node = node.get_node_or_null("SlotMarkers")
	if markers != null:
		for marker in markers.get_children():
			if marker is Marker3D:
				positions.append(marker.position)
	return positions


func _get_scene_for_size(room_type: RoomType, size: int) -> PackedScene:
	var definition: Dictionary = _ROOM_DATA.get(room_type)
	if definition == null:
		push_error("Unknown room type %s" % room_type)
		return null
	var scenes: Dictionary = definition.get("scenes", {})
	if scenes.is_empty():
		push_error("No scenes registered for room %s" % room_type)
		return null
	var target_size: int = size
	if target_size <= 0:
		var sizes: Array = scenes.keys()
		sizes.sort()
		if sizes.is_empty():
			return null
		target_size = sizes[0]
	if !scenes.has(target_size):
		push_error("Size %s not available for room %s" % [target_size, room_type])
		return null
	return scenes[target_size]
