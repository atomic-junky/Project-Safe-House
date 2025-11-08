class_name EmptyLocation extends AbstractRoom


func _constructor() -> void:
	type = GlobalRoomManager.RoomType.ROOM_OUTSIDE
	max_size = 1


func _get_mesh():
	return null
