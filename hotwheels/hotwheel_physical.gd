extends CharacterBody3D

@onready var PATH = $path/pathfollow
var dad

func _physics_process(delta):
	PATH.progress_ratio += 0.01
	if PATH.progress_ratio == 1:
		PATH.progress_ratio = 0

func _on_lifetime_timeout():
	queue_free()

func _on_sound_spam_timeout():
	dad.heardNoise(position)
