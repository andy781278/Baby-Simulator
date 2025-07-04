extends RigidBody3D

var milk = 100

func _ready():
	hide()

func disable():
	$collider.set_deferred("disabled",true)
	hide()

func enable():
	$collider.disabled = false
	show()
