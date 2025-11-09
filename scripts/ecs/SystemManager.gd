class_name SystemManager
extends Node

## Manager that runs all ECS systems.
## Systems are simple classes that operate on entities with specific components.
## This is the central coordinator for all game logic.

var entities: Array = []
var systems: Array = []


func _ready() -> void:
	set_process(true)


func _process(delta: float) -> void:
	# Update all systems
	for system: Variant in systems:
		if system and system.enabled:
			system.update(delta, self)


## Register an entity to be processed by systems
func register_entity(entity: Variant) -> void:
	if entity not in entities:
		entities.append(entity)


## Unregister an entity
func unregister_entity(entity: Variant) -> void:
	entities.erase(entity)


## Add a system to be updated each frame
func add_system(system: Variant) -> void:
	systems.append(system)
	system.on_added(self)


## Query all entities with specific components
func query_entities_with_components(component_names: Array[String]) -> Array:
	var results: Array = []
	for entity in entities:
		if not entity.active:
			continue

		var has_all: bool = true
		for comp_name: String in component_names:
			if not entity.has_component(comp_name):
				has_all = false
				break

		if has_all:
			results.append(entity)

	return results


## Query entities by tag
func query_entities_by_tag(tag: String) -> Array:
	var results: Array = []
	for entity in entities:
		if entity.active and entity.has_tag(tag):
			results.append(entity)
	return results


## Query a single entity by ID
func get_entity_by_id(entity_id: String):
	for entity in entities:
		if entity.id == entity_id:
			return entity
	return null


## Clear all systems and entities
func clear() -> void:
	entities.clear()
	systems.clear()
