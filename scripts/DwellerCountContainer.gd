extends HBoxContainer

var DwellerObject = preload("res://objects/dwellers/Dweller.tscn")

@onready var main = %Shelter
@onready var dweller_count = %DwellerCountLabel


func _ready():
	await main.ready
	update_dweller_count()


func update_dweller_count():
	var count = main.dweller_container.get_child_count()
	dweller_count.text = str(count)


func _on_add_dweller_pressed():	
	var new_dweller = DwellerObject.instantiate()
	new_dweller.position = Vector3(-1, 47.095, -1)
	main.dweller_container.add_child(new_dweller)
	update_dweller_count()


func _on_remove_dweller_pressed():
	var dwellers = main.dweller_container.get_children()
	if len(dwellers) > 0:
		dwellers[len(dwellers) - 1].free()
	update_dweller_count()


func _on_main_ready():
	update_dweller_count()
