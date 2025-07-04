extends Node2D

func _on_start_pressed():
	get_tree().change_scene_to_file("res://main.tscn")
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _on_about_pressed():
	pass # Replace with function body.
