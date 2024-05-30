extends CanvasLayer


signal loading_screen_has_full_coverage

@onready var cog_texture: TextureRect = %LoadingCog
@onready var animationPlayer: AnimationPlayer = $AnimationPlayer
@onready var progressLabel: Label = %ProgressLabel


func _update_progress_bar(new_value: float) -> void:
	progressLabel.text = str(int(new_value * 100)) + "%"


func _start_outro_animation() -> void:
	if animationPlayer.is_playing():
		await Signal(animationPlayer, "animation_finished")
	animationPlayer.play("end_load")
	await Signal(animationPlayer, "animation_finished")
	self.queue_free()


func _process(_delta):
	cog_texture.rotation_degrees += 1
