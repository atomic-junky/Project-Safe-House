extends MarginContainer
class_name RoomWindow


@export var room_label: Label
@export var destroy_btn: Button

var _room: Room


func set_room(room: Room):
	_room = room

	var short_id = room.id.split("-")[0]
	room_label.text = room.room_name + " (" + short_id + ")"

	destroy_btn.visible = room.can_be_destroy()


func _on_destroy_btn_pressed():
	_room.destroy()
	get_parent().background_overlay.hide_all()
