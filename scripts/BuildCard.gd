extends Control


@export var room: int # Type: RoomList
@onready var main_game = get_tree().current_scene.find_child("Main")
var mouse_hover: bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	var texture
	match room:
		RoomList.ELEVATOR:
			$Label.text = "Elevator"
			texture = card_texture()
		RoomList.LIVING_ROOM:
			$Label.text = "Living Room"
			texture = card_texture("C")
		RoomList.POWER_GENERATOR:
			$Label.text = "Power Generator"
			texture = card_texture("S")
		RoomList.DINER:
			$Label.text = "Diner"
			texture = card_texture("E")
		RoomList.WATER_TREATMENT:
			$Label.text = "Water Treatment"
			texture = card_texture("P")
		RoomList.STORAGE_ROOM:
			$Label.text = "Storage Room"
			texture = card_texture("E")
		RoomList.MEDBAY:
			$Label.text = "Medbay"
			texture = card_texture("I")
		RoomList.SCIENCE_LAB:
			$Label.text = "Science Lab"
			texture = card_texture("I")
			
	
	if texture:
		$Card.texture_normal = texture


func _on_texture_button_pressed():
	Global.build_mode = true
	Global.interface_mode = false
	Global.build_room = room
	
	GlobalSignal.emit("build_card_selected", [room])
	
	# main_game.toggle_build_mode(room)
	# get_tree().current_scene.find_child("BuildOverlay").hide()
	

func card_texture(special: String = ""):
	var path = "res://assets/buttons/cards/card" + special + ".png"
	return load(path)
