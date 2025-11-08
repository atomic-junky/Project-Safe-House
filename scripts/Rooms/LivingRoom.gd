extends AbstractRoom

class_name LivingRoom

var room_name: String = "Living Room"


func _constructor() -> void:
	type = GlobalRoomManager.RoomType.ROOM_LIVING_ROOM
