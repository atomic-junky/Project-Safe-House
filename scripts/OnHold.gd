extends Node


func update_positions():
	var dwellers = get_children()
	for i in get_child_count():
		var dweller = dwellers[i-1]
		dweller.instructions.append(Instructions.MOVE_ON_FLOOR)
		dweller.target_positions.append(Vector3(0, 47.095, -1 + 0.5 * i))
