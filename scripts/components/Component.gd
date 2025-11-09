class_name Component
extends Node

enum LifecycleState { NEW, INITIALIZED, CLEANED }

@export var entity: ShelterEntity

var lifecycle_state: LifecycleState = LifecycleState.NEW
var auto_initialize: bool = true


func initialize() -> void:
	if lifecycle_state != LifecycleState.NEW:
		return
	_initialize()
	lifecycle_state = LifecycleState.INITIALIZED


func update(delta: float) -> void:
	if lifecycle_state == LifecycleState.CLEANED:
		return
	if lifecycle_state == LifecycleState.NEW:
		if auto_initialize:
			initialize()
		else:
			return
	_update(delta)


func cleanup() -> void:
	if lifecycle_state == LifecycleState.CLEANED:
		return
	_cleanup()
	lifecycle_state = LifecycleState.CLEANED


func _ready() -> void:
	if auto_initialize:
		initialize()


func _exit_tree() -> void:
	cleanup()


func _initialize() -> void:
	pass


func _update(_delta: float) -> void:
	pass


func _cleanup() -> void:
	pass
