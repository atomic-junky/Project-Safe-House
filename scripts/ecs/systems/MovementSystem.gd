class_name MovementSystem
extends System

## System that processes movement - inspired by GECS pattern
## Moves entities from position A to B

const ARRIVAL_TOLERANCE: float = 0.05


func query() -> QueryBuilder:
	"""Define which entities this system processes."""
	var q: QueryBuilder = QueryBuilder.new()
	return q.with_all(["Transform", "Movement"]).iterate(["Transform", "Movement"])


func process(_entities: Array, components: Array, delta: float) -> void:
	"""Process all moving entities."""
	var transforms: Array = components[0]
	var movements: Array = components[1]

	for i: int in transforms.size():
		var transform: Transform = transforms[i]
		var movement: Movement = movements[i]

		if not movement.is_moving:
			continue

		_move_entity(transform, movement, delta)


func _move_entity(transform: Transform, movement: Movement, delta: float) -> void:
	"""Move one entity."""
	var direction: Vector3 = movement.target_position - transform.position
	var distance: float = direction.length()

	# Check arrival
	if distance <= ARRIVAL_TOLERANCE:
		transform.position = movement.target_position
		movement.is_moving = false
		movement.velocity = Vector3.ZERO
		return

	# Move toward target
	var step: float = movement.max_speed * delta
	transform.position += direction.normalized() * step
	movement.velocity = direction.normalized() * movement.max_speed
