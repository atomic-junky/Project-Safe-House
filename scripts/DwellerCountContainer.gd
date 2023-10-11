extends HBoxContainer


const Dweller = preload("res://assets/dwellers/Dweller.tscn")
const dweller_type = preload("res://scripts/Dweller/Dweller.gd")

@onready var main = $"../../../../../../Main"
@onready var dweller_count = $DwellerCount


func update_dweller_count():
	var count = main.get_all_dwellers().size()
	dweller_count.text = str(count) + (" dwellers" if count > 1 else " dweller")


func _on_add_dweller_pressed():
	var on_hold_count = main.dc_on_hold.get_child_count()
	
	var new_dweller = Dweller.instantiate()
	new_dweller.position = Vector3(0, 47.095, 28)
	main.dc_on_hold.add_child(new_dweller)
	new_dweller.instructions.append(Instructions.MOVE_ON_FLOOR)
	new_dweller.target_positions.append(Vector3(0, 47.095, -1 + 0.5 * (on_hold_count)))
	update_dweller_count()


func _on_remove_dweller_pressed():
	var dwellers = main.get_all_dwellers()
	if dwellers.size() > 0:
		dwellers[dwellers.size() - 1].queue_free()
	update_dweller_count()


func _on_main_ready():
	update_dweller_count()
