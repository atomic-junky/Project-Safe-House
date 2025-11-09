class_name BaseSystem
extends RefCounted

## Base class for all ECS Systems.
## Systems contain game logic and operate on entities/components.

var world: Variant
var enabled: bool = true


func _init(ecs_world: Variant) -> void:
	world = ecs_world


## Called when system is added to world
func initialize() -> void:
	pass


## Called every frame - override to implement system logic
func update(_delta: float) -> void:
	pass


## Called when system is removed
func cleanup() -> void:
	pass


## Query entities by component types
func query_entities(component_types: Array[String]) -> Array:
	var results: Array = []
	for entity in world.entities.values():
		var has_all: bool = true
		for comp_type: String in component_types:
			if not entity.has_component(comp_type):
				has_all = false
				break
		if has_all and entity.active:
			results.append(entity)
	return results


## Query entities by tag
func query_by_tag(tag: String) -> Array:
	var results: Array = []
	for entity in world.entities.values():
		if entity.has_tag(tag) and entity.active:
			results.append(entity)
	return results


## Get entity by ID
func get_entity(entity_id: String):
	return world.get_entity(entity_id)
