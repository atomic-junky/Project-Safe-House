@tool
extends Node
class_name MeshLink


const _meshes = {
	DEFAULT={
		name="default",
		path="res://assets/meshes/rooms/base_1l_room.glb"
	},
	DIRT={
		name="dirt",
		path="res://assets/meshes/dirt.glb"
	},
	BUILD_LOCATION = {
		name="build_location",
		path="res://objects/map_scenes/shelter/BuildLocation.tscn"
	},
	VAULTDOOR = {
		name="vaultdoor",
		path="res://assets/meshes/rooms/vault_door.glb"
	},
	ELEVATOR_TOP = {
		name="elevator_top",
		path="res://assets/meshes/elevator_middle.glb"
	},
	ELEVATOR_MIDDLE = {
		name="elevator_middle",
		path="res://assets/meshes/elevator_middle.glb"
	},
	ELEVATOR_BOTTOM = {
		name="elevator_bottom",
		path="res://assets/meshes/elevator_middle.glb"
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


static func build_palette() -> ScenePalette:
	var pal: ScenePalette = ScenePalette.new()

	for el in _meshes.values():
		pal.create_item()

		var pal_index = pal.size()-1
		var scene = load(el.path)

		pal.set_item_scene(pal_index, scene)
		pal.set_item_name(pal_index, el.name)

	return pal

