class_name ECSWorld
extends RefCounted

## Central ECS World that manages all entities and systems.
##
## Entities are containers of components.
## Components hold data only (no logic).
## Systems operate on entities/components and contain all game logic.
##
## This is the true source of truth for game state.

class Entity:
	"""Entity - a collection of components."""
	var id: String
	var components: Dictionary[String, Node] = {}
	var active: bool = true
	var tags: Array[String] = []
	
	func _init(entity_id: String) -> void:
		id = entity_id
	
	func add_component(component_type: String, component: Node) -> void:
		components[component_type] = component
	
	func get_component(component_type: String) -> Node:
		return components.get(component_type, null)
	
	func has_component(component_type: String) -> bool:
		return components.has(component_type)
	
	func remove_component(component_type: String) -> void:
		components.erase(component_type)
	
	func add_tag(tag: String) -> void:
		if not tag in tags:
			tags.append(tag)
	
	func has_tag(tag: String) -> bool:
		return tag in tags
	
	func remove_tag(tag: String) -> void:
		tags.erase(tag)


class System:
	"""Base class for all ECS systems."""
	var world: ECSWorld
	var enabled: bool = true
	
	func _init(ecs_world: ECSWorld) -> void:
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
	func query_entities(component_types: Array[String]) -> Array[Entity]:
		var results: Array[Entity] = []
		for entity: Entity in world.entities.values():
			var has_all: bool = true
			for comp_type in component_types:
				if not entity.has_component(comp_type):
					has_all = false
					break
			if has_all and entity.active:
				results.append(entity)
		return results
	
	## Query entities by tag
	func query_by_tag(tag: String) -> Array[Entity]:
		var results: Array[Entity] = []
		for entity: Entity in world.entities.values():
			if entity.has_tag(tag) and entity.active:
				results.append(entity)
		return results


var entities: Dictionary[String, Entity] = {}
var systems: Array[System] = []
var _entity_counter: int = 0


func create_entity(entity_id: String = "") -> Entity:
	"""Create a new entity. Auto-generates ID if not provided."""
	if entity_id.is_empty():
		_entity_counter += 1
		entity_id = "entity_%d" % _entity_counter
	
	var entity := Entity.new(entity_id)
	entities[entity_id] = entity
	return entity


func get_entity(entity_id: String) -> Entity:
	"""Get entity by ID."""
	return entities.get(entity_id, null)


func destroy_entity(entity_id: String) -> void:
	"""Destroy entity and all its components."""
	if entity_id in entities:
		var entity: Entity = entities[entity_id]
		for component: Node in entity.components.values():
			component.queue_free()
		entities.erase(entity_id)


func add_system(system: System) -> void:
	"""Add system to world."""
	systems.append(system)
	system.initialize()


func remove_system(system: System) -> void:
	"""Remove system from world."""
	if system in systems:
		system.cleanup()
		systems.erase(system)


func update(delta: float) -> void:
	"""Update all systems."""
	for system in systems:
		if system.enabled:
			system.update(delta)


func clear() -> void:
	"""Clear all entities and systems."""
	for system: System in systems:
		system.cleanup()
	systems.clear()

	for entity: Entity in entities.values():
		for component: Node in entity.components.values():
			component.queue_free()
	entities.clear()
	_entity_counter = 0