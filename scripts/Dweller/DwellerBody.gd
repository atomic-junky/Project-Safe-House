extends Node3D

class_name DwellerBody


func _ready():
	$LegsAnimationPlayer.play("Idle")
	$ArmsAnimationPlayer.play("Idle")
