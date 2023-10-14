extends Control


enum room_list { ELEVATOR = 2, POWER_GENERATOR = 4, WATER_TREATMENT = 5, DINER = 6, LIVING_ROOM = 7 }
@export var room: room_list
@onready var main_game = get_tree().current_scene.find_child("Main")
var mouse_hover: bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	var texture
	match room:
		room_list.ELEVATOR:
			$Label.text = "Elevator"
			texture = card_texture()
		room_list.POWER_GENERATOR:
			$Label.text = "Power Generator"
			texture = card_texture("S")
		room_list.WATER_TREATMENT:
			$Label.text = "Water Treatment"
			texture = card_texture("P")
		room_list.DINER:
			$Label.text = "Diner"
			texture = card_texture("E")
		room_list.LIVING_ROOM:
			$Label.text = "Living Room"
			texture = card_texture("C")
			
	
	if texture:
		$Card.texture_normal = texture


func _on_texture_button_pressed():
	Global.build_mode = true
	Global.interface_mode = false
	Global.build_room = room
	main_game.toggle_build_mode(room)
	get_tree().current_scene.find_child("BuildOverlay").hide()
	

func card_texture(special: String = ""):
	var path = "res://assets/buttons/cards/card" + special + ".png"
	return load(path)
