extends Control

@onready var tabs_container = $Container/TabsContainer

# Called when the node enters the scene tree for the first time.
func _ready():
	_on_tab_bar_tab_changed(0)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	

func _on_tab_bar_tab_changed(tab):
	for _tab in tabs_container.get_children():
		_tab.hide()
	tabs_container.get_child(tab).show()


func _on_build_button_pressed():
	show()
	Global.interface_mode = true
	
func _gui_input(event):
	if event is InputEventMouseButton and event.is_pressed():
		if event.button_index in [MOUSE_BUTTON_WHEEL_DOWN, MOUSE_BUTTON_WHEEL_UP]:
			return
		hide()
		Global.interface_mode = false
