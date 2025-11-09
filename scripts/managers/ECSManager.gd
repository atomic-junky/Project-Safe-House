extends Node

## Central ECS manager - coordinates World and all systems
## Provides convenient API for game code to work with entities

var world: World = null
var systems_initialized: bool = false

# Systems are automatically accessible via class_name
# Components are automatically accessible via class_name
# No need for preload() when using class_name


func _ready() -> void:
	"""Initialize ECS World and all systems."""
	# Create world
	world = World.new()

	# Add all systems to world
	world.add_system(MovementSystem.new())
	world.add_system(NavigationSystem.new())
	world.add_system(DraggableSystem.new())
	world.add_system(WorkSystem.new())

	systems_initialized = true
	print("ECSManager: World initialized with all systems")


func _process(delta: float) -> void:
	"""Update ECS world each frame."""
	if world and systems_initialized:
		world.process(delta)


## Create a new dweller entity with all components
func create_dweller() -> Entity:
	"""Create a dweller entity with all necessary components."""
	if not world or not systems_initialized:
		push_error("ECSManager: World not initialized")
		return null

	# Create entity
	var entity: Entity = world.create_entity()

	# Add Transform component
	var transform: Transform = Transform.new()
	transform.position = Vector3(-1, 47.095, -1)
	world.add_component(entity.id, "Transform", transform)

	# Add Movement component
	var movement: Movement = Movement.new()
	world.add_component(entity.id, "Movement", movement)

	# Add Navigation component
	var navigation: Navigation = Navigation.new()
	world.add_component(entity.id, "Navigation", navigation)

	# Add Draggable component
	var draggable: Draggable = Draggable.new()
	draggable.is_draggable = true
	world.add_component(entity.id, "Draggable", draggable)

	# Add Work component
	var work: Work = Work.new()
	world.add_component(entity.id, "Work", work)

	print("ECSManager: Created dweller entity %d" % entity.id)
	return entity


## Destroy a dweller entity
func destroy_dweller(entity_id: int) -> void:
	"""Destroy a dweller entity."""
	if not world or not systems_initialized:
		push_error("ECSManager: World not initialized")
		return

	world.destroy_entity(entity_id)
	print("ECSManager: Destroyed dweller entity %d" % entity_id)


## Get all dweller entities
func get_all_dwellers() -> Array[Entity]:
	"""Get all entities with Transform component (all dwellers have this)."""
	if not world or not systems_initialized:
		return []

	var results: Array[Entity] = []
	for entity: Entity in world.query_entities_with(["Transform"]):
		results.append(entity)
	return results


## Get entity by ID
func get_entity(entity_id: int) -> Entity:
	"""Get entity by its ID."""
	if not world:
		return null
	return world.get_entity(entity_id)


## Get component from entity
func get_component(entity_id: int, component_name: String) -> Variant:
	"""Get a component from an entity."""
	if not world:
		return null
	return world.get_component(entity_id, component_name)


## Add component to entity
func add_component(entity_id: int, component_name: String, component: Variant) -> void:
	"""Add a component to an entity."""
	if not world:
		return
	world.add_component(entity_id, component_name, component)


## Remove component from entity
func remove_component(entity_id: int, component_name: String) -> void:
	"""Remove a component from an entity."""
	if not world:
		return
	world.remove_component(entity_id, component_name)
