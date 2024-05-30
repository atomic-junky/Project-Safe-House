class_name ENavigationRunningCState
extends CompositeState


const TRAVEL_SPEED = 1.0

var room: Room
var _target_pos: Vector3
var _nav_height: float


func _enter(_msg={}) -> void:
    room = node.assigned_room
    if room.get_navigation_region() == null:
        return

    _nav_height = room.get_navigation_region().navigation_mesh.cell_height

    var pos = room.get_work_position(node) + room.global_position
    var map = room.get_navigation_region().get_navigation_map()
    var p = NavigationServer3D.map_get_closest_point(map, pos)

    node._agent.target_position = p
    _target_pos = node._agent.get_next_path_position()
    _target_pos.y -= _nav_height


func _do(delta: float) -> void:
    if room.get_navigation_region() == null:
        completed.emit()
        Logger.warn("Ended on room that as no NavigationRegion3D!")
        return

    if _target_pos == node.global_position:
        if node._agent.is_navigation_finished():
            completed.emit()
            return
        
        _target_pos = node._agent.get_next_path_position()
        _target_pos.y -= _nav_height

    node.move_to_position(delta, _target_pos, TRAVEL_SPEED)