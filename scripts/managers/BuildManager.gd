class_name BuildManager
extends Node

signal build_mode_changed(active: bool)
signal location_checked(result: Dictionary)

var _is_build_mode: bool = false


func enable_build_mode() -> void:
	if _is_build_mode:
		return
	_is_build_mode = true
	emit_signal("build_mode_changed", true)


func disable_build_mode() -> void:
	if not _is_build_mode:
		return
	_is_build_mode = false
	emit_signal("build_mode_changed", false)


func is_build_mode() -> bool:
	return _is_build_mode


func validate_location(payload: Dictionary) -> void:
	emit_signal("location_checked", payload)
