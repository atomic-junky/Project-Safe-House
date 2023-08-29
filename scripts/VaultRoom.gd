extends Node
class_name VaultRoom

var id: String = "-1"
var type = RoomList.DIRT

func _init(_type, _id = "-1"):
	self.id = _id
	self.type = _type
	
	if self.id == "-1":
		self.id = uuid.v4()
