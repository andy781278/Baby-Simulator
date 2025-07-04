extends CharacterBody3D

var introdad = [preload("res://sfx/intro dad.mp3"),preload("res://sfx/intro dad 2.mp3"),\
preload("res://sfx/intro dad 3.mp3")]
var skiptimes = [9,13,21]
#when dad sees baby
var dadfound = [preload("res://sfx/dad found 1.mp3"),preload("res://sfx/dad found 2.mp3"),\
preload("res://sfx/dad found 3.mp3")]
#when dad hears baby
var dadheard = [preload("res://sfx/dad heard 1.mp3"),preload("res://sfx/dad heard 2.mp3"),\
preload("res://sfx/dad heard 3.mp3")]
#when dad is chilling
var dadidle = [preload("res://sfx/dad idle 1.mp3"),preload("res://sfx/dad idle 2.mp3"),\
preload("res://sfx/dad idle 3.mp3"),preload("res://sfx/dad idle 4.mp3"),\
preload("res://sfx/dad idle 5.mp3"),preload("res://sfx/dad idle 6.mp3"), ]
#when dad no longer sees the baby
var dadlost = [preload("res://sfx/dad lost 1.mp3"),preload("res://sfx/dad lost 2.mp3"),\
preload("res://sfx/dad lost 3.mp3")]
#when dad puts the baby back down
var dadput = [preload("res://sfx/dad put 1.mp3"),preload("res://sfx/dad put 2.mp3"),\
preload("res://sfx/dad put 3.mp3")]
#when baby vomits on dad
var dadStun = preload("res://sfx/dadStun.mp3")

var speed = 5

var doing = "looking" # looking, chasing, putting

var playerIn = false
var playerSee = false
var slowed = false
var player
var main
var roomLocs
var posmesh

var angleTo = 0

var gravity : float = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	main = get_node("/root/main")
	player = get_node("/root/main/baby")
	roomLocs = get_node("/root/main/roomLocs")
	posmesh = get_node("/root/main/pos")
	
	playSound(introdad[auto.day-1])
	await get_tree().create_timer(skiptimes[auto.day-1]).timeout
	auto.dayStarted = true
	main.get_node("invisWall").get_child(0).disabled = true
	main.playMusic()
	$AnimationPlayer.current_animation = "run"
	getNewCoords()
	startIdleAudioTimer()
	player.startStarving()

func _process(_delta):
	
	#change animation speed and reuglar speed
	
	if $AnimationPlayer.current_animation == "run":
		var finalSpeed
		if doing == "chasing":
			finalSpeed = speed+player.bottles
			$AnimationPlayer.speed_scale = 1.5+(player.bottles*0.2)
		else:
			finalSpeed = (speed/2)+player.bottles
			$AnimationPlayer.speed_scale = 0.5+(player.bottles*0.2)
		if slowed:
			finalSpeed *= 0.25
		var newVel = ($navAgent.get_next_path_position() - position).normalized() * finalSpeed
	
		velocity = newVel
		angleTo = Vector2(newVel.z,newVel.x).angle()+PI
	else:
		velocity.x = 0
		velocity.z = 0
	
	if doing =="putting":
		$AnimationPlayer.current_animation = "run"
		updateTargetLoc(roomLocs.get_child(roomLocs.get_child_count()-1).position)
	
	if abs(player.position.y-position.y) >= 5:
		$footstep.pitch_scale = 0.4
	else:
		$footstep.pitch_scale = 0.6
	
	move_and_slide()
	
	$Armature.rotation.y = lerp_angle($Armature.rotation.y,angleTo,0.1)
	
	if playerIn&&doing!="putting"&&!player.inSpawn&&!$stunCD.time_left > 0:
		$checkPlayer.target_position = (player.global_position - $checkPlayer.global_position)*2
		
		if $checkPlayer.is_colliding()&&$checkPlayer.get_collider().is_in_group("baby"):
			playerSee = true
			if doing == "looking"&&$seeBabyAudioCD.time_left <= 0:
				playSound(rand(dadfound))
				$seeBabyAudioCD.start()
			doing = "chasing"
			$AnimationPlayer.current_animation = "run"
			updateTargetLoc(player.position)
	
func walk():
	if doing=="putting":
		return
	if randf() > 0.75:#run
		$AnimationPlayer.current_animation = "run"
		getNewCoords()
	else: #still
		$AnimationPlayer.current_animation = "idle"
		$walk_timer.wait_time = randf_range(1,3)#0.5,3
		$walk_timer.start()
	
func _on_walk_timer_timeout():
	walk()

func updateTargetLoc(target_pos : Vector3):
	$navAgent.target_position = target_pos

func getNewCoords():
	var locIndex = randi()%(roomLocs.get_child_count()-1)
	var locNode = roomLocs.get_child(locIndex)
	updateTargetLoc(locNode.position)

func _on_nav_agent_target_reached():
	if doing == "putting":
		putDownBaby()
		return
	$AnimationPlayer.current_animation = "idle"
	if doing == "chasing":
		if !player.inSpawn:
			playSound(rand(dadlost))
		else:
			getNewCoords()
			playSound(rand(dadput))
		doing = "looking"
	$walk_timer.wait_time = randf_range(1,3)#0.5,3
	$walk_timer.start()

func reachedBaby():
	if doing == "putting"&&$stunCD.time_left > 0:
		return
	doing = "putting"
	player.stopSlip()
	player.headbob_animation(false)
	await get_tree().process_frame
	player.get_parent().remove_child(player)
	$Armature/playerpos.add_child(player)
	player.position = Vector3.ZERO
	player.collider.disabled = true
	player.caught = true
	player.flying = false
	player.cry()
	if !player.vomitReady:
		return
	player.vomitReady = false
	await get_tree().create_timer(2).timeout
	if !player.caught:
		return
	player.playBurp()
	player.vomit()
	$stunCD.start()
	playSound(dadStun)
	doing = "looking"
	$AnimationPlayer.play("idle")
	var tempPos = player.global_position
	$Armature/playerpos.remove_child(player)
	main.add_child(player)
	player.collider.disabled = false
	player.caught = false
	player.position = tempPos

func putDownBaby():
	playSound(rand(dadput))
	doing = "looking"
	await get_tree().process_frame
	$Armature/playerpos.remove_child(player)
	main.add_child(player)
	player.collider.disabled = false
	player.caught = false
	player.position = $Armature/playerpos.global_position
	angleTo = PI
	position = Vector3(0,0,8)
	await get_tree().process_frame
	getNewCoords()

func playSound(sound):
	if auto.momOut:
		return
	$call.stream = sound
	$call.play()

func rand(arr):
	return arr[randi()%arr.size()]

func _on_idle_audio_timer_timeout():
	if doing != "chasing":
		playSound(rand(dadidle))
	startIdleAudioTimer()

func startIdleAudioTimer():
	$idleAudioTimer.wait_time = randf_range(10,30)
	$idleAudioTimer.start()

func heardNoise(pos):
	playSound(rand(dadheard))
	$AnimationPlayer.current_animation = "run"
	updateTargetLoc(pos)

func _on_grab_area_body_entered(body):
	if body.is_in_group("baby")&&!$stunCD.time_left > 0:
		reachedBaby()

func stun():
	if !$stunCD.is_stopped():
		return
	$stunCD.start()
	playSound(dadStun)
	doing = "looking"
	$AnimationPlayer.play("idle")
