extends Control 

const MAIN_GAME_SCENE = preload("res://main.tscn")

func _on_start_button_pressed():
	get_tree().change_scene_to_packed(MAIN_GAME_SCENE)
