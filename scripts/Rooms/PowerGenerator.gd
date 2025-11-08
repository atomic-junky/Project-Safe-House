extends AbstractRoom

class_name PowerGenerator

var room_name: String = "Power Generator"


func _constructor() -> void:
	type = GlobalRoomManager.RoomType.ROOM_POWER_GENERATOR
	var params: WorkingPoolParameters = WorkingPoolParameters._default()
	working_spots = WorkingPool.new(params)
