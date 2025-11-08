class_name DwellerManager
extends Node

signal dweller_registered(dweller_id: String)
signal dweller_unregistered(dweller_id: String)

const DwellerEntity := preload("res://scripts/entities/DwellerEntity.gd")

var _dwellers: Dictionary[String, DwellerEntity] = {}


func register(dweller: DwellerEntity) -> void:
	if dweller == null:
		return
	var dweller_id: String = dweller.id
	if dweller_id.is_empty():
		dweller_id = str(dweller.get_instance_id())
	_dwellers[dweller_id] = dweller
	emit_signal("dweller_registered", dweller_id)


func unregister(dweller_id: String) -> void:
	if not _dwellers.has(dweller_id):
		return
	_dwellers.erase(dweller_id)
	emit_signal("dweller_unregistered", dweller_id)


func get_dweller(dweller_id: String) -> DwellerEntity:
	return _dwellers.get(dweller_id, null)


func all() -> Array[DwellerEntity]:
	var result: Array[DwellerEntity] = []
	for dweller: DwellerEntity in _dwellers.values():
		result.append(dweller)
	return result
