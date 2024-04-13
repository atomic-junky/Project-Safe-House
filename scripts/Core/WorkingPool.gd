class_name WorkingPool


var _spots = {

}


func _init(parameters: WorkingPoolParameters = WorkingPoolParameters._default()):
	for s in parameters._sizes.keys():
		_spots[s] = [] 
		for pos in parameters._sizes[s]:
			_spots[s].append({
				"position": pos,
				"dweller": null
			})

func is_full(room_size):
	var free_slots = _spots[room_size].filter(func(s): return s.dweller == null)
	return len(free_slots) <= 0

func _assign_dweller(room_size, dweller: Dweller):
	if is_full(room_size):
		return
	
	var slot = _spots[room_size].filter(func(s): return s.dweller == null).pick_random()
	slot.dweller = dweller

func _deassign_dweller(room_size, dweller: Dweller):
	pass

func get_position(room_size, dweller):
	var slot = _spots[room_size].filter(func(s): return s.dweller != null and s.dweller.id == dweller.id)
	if len(slot) > 0:
		return slot[0].get("position")

func is_taken_at(room_size, spot_id):
	pass

func get_one(room_size, spot_id):
	pass

func get_all(room_size):
	pass
