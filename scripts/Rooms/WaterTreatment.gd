extends AbstractRoom

class_name WaterTreatment

var room_name: String = "Water Treatment"


func _constructor() -> void:
	type = GlobalRoomManager.RoomType.ROOM_WATER_TREATMENT
