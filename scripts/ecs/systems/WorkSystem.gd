class_name WorkSystem
extends System

## System that processes work assignments
## Updates work state and efficiency for working entities


func query() -> QueryBuilder:
	"""Define which entities this system processes."""
	var q: QueryBuilder = QueryBuilder.new()
	return q.with_all(["Work", "Transform"]).iterate(["Work", "Transform"])


func process(_entities: Array, components: Array, _delta: float) -> void:
	"""Process all working entities."""
	var work_components: Array = components[0]  # From iterate([..., "Work"])
	var transforms: Array = components[1]        # From iterate([..., "Transform"])

	for i: int in work_components.size():
		var work: Work = work_components[i]
		var transform: Transform = transforms[i]

		_update_work(work, transform)


func _update_work(work: Work, _transform: Transform) -> void:
	"""Update work state and progress."""
	
	# If not working, nothing to do
	if not work.is_working:
		return
	
	# Simulate work progress based on efficiency
	# This is a placeholder - actual work logic would depend on room type
	if work.assigned_room:
		# Update position to work location
		# (In real implementation, this would use the room's work slot position)
		# _transform.position = work.assigned_room.get_work_slot_position(work.slot_index)
		pass
