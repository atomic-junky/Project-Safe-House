class_name ShelterController
extends Node

signal build_request_issued(payload: Dictionary)
signal room_network_changed(payload: Dictionary)

var room_manager: RoomManager = null
var elevator_manager: ElevatorManager = null
var build_manager: BuildManager = null
var dweller_manager: DwellerManager = null


func bind_managers(managers: Dictionary[String, Node]) -> void:
	room_manager = managers.get("room") as RoomManager
	elevator_manager = managers.get("elevator") as ElevatorManager
	build_manager = managers.get("build") as BuildManager
	dweller_manager = managers.get("dweller") as DwellerManager


func request_build(payload: Dictionary) -> void:
	emit_signal("build_request_issued", payload)


func notify_room_network(payload: Dictionary) -> void:
	emit_signal("room_network_changed", payload)
