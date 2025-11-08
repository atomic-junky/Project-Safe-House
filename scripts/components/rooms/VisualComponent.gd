class_name VisualComponent
extends "res://scripts/components/Component.gd"

@export var variants: Dictionary = {}

var _current_instance: Node3D = null


func show_variant(key: Variant) -> void:
	if _current_instance:
		_current_instance.queue_free()
		_current_instance = null

	var variant: Variant = variants.get(key)
	if variant == null:
		return

	var instance: Node = null
	if variant is PackedScene:
		instance = variant.instantiate()
	elif variant is Node:
		instance = variant.duplicate()

	if instance == null:
		return

	_current_instance = instance
	entity.add_child(instance)


func _cleanup() -> void:
	if _current_instance:
		_current_instance.queue_free()
		_current_instance = null
