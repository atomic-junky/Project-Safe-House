extends Control


@export var shelter: Node3D

@export_subgroup("Overlays")
@export var background_overlay: ColorRect
@export var build_overlay: Control
@export var popus_overlay: Control


func _ready():
	background_overlay.hide()
	build_overlay.hide()
	popus_overlay.hide()