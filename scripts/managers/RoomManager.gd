class_name RoomManager
extends Node

signal room_registered(room: Node3D)
signal room_unregistered(room_id: String)

const RoomEntity := preload("res://scripts/entities/RoomEntity.gd")

var _rooms: Dictionary[String, RoomEntity] = {}


func register(room_id: String, room: RoomEntity) -> void:
	if room_id.is_empty() or room == null:
		return
	_rooms[room_id] = room
	emit_signal("room_registered", room)


func unregister(room_id: String) -> void:
	if not _rooms.has(room_id):
		return
	_rooms.erase(room_id)
	emit_signal("room_unregistered", room_id)



func get_room(room_id: String) -> RoomEntity:
	return _rooms.get(room_id, null)


func all() -> Array[RoomEntity]:
	var result: Array[RoomEntity] = []
	for room: RoomEntity in _rooms.values():
		result.append(room)
	return result
