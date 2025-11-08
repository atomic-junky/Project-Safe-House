class_name WorkComponent
extends "res://scripts/components/Component.gd"

var assigned_room: Node = null
var assigned_spot: Vector3 = Vector3.ZERO
var is_working: bool = false


func assign(room: Node, spot: Vector3 = Vector3.ZERO) -> void:
	assigned_room = room
	assigned_spot = spot
	is_working = room != null


func unassign() -> void:
	assigned_room = null
	assigned_spot = Vector3.ZERO
	is_working = false
