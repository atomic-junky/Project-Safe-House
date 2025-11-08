class_name MovementComponent
extends "res://scripts/components/Component.gd"

@export var move_speed: float = 1.5
@export var arrival_tolerance: float = 0.05

var _target_position: Vector3 = Vector3.ZERO
var _is_moving: bool = false


func move_to(position: Vector3) -> void:
	_target_position = position
	_is_moving = true


func stop() -> void:
	_is_moving = false


func _update(delta: float) -> void:
	if not _is_moving:
		return
	if entity == null:
		return
	if not (entity is Node3D):
		return
	var actor: Node3D = entity as Node3D
	var direction: Vector3 = _target_position - actor.global_position
	if direction.length() <= arrival_tolerance:
		actor.global_position = _target_position
		_is_moving = false
		return
	actor.global_position += direction.normalized() * move_speed * delta
