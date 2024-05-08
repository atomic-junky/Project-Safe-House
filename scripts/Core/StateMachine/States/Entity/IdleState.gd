class_name EIdleState
extends State


@export var running_state: ERunningState

var move_direction: Vector2
var wander_time: float


func randomize_wander() -> void:
	move_direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
	wander_time = randf_range(1, 3)


func enter() -> void:
	randomize_wander()


func _do(_delta: float) -> void:
	if node.map_path != null and !node.map_path.is_empty():
		parent.transition_to(running_state)