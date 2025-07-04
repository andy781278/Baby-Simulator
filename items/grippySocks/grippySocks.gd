extends Area3D

@onready var player = get_node("/root/main/baby")

func _process(_delta):
	$mesh.rotation.y += 0.003

func _on_body_entered(body):
	if body.is_in_group("baby"):
		player.currentItem = self

func _on_body_exited(body):
	if body.is_in_group("baby")&&player.currentItem == self:
		player.currentItem = null

func getTexture():
	return $mesh.mesh.material.albedo_texture

func trigger():
	player.gripped = true
	player.speedMod += 0.3
