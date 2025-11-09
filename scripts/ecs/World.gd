class_name World
extends RefCounted

## ECS World - manages entities, components, and systems.
## Inspired by GECS - simple but powerful.

var entities: Dictionary = {}
var entity_counter: int = 0
var systems: Array[System] = []

## Component storage by component type name
var components: Dictionary = {}

## Query cache for performance
var query_cache: Dictionary = {}


func create_entity() -> Entity:
	"""Create a new entity and return it."""
	var entity_id: int = entity_counter
	entity_counter += 1

	var entity: Entity = Entity.new(entity_id)
	entities[entity_id] = entity
	return entity


func get_entity(entity_id: int) -> Entity:
	"""Get entity by ID."""
	return entities.get(entity_id, null)


func destroy_entity(entity_id: int) -> void:
	"""Destroy an entity."""
	if entity_id in entities:
		var entity: Entity = entities[entity_id]
		# Clean up all components
		for component_name: String in entity.components.keys():
			_unindex_component(component_name, entity_id)
		entities.erase(entity_id)
		_invalidate_query_cache()


func add_component(entity_id: int, component_name: String, data: Variant) -> void:
	"""Add a component to an entity."""
	var entity: Entity = entities.get(entity_id)
	if entity == null:
		return

	entity.add_component(component_name, data)
	_index_component(component_name, entity_id, data)
	_invalidate_query_cache()


func get_component(entity_id: int, component_name: String) -> Variant:
	"""Get a component from an entity."""
	var entity: Entity = entities.get(entity_id)
	if entity == null:
		return null
	return entity.get_component(component_name)


func remove_component(entity_id: int, component_name: String) -> void:
	"""Remove a component from an entity."""
	var entity: Entity = entities.get(entity_id)
	if entity == null:
		return

	entity.remove_component(component_name)
	_unindex_component(component_name, entity_id)
	_invalidate_query_cache()


## Add a system to be processed
func add_system(system: System) -> void:
	"""Add system to world."""
	system.world = self
	system.initialize()
	systems.append(system)


## Remove a system
func remove_system(system: System) -> void:
	"""Remove system from world."""
	if system in systems:
		system.cleanup()
		systems.erase(system)


## Process all enabled systems
func process(delta: float) -> void:
	"""Call process on all enabled systems."""
	for system: System in systems:
		if system and system.enabled:
			var query_builder: QueryBuilder = system.query()
			if query_builder == null:
				continue

			var query_dict: Dictionary = query_builder.build()
			var queried_entities: Array = query_with(query_dict)

			# Prepare components array for iteration
			var components_to_iterate: Array = []
			for comp_name: String in query_dict.get("iterate", []):
				var comp_array: Array = []
				for entity: Entity in queried_entities:
					var comp: Variant = entity.get_component(comp_name)
					if comp != null:
						comp_array.append(comp)
				components_to_iterate.append(comp_array)

			system.process(queried_entities, components_to_iterate, delta)


## Query entities by QueryBuilder pattern
func query_with(query_dict: Dictionary) -> Array:
	"""Query entities with given component requirements."""
	var required: Array = query_dict.get("with", [])
	var forbidden: Array = query_dict.get("without", [])

	var results: Array[Entity] = []

	if required.is_empty():
		# Return all entities that don't have forbidden components
		for entity: Entity in entities.values():
			var has_forbidden: bool = false
			for comp_name: String in forbidden:
				if entity.has_component(comp_name):
					has_forbidden = true
					break
			if not has_forbidden:
				results.append(entity)
		return results

	# Start with entities that have the first required component
	var first_component: String = required[0]
	if not first_component in components:
		return results

	var first_entities: Dictionary = components[first_component]

	for entity_id: int in first_entities.keys():
		var entity: Entity = entities.get(entity_id)
		if entity == null:
			continue

		# Check all required components
		var has_all: bool = true
		for comp_name: String in required:
			if not entity.has_component(comp_name):
				has_all = false
				break

		# Check no forbidden components
		if has_all:
			for comp_name: String in forbidden:
				if entity.has_component(comp_name):
					has_all = false
					break

		if has_all:
			results.append(entity)

	return results


## Old simple query API (backward compatibility)
func query_entities_with(component_names: Array[String]) -> Array:
	"""Query all entities that have ALL of the specified components."""
	var query: QueryBuilder = QueryBuilder.new()
	query.with_all(component_names)
	return query_with(query.build())


func _index_component(component_name: String, entity_id: int, data: Variant) -> void:
	"""Index component for fast queries."""
	if not component_name in components:
		components[component_name] = {}
	components[component_name][entity_id] = data


func _unindex_component(component_name: String, entity_id: int) -> void:
	"""Remove component from index."""
	if component_name in components:
		components[component_name].erase(entity_id)


func _invalidate_query_cache() -> void:
	"""Invalidate query cache when entities/components change."""
	query_cache.clear()
