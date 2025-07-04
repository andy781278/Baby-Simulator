extends CharacterBody3D
var skiptimes = [9,13,21]
var kidfound = [preload("res://sfx/kid found 1.mp3"),preload("res://sfx/kid found 2.mp3"),\
preload("res://sfx/kid found 3.mp3")]
var kididle = [preload("res://sfx/kid idle 1.mp3"),preload("res://sfx/kid idle 2.mp3"),\
preload("res://sfx/kid idle 3.mp3"),preload("res://sfx/kid idle 4.mp3"),\
preload("res://sfx/kid idle 5.mp3"),preload("res://sfx/kid idle 6.mp3"),\
preload("res://sfx/kid idle 7.mp3")]
var pebbled = preload("res://sfx/pebbleNeighbor.mp3")
var banana = preload("res://banana_peel.tscn")

var playerIn = false
var playerSee = false
var slowed = false
var main
var player
var dad
var roomLocs
var run

var speed = 2

var angleTo = 0

var gravity : float = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	main = get_node("/root/main")
	player = get_node("/root/main/baby")
	roomLocs = get_node("/root/main/roomLocs")
	dad = get_node("/root/main/dad")
	walk()
	$bananaTimer.wait_time = randf_range(1,2)
	$bananaTimer.start()
	await get_tree().create_timer(skiptimes[auto.day-1]).timeout
	startIdleAudioTimer()

func _process(_delta):
	
	if run:
		var newVel = ($navAgent.get_next_path_position() - position).normalized()
		if slowed:
			newVel = newVel*speed*0.5
		else:
			newVel = newVel*speed
		$navAgent.set_velocity(newVel)
		angleTo = Vector2(newVel.z,newVel.x).angle()+PI
	else:
		velocity.x = 0
		velocity.z = 0
	
	if playerIn&&!player.inSpawn&&$stunCD.is_stopped():
		$checkPlayer.target_position = (player.global_position - $checkPlayer.global_position)*2
		
		if $checkPlayer.is_colliding()&&$checkPlayer.get_collider().is_in_group("baby"):
			playerSee = true
			dad.heardNoise(player.position)
			if $seeBabyAudioCD.time_left <= 0:
				playSound(rand(kidfound))
				$seeBabyAudioCD.start()

func getNewCoords():
	var locIndex = randi()%(roomLocs.get_child_count()-1)
	var locNode = roomLocs.get_child(locIndex)
	updateTargetLoc(locNode.position)

func _on_walk_timer_timeout():
	walk()

func updateTargetLoc(target_pos : Vector3):
	#posmesh.position = target_pos
	$navAgent.target_position = target_pos

func playSound(sound):
	$call.stream = sound
	$call.play()

func rand(arr):
	return arr[randi()%arr.size()]

func _on_nav_agent_target_reached():
	$walk_timer.wait_time = randf_range(1,3)#0.5,3
	$walk_timer.start()

func walk():
	if randf() > 0.75:#run
		getNewCoords()
		run = true
	else: #still
		run = false
		$walk_timer.wait_time = randf_range(1,3)#0.5,3
		$walk_timer.start()

func _on_sense_body_entered(body):
	if body.is_in_group("baby"):
		playerIn = true

func _on_sense_body_exited(body):
	if body.is_in_group("baby"):
		playerIn = false

func _on_idle_audio_timer_timeout():
	if !playerSee:
		playSound(rand(kididle))
	startIdleAudioTimer()

func startIdleAudioTimer():
	$idleAudioTimer.wait_time = randf_range(10,30)
	$idleAudioTimer.start()

func _on_nav_agent_velocity_computed(safe_velocity):
	velocity = safe_velocity
	move_and_slide()

func _on_banana_timer_timeout():
	var Banana = banana.instantiate()
	get_parent().add_child(Banana)
	Banana.position = position
	$bananaTimer.wait_time = randf_range(8,20)
	$bananaTimer.start()

func stun():
	if !$stunCD.is_stopped():
		return
	$stunCD.start()
	playSound(pebbled)
	$modelp.show()
	$model.hide()

func _on_stun_cd_timeout():
	$model.show()
	$modelp.hide()
