extends Control

const MAIN_SCENE_PATH := "res://scenes/Main.tscn"

@onready var back_button: Button = $"Layout/BackButton"

func _ready() -> void:
    back_button.pressed.connect(_on_back_button_pressed)

func _on_back_button_pressed() -> void:
    get_tree().change_scene_to_file(MAIN_SCENE_PATH)
