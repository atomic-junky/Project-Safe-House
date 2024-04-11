extends Object

class_name Room

var id: String = UUID.v4()
var positions: Array[Vector2]
var size: int = 1 :
	get:
		return len(positions)

var max_size: int = 3

var dwellers: Array = []


func _init() -> void:
	call("_constructor")
	
	Logger.info("Room(" + id + ") created")

# Overwritable function called at initialization
func _constructor() -> void:
	pass

func _register_dweller(dweller: Dweller) -> void:
	if not dwellers.has(dweller.id):
		dwellers.append(dweller.id)

func _forget_dweller(dweller: Dweller) -> void:
	if dwellers.has(dweller.id):
		dwellers.erase(dweller.id)
