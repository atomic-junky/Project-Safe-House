class_name Entity
extends RefCounted

## Simple Entity - just an ID and a container for components.
## No logic here!

var id: int
var components: Dictionary[String, Variant] = {}


func _init(entity_id: int) -> void:
	id = entity_id


func add_component(component_name: String, data: Variant) -> void:
	components[component_name] = data


func get_component(component_name: String) -> Variant:
	return components.get(component_name, null)


func has_component(component_name: String) -> bool:
	return components.has(component_name)


func remove_component(component_name: String) -> void:
	components.erase(component_name)
