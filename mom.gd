extends CharacterBody3D
var main
var player
var dad
var roomLocs
var run

var speed = 12
var gravity : float = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	main = get_node("/root/main")
	roomLocs = get_node("/root/main/roomLocs")
	$ambience.play()
	getNewCoords()

func _process(_delta):
	var newVel = ($navAgent.get_next_path_position() - position).normalized() * speed
	velocity = velocity.move_toward(newVel,0.25)
	move_and_slide()

func getNewCoords():
	var locIndex = randi()%(roomLocs.get_child_count()-1)
	var locNode = roomLocs.get_child(locIndex)
	updateTargetLoc(locNode.position)

func updateTargetLoc(target_pos : Vector3):
	#posmesh.position = target_pos
	$navAgent.target_position = target_pos

func _on_nav_agent_target_reached():
	getNewCoords()

func _on_jumpscare_area_body_entered(body):
	if body.is_in_group("baby"):
		body.momJumpscare()
