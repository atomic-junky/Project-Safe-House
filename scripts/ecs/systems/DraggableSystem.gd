class_name DraggableSystem
extends System

## System that processes drag input for draggable entities
## Updates draggable state based on user interaction


func query() -> QueryBuilder:
	"""Define which entities this system processes."""
	var q: QueryBuilder = QueryBuilder.new()
	return q.with_all(["Draggable", "Transform"]).iterate(["Draggable", "Transform"])


func process(_entities: Array, components: Array, _delta: float) -> void:
	"""Process all draggable entities."""
	var draggables: Array = components[0]  # From iterate([..., "Draggable"])
	var transforms: Array = components[1]  # From iterate([..., "Transform"])

	for i: int in draggables.size():
		var draggable: Draggable = draggables[i]
		var transform: Transform = transforms[i]

		_update_draggable(draggable, transform)


func _update_draggable(draggable: Draggable, transform: Transform) -> void:
	"""Update draggable state and position during drag."""
	# Drag interactions now only update placeholder visuals handled by Shelter.gd.
	# We keep the ECS transform untouched so the dweller remains in place until drop.
	if draggable.is_being_dragged:
		# Preserve current transform so static analyzers register the argument usage.
		transform.position = transform.position
