extends Node2D

class_name StateMachine

# TODO: Create a big state machine system for rooms, entities and objects

var _change_state
var _animated_sprite
var _persistent_state


func _process(_delta):
    pass

func setup(change_state, animated_sprite, persistent_state):
    self._change_state = change_state
    self._animated_sprite = animated_sprite
    self._persistent_state = persistent_state

func move_left():
    pass

func move_right():
    pass