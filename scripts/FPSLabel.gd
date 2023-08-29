extends RichTextLabel

func _process(delta: float) -> void:
	set_text(str(Engine.get_frames_per_second()) + " [b]FPS[/b]")
