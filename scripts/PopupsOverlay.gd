extends Control
class_name PopupsOverlay

@export var background_overlay: ColorRect
@export var room_window: RoomWindow

func _ready():
	_hide_all()

func show_room_window(room: Room):
	_hide_all()
	show()
	room_window.set_room(room)
	room_window.show()
	background_overlay.show()

func _hide_all():
	hide()
	var all = [room_window]
	for i in all:
		i.hide()

func _gui_input(event):
	if event is InputEventMouseButton and event.is_pressed():
		if event.button_index in [MOUSE_BUTTON_WHEEL_DOWN, MOUSE_BUTTON_WHEEL_UP]:
			return
		background_overlay.hide_all()
		Global.interface_mode = false