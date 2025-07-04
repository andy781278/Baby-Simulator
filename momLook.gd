extends StaticBody3D

var leaving = false

func _ready():
	if !auto.day >= 2:
		hide()

func leave():
	leaving = true
	await get_tree().create_timer(0.5).timeout
	$momWindow/leave.play("leave")
