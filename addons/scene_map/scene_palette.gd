@tool
@icon("scene_palette.svg")
class_name ScenePalette
extends Resource

var items: Dictionary


func _set(property: StringName, value: Variant) -> bool:
	if property == "add_item":
		create_item()
		return true
	if property.begins_with("items/"):
		var parts := property.split("/")
		if parts.size() != 3:
			push_error("Not enough parts (need 3) for property: %s" % property)
			return false

		var item_index := int(parts[1])
		var prop := parts[2]

		if !items.has(item_index):
			items[item_index] = Item.new()

		match prop:
			"name":
				set_item_name(item_index, value)
				return true
			"scene":
				set_item_scene(item_index, value)
				return true
			"remove_item":
				remove_item(item_index)
				return true
			_:
				return false

	return false


func _get(property: StringName):
	if property.begins_with("items/"):
		var parts := property.split("/")
		if parts.size() != 3:
			push_error("Not enough parts (need 3) for property: %s" % property)
			return null

		var item_index := int(parts[1])
		var prop := parts[2]

		if !items.has(item_index):
			# push_error("Item ID is not present in palette. _get()")
			return null

		match prop:
			"name":
				return get_item_name(item_index)
			"scene":
				return get_item_scene(item_index)
			_:
				return null
	return null


func _get_property_list() -> Array:
	var props := [{"name": "ScenePalette", "type": TYPE_NIL, "usage": PROPERTY_USAGE_CATEGORY}]

	for item_index in items:
		var prefix = "items/%d/" % item_index
		props.append({"name": prefix + "name", "type": TYPE_STRING})
		props.append(
			{
				"name": prefix + "scene",
				"type": TYPE_OBJECT,
				"hint": PROPERTY_HINT_RESOURCE_TYPE,
				"hint_string": "PackedScene"
			}
		)
		props.append(
			{"name": prefix + "remove_item", "type": TYPE_BOOL, "usage": PROPERTY_USAGE_EDITOR}
		)

	props.append({"name": "add_item", "type": TYPE_BOOL, "usage": PROPERTY_USAGE_EDITOR})

	return props


func create_item() -> void:
	items[get_next_available_id()] = Item.new()
	_emit_changed()


func remove_item(item_index: int) -> void:
	if !items.has(item_index):
		push_error("Item ID is not present in palette. remove_item()")

	items.erase(item_index)
	_emit_changed()


func get_item_name(item_index: int) -> String:
	if item_index < 0:
		push_error("Item ID cannot be negative. get_item_name()")
		return ""
	if !items.has(item_index):
		push_error("Item ID is not present in palette get_item_name().")
		return ""

	return items[item_index].name


func set_item_name(item_index: int, name: String) -> void:
	if item_index < 0:
		push_error("Item ID cannot be negative. set_item_name()")
	if !items.has(item_index):
		push_error("Item ID is not present in palette. set_item_name()")

	items[item_index].name = name


func get_item_scene(item_index: int) -> PackedScene:
	if item_index < 0:
		push_error("Item ID cannot be negative. get_item_scene()")
		return null
	if !items.has(item_index):
		push_error("Item ID is not present in palette. get_item_scene()")
		return null

	return items[item_index].scene


func set_item_scene(item_index: int, scene: PackedScene) -> void:
	if item_index < 0:
		push_error("Item ID cannot be negative. set_item_scene()")
	if !items.has(item_index):
		push_error("Item ID is not present in palette. set_item_scene()")

	items[item_index].scene = scene
	_emit_changed()


func size():
	return items.size()


func clear() -> void:
	items.clear()
	_emit_changed()


func get_next_available_id() -> int:
	return items.size()


func _emit_changed():
	notify_property_list_changed()
	emit_changed()


class Item:
	var name: String
	var scene: PackedScene
