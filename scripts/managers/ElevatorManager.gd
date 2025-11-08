class_name ElevatorManager
extends Node

signal network_updated()

const RoomEntity := preload("res://scripts/entities/RoomEntity.gd")

var _shafts: Array[RoomEntity] = []


func register(shaft: RoomEntity) -> void:
	if shaft == null:
		return
	if _shafts.has(shaft):
		return
	_shafts.append(shaft)
	_emit_network()


func unregister(shaft: RoomEntity) -> void:
	if not _shafts.has(shaft):
		return
	_shafts.erase(shaft)
	_emit_network()


func shafts() -> Array[RoomEntity]:
	return _shafts.duplicate()


func _emit_network() -> void:
	emit_signal("network_updated")
