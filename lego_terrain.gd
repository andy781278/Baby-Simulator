extends Area3D

func _on_body_entered(body):
	if body.is_in_group("entity"):
		body.slowed = true

func _on_body_exited(body):
	if body.is_in_group("entity"):
		body.slowed = false

func _on_area_entered(area):
	if area.is_in_group("dadGrabArea"):
		area.get_parent().slowed = true

func _on_area_exited(area):
	if area.is_in_group("dadGrabArea"):
		area.get_parent().slowed = false
