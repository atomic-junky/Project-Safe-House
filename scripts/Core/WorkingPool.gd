class_name WorkingPool

var _spots = {

}

func _init(parameters: WorkingPoolParameters=WorkingPoolParameters._default()):
	for s in parameters._sizes.keys():
		_spots[s] = []
		for pos in parameters._sizes[s]:
			_spots[s].append({
				"position": pos,
				"dweller": null
			})

func is_full(room_size):
	var free_spots = _spots[room_size].filter(func(s): return s.dweller == null)
	return len(free_spots) <= 0

func is_empty(room_size):
	var taken_spots = get_all_taken(room_size)
	return len(taken_spots) <= 0

func _assign_dweller(room_size, dweller: Dweller) -> bool:
	if has_dweller(room_size, dweller):
		return true

	if is_full(room_size):
		return false
	
	var slot = _spots[room_size].filter(func(s): return s.dweller == null)[0]
	slot.dweller = dweller
	return true

func _deassign_dweller(room_size, dweller: Dweller):
	var spot = get_dweller_spot(room_size, dweller)
	if len(spot) <= 0:
		return

	spot[0].dweller = null

func get_dweller_spot(room_size, dweller):
	return _spots[room_size].filter(func(s): return s.dweller != null and s.dweller.id == dweller.id)

func get_position(room_size, dweller):
	var spot = get_dweller_spot(room_size, dweller)
	if len(spot) > 0:
		return spot[0].get("position")

func is_taken_at(room_size, spot_id):
	return get_one(room_size, spot_id).dweller != null

func get_one(room_size, spot_id):
	return _spots[room_size][spot_id]

func get_all(room_size):
	return _spots[room_size]

func get_all_taken(room_size):
	var taken_spots = _spots[room_size].filter(func(s): return s.dweller != null)
	return taken_spots

func has_dweller(room_size, dweller):
	return len(get_dweller_spot(room_size, dweller)) > 0