class_name NavigationSystem
extends System

## System that processes navigation - updates entity targets based on pathfinding
## Manages room-to-room pathfinding and target positions


func query() -> QueryBuilder:
	"""Define which entities this system processes."""
	var q: QueryBuilder = QueryBuilder.new()
	return q.with_all(["Navigation", "Movement"]).iterate(["Navigation", "Movement"])


func process(_entities: Array, _components: Array, _delta: float) -> void:
	"""Navigation progression is now handled by Dweller state logic."""
	return
