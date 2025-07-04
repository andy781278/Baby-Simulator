extends Node

var day = 1
var dayStarted = false
var momOut = false

func nextDay():
	day+=1
	if day>3:
		get_tree().change_scene_to_file("res://win.tscn")
	else:
		get_tree().reload_current_scene()
