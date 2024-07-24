class_name EIdleState extends State


@export var running_state: ERunningState

var move_direction: Vector2
var wander_time: float


func randomize_wander() -> void:
	move_direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
	wander_time = randf_range(1, 3)


func _enter(_actor: Node) -> void:
	randomize_wander()


func _update(_delta: float, actor: Node) -> void:
	if actor.map_path != null and !actor.map_path.is_empty():
		transitioned.emit(running_state)
