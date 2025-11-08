class_name Component
extends Node

enum LifecycleState { NEW, INITIALIZED, CLEANED }

var entity: Node:
	get:
		return _entity
	set(value):
		_entity = value

var lifecycle_state: LifecycleState = LifecycleState.NEW
var auto_initialize: bool = true

var _entity: Node = null


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
