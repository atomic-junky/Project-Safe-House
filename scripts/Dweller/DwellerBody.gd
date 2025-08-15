extends Node3D

class_name DwellerBody


func _ready() -> void:
	$LegsAnimationPlayer.play("Idle")
	$ArmsAnimationPlayer.play("Idle")
