extends RichTextLabel

func _process(_delta: float) -> void:
	set_text(str(Engine.get_frames_per_second()) + " [b]FPS[/b]")
