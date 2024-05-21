extends Node

signal progress_change(progress)
signal load_done

var _load_screen_path: String = "res://scenes/loading_screen.tscn"
var _load_screen = load(_load_screen_path)
var _load_resource: PackedScene
var _scene_path: String
var _progress: Array = []

var use_sub_threads: bool = false


func load_scene(scene_path: String) -> void:
	_scene_path = scene_path
	
	var new_loading_screen = _load_screen.instantiate()
	get_tree().get_root().add_child.call_deferred(new_loading_screen)
	
	self.progress_change.connect(new_loading_screen._update_progress_bar)
	self.load_done.connect(new_loading_screen._start_outro_animation)
	
	await Signal(new_loading_screen, "loading_screen_has_full_coverage")
	
	start_load()


func start_load() -> void:
	var state = ResourceLoader.load_threaded_request(_scene_path, "", use_sub_threads)
	if state == OK:
		set_process(true)


func _process(_delta):
	var load_status = ResourceLoader.load_threaded_get_status(_scene_path, _progress)
	match load_status:
		0, 2: #? THREAD_LOAD_INVALID_RESOURCE, THREAD_LOAD_FAILED
			set_process(false)
			return
		1: #? THREAD_LOAD_IN_PROGRESS
			emit_signal("progress_change", _progress[0])
		3: #? THREAD_LOAD_LOADED
			_load_resource = ResourceLoader.load_threaded_get(_scene_path)
			emit_signal("progress_change", 1.0)
			emit_signal("load_done")
			get_tree().change_scene_to_packed(_load_resource)
	
