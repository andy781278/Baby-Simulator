extends CharacterBody3D

var vel = Vector3.ZERO

func _physics_process(_delta):
	move_and_slide()

func _on_collision_area_area_entered(area):
	if area.is_in_group("pebable"):
		area.get_parent().stun()
		queue_free()

func _on_lifetime_timeout():
	queue_free()
