class_name RoomFactory
extends RefCounted

const RoomEntity := preload("res://scripts/entities/RoomEntity.gd")
const Component := preload("res://scripts/components/Component.gd")
const RoomData := preload("res://scripts/resources/RoomData.gd")


func create_from_data(data: RoomData) -> RoomEntity:
	if data == null:
		return null
	var room: RoomEntity = RoomEntity.new()
	room.name = data.room_name
	room.room_type_id = data.room_type
	for config: Dictionary in data.component_configs:
		var component: Component = _build_component(config)
		if component == null:
			continue
		room.attach_component(component)
	return room


func _build_component(config: Dictionary) -> Component:
	var script: Script = config.get("script")
	if script == null and config.has("script_path"):
		script = load(config.get("script_path")) as Script
	if script == null:
		return null
	var component: Component = script.new() as Component
	if component == null:
		return null
	var properties: Dictionary = config.get("properties", {})
	for key: Variant in properties.keys():
		component.set(key, properties[key])
	return component
