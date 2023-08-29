extends Node3D


func _ready():
	$LegsAnimationPlayer.play("Idle")
	$ArmsAnimationPlayer.play("Idle")
