class_name System
extends RefCounted

## Base class for all systems.
## Systems implement logic that operates on components.

var enabled: bool = true
var world: World = null


## Override this to define which entities this system processes
func query() -> QueryBuilder:
	"""Return a QueryBuilder that defines which entities to process."""
	return null


## Override this to implement system logic
func process(_entities: Array, _components: Array, _delta: float) -> void:
	"""Process entities and their components."""
	pass


## Called when system is added to world
func initialize() -> void:
	pass


## Called when system is removed from world
func cleanup() -> void:
	pass
