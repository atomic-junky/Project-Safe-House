@tool
class_name EIdleState extends State

@export var running_state: ERunningState


func _enter(_actor: Node) -> void:
	pass


func _update(_delta: float, actor: Node) -> void:
	if actor.map_path != null and !actor.map_path.is_empty():
		transitioned.emit(running_state)
