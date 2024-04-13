extends Object

class_name Room

var id: String = UUID.v4()
var positions: Array[Vector2]
var size: int = 1 :
	get:
		return len(positions)

var max_size: int = 3

var dwellers: Array = []
var working_spots: WorkingPool = WorkingPool.new()


func _init() -> void:
	call("_constructor")
	
	Logger.info("Room(" + id + ") created")

# Overwritable function called at initialization
func _constructor() -> void:
	pass

func _register_dweller(dweller: Dweller) -> void:
	if not dwellers.has(dweller.id):
		dwellers.append(dweller.id)
	
	working_spots._assign_dweller(size, dweller)

func _forget_dweller(dweller: Dweller) -> void:
	if dwellers.has(dweller.id):
		dwellers.erase(dweller.id)

func get_work_position(dweller: Dweller):
	return working_spots.get_position(size, dweller)

func _sort_postions(a: Vector2, b: Vector2) -> bool:
	if a.x < b.x:
		return true
	return false

func get_first_position():
	var result = positions.duplicate()
	result.sort_custom(_sort_postions)
	
	return result[0]
