extends HBoxContainer

var DwellerObject: PackedScene = preload("res://prefabs/dwellers/Dweller.tscn")

@export var shelter: Node3D
@export var dweller_count_label: Label


func _ready() -> void:
	await shelter.ready
	update_dweller_count()


func update_dweller_count() -> void:
	var count: int = shelter.dweller_container.get_child_count()
	dweller_count_label.text = str(count)


func _on_add_dweller_pressed() -> void:
	var new_dweller = DwellerObject.instantiate()
	new_dweller.position = Vector3(-1, 47.095, -1)
	shelter.dweller_container.add_child(new_dweller)
	update_dweller_count()


func _on_remove_dweller_pressed() -> void:
	var dwellers = shelter.dweller_container.get_children()
	if len(dwellers) > 0:
		dwellers[len(dwellers) - 1].free()
	update_dweller_count()


func _on_main_ready() -> void:
	update_dweller_count()
