class_name EntityBase
extends Node3D

## Base class for all ECS entities in the game.
## Entities are simply containers of components (data).
## No logic here - logic lives in systems.

var id: String = UUID.v4()
var components: Dictionary[String, Node] = {}
var tags: Array[String] = []
var active: bool = true


## Add a component to this entity
func add_component(component: Node) -> void:
	if component == null:
		return

	var component_class: String = component.get_class()
	if component_class.is_empty():
		component_class = component.get_script().resource_path.get_basename()

	components[component_class] = component
	add_child(component)


## Get a component by type
func get_component(component_class: String) -> Node:
	return components.get(component_class, null)


## Check if entity has component
func has_component(component_class: String) -> bool:
	return components.has(component_class)


## Remove a component
func remove_component(component_class: String) -> void:
	if component_class in components:
		var component: Node = components[component_class]
		components.erase(component_class)
		component.queue_free()


## Add a tag to this entity
func add_tag(tag: String) -> void:
	if tag not in tags:
		tags.append(tag)


## Check if entity has tag
func has_tag(tag: String) -> bool:
	return tag in tags


## Remove a tag
func remove_tag(tag: String) -> void:
	tags.erase(tag)


## Deactivate entity (systems won't process it)
func deactivate() -> void:
	active = false


## Reactivate entity
func reactivate() -> void:
	active = true


## Clean up entity
func destroy() -> void:
	active = false
	queue_free()
