extends RigidBody3D

var leaving = false

func leave():
	leaving = true
	$momWindow/leave.play("leave")
