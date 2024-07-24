class_name ENavigationRunning extends Transition


const TRAVEL_SPEED = 1.0

var room: Room
var _target_pos: Vector3
var _nav_height: float


func _is_valid(actor: Node) -> bool:
	# TODO: Clean this
	if state._target_pos and state._target_pos == actor.global_position:
		if actor.map_path.is_empty():
			if actor.assigned_room.has_dweller(actor) and !state.nav_state:
				return true
	return false

func _enter(actor: Node) -> void:
	room = actor.assigned_room
	if room.get_navigation_region() == null:
		return

	_nav_height = room.get_navigation_region().navigation_mesh.cell_height

	var pos = room.get_work_position(actor) + room.global_position
	var map = room.get_navigation_region().get_navigation_map()
	var p = NavigationServer3D.map_get_closest_point(map, pos)

	actor._agent.target_position = p
	_target_pos = actor._agent.get_next_path_position()
	_target_pos.y -= _nav_height


func _update(delta: float, actor: Node) -> void:
	if room.get_navigation_region() == null:
		completed.emit()
		Logger.warn("Ended on room that as no NavigationRegion3D!")
		return

	if _target_pos == actor.global_position:
		if actor._agent.is_navigation_finished():
			completed.emit()
			return
		
		_target_pos = actor._agent.get_next_path_position()
		_target_pos.y -= _nav_height

	actor.move_to_position(delta, _target_pos, TRAVEL_SPEED)
