extends Control

enum SpecialTexture { S, P, E, C, I, A, L }

@export var room: GlobalRoomManager.RoomType
@export var room_name: String = ""
@export var special_texture: SpecialTexture
@onready var main_game = get_tree().current_scene.find_child("Main")
var mouse_hover: bool = false


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var texture: Texture2D
	$Label.text = room_name
	texture = card_texture(str(SpecialTexture.keys()[special_texture]))

	assert(texture != null)
	$Card.texture_normal = texture


func _on_texture_button_pressed() -> void:
	Global.build_mode = true
	Global.interface_mode = false
	Global.build_room = room

	SignalBus.build_card_selected.emit(room)

	# main_game.toggle_build_mode(room)
	# get_tree().current_scene.find_child("BuildOverlay").hide()


func card_texture(special: String = "") -> Texture2D:
	var path = "res://assets/buttons/cards/card" + special + ".png"
	return load(path)
