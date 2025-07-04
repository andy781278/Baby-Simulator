extends CharacterBody3D

var laugh = [preload("res://sfx/baby laugh 1.wav"),\
preload("res://sfx/baby laugh 2.wav"),preload("res://sfx/baby laugh 3.wav")]
var Pebble = preload("res://pebble.tscn")
var legoTerrain = preload("res://lego_terrain.tscn")
var Hotwheel = preload("res://hotwheels/hotwheelPhysical.tscn")

@onready var collider = $collider
var dad
var main
var roomLocs

@export_category("Character")
@export var base_speed : float = 3.0
@export var sprint_speed : float = 6.0
@export var crouch_speed : float = 1.0

@export var acceleration : float = 10.0
@export var jump_velocity : float = 4.5
@export var mouse_sensitivity : float = 0.1

@export var initial_facing_direction : Vector3 = Vector3.ZERO

@export_group("Nodes")
@export var HEAD : Node3D
@export var CAMERA : Camera3D
@export var HEADBOB_ANIMATION : AnimationPlayer
@export var JUMP_ANIMATION : AnimationPlayer
@export var CROUCH_ANIMATION : AnimationPlayer
@export var COLLISION_MESH : CollisionShape3D

@export_group("Controls")
@export var JUMP : String = "ui_accept"
@export var LEFT : String = "ui_left"
@export var RIGHT : String = "ui_right"
@export var FORWARD : String = "ui_up"
@export var BACKWARD : String = "ui_down"
@export var PAUSE : String = "ui_cancel"
@export var CROUCH : String
@export var SPRINT : String

@export_group("Feature Settings")
@export var immobile : bool = false
@export var jumping_enabled : bool = true
@export var in_air_momentum : bool = true
@export var motion_smoothing : bool = true
@export var sprint_enabled : bool = true
@export var crouch_enabled : bool = true
@export_enum("Hold to Crouch", "Toggle Crouch") var crouch_mode : int = 0
@export_enum("Hold to Sprint", "Toggle Sprint") var sprint_mode : int = 0
@export var dynamic_fov : bool = true
@export var continuous_jumping : bool = true
@export var view_bobbing : bool = true
@export var jump_animation : bool = true

# Member variables
var speed : float = base_speed
var current_speed : float = 0.0
# States: normal, crouching, sprinting
var state : String = "normal"
var low_ceiling : bool = false # This is for when the cieling is too low and the player needs to crouch.
var was_on_floor : bool = true
var gravity : float = ProjectSettings.get_setting("physics/3d/default_gravity")

var speedMod : float = 1.0
var staminaRegenMod : float = 1.0
var jumpSpeedMod : float = 1.0

var bottles = 0:
	set(val):
		bottles=val
		$gui/numBottles.text = str(bottles) + "/" + str(bottleMax)
var bottleMax = 3:
	set(val):
		bottleMax=val
		$gui/numBottles.text = str(bottles) + "/" + str(bottleMax)
var currentBottle

var stamina = 100.0:
	set(val):
		var clamped = clamp(val,0.0,100.0)
		stamina = clamped
		$gui/stamina.value = clamped
		
		if stamina >= 100:
			$gui/stamina.hide()
		else:
			$gui/stamina.show()

var timeLeft : int = 180
var numPebbles : int = 0:
	set(val):
		numPebbles=val
		$gui/numPebbles.text = str(numPebbles)
		if val>0:
			$gui/numPebbles.show()
			$gui/pebble.show()
		else:
			$gui/numPebbles.hide()
			$gui/pebble.hide()

var resting = true
var caught = false
var inSpawn = false
var lost = false
var flying = false
var vomitReady = false
var pacified = false
var slowed = false
var gripped = false
var hasFunnel = false

var debug = false

var currentItem = null
var heldItem = null


func _ready():
	dad = get_node("/root/main/dad")
	main = get_node("/root/main")
	roomLocs = get_node("/root/main/roomLocs")
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	# Set the camera rotation to whatever initial_facing_direction is
	if initial_facing_direction:
		HEAD.set_rotation_degrees(initial_facing_direction) # I don't want to be calling this function if the vector is zero
	
	# Reset the camera position
	HEADBOB_ANIMATION.play("RESET")
	JUMP_ANIMATION.play("RESET")
	
	$laugh_timer.wait_time = randf_range(20,35)
	$laugh_timer.start()
	
	if auto.get_child_count()>0:
		var item = auto.get_child(0)
		auto.remove_child(item)
		$item.add_child(item)
		$gui/item.texture = item.getTexture()
		item.player = self
	
	$gui/dayCount.text = "DAY "+str(auto.day)
	$gui/dayCount.show()
	await get_tree().create_timer(5).timeout
	$gui/dayCount.hide()

func _input(event):
	if event.is_action_pressed("ui_q")&&$cry_timer.time_left <= 0&&!lost:
		$cry_timer.start()
		$"fake cry sfx".play()
		if !inSpawn:
			dad.heardNoise(position)
	
	if currentItem != null && event.is_action_pressed("use"):
		var item = currentItem
		if $item.get_child_count()>0:
			var itemInHand = $item.get_child(0)
			$item.remove_child(itemInHand)
			get_parent().add_child(itemInHand)
			itemInHand.position = item.position
		get_parent().remove_child(item)
		$item.add_child(item)
		currentItem = null
		$gui/item.texture = item.getTexture()
	
	if $item.get_child_count()>0 && event.is_action_pressed("ui_left_click"):
		var item = $item.get_child(0)
		item.trigger()
		$item.remove_child(item)
		item.queue_free()
		$gui/item.texture = null
		$swallow.play()
	
	if numPebbles > 0 && !caught && event.is_action_pressed("throw"):
		throwPebble()
	
	if debug:
		if event.is_action_pressed("1"):
			main.spawnItem(6,position)
		if event.is_action_pressed("2"):
			main.spawnItem(7,position)
		if event.is_action_pressed("3"):
			main.spawnItem(8,position)
		if event.is_action_pressed("4"):
			main.spawnItem(9,position)
		if event.is_action_pressed("5"):
			main.spawnItem(10,position)
		if event.is_action_pressed("6"):
			main.spawnItem(11,position)

func _physics_process(delta):
	if lost:
		return
	current_speed = Vector3.ZERO.distance_to(get_real_velocity())
	var cv : Vector3 = get_real_velocity()
	var vd : Array[float] = [
		snappedf(cv.x, 0.001),
		snappedf(cv.y, 0.001),
		snappedf(cv.z, 0.001)
	]
	
	if !is_on_floor() && !flying:
		velocity.y -= gravity * delta
	
	handle_jumping()
	
	var input_dir = Vector2.ZERO
	if !immobile:
		input_dir = Input.get_vector(LEFT, RIGHT, FORWARD, BACKWARD)
	if !flying:
		handle_movement(delta, input_dir)
	else:
		stamina -= 0.5
		CAMERA.fov = lerp(CAMERA.fov, 100.0, 0.3)
		handle_fly(delta)
	
	handle_state(input_dir)
	if !lost&&!caught&&!flying:
		update_camera_fov()
		headbob_animation(input_dir)
	
	if jump_animation:
		if !was_on_floor and is_on_floor(): # Just landed
			JUMP_ANIMATION.play("land")
		
		was_on_floor = is_on_floor() # This must always be at the end of physics_process
	
	if state == "sprinting":
		stamina -= 0.1
		if stamina <= 0:
			enter_normal_state()
	
	if resting:
		stamina += 0.1 * staminaRegenMod
	
	if currentBottle != null:
		$gui/milk.value = currentBottle.milk
		$gui/milk.show()
		$gui/KeyE.show()
		if Input.is_action_pressed("use"):
			if !$drink.playing:
				$drink.play()
			if !hasFunnel:
				currentBottle.milk -= 0.3
			else:
				currentBottle.milk -= 1.5
			stamina += 0.1
			if currentBottle.milk <= 0:
				bottleConsumed()
		else:
			$drink.stop()
	else:
		$gui/milk.hide()
		$gui/KeyE.hide()
		$drink.stop()
	
	if !pacified&&!$starveTimer.is_stopped():
		var time = $starveTimer.time_left+1
		$gui/timer.text = str(int(time/60))+":"+str("%02d" % (int(time)%60))
	else:
		$gui/timer.text = str(int(timeLeft/60))+":"+str("%02d" % (int(timeLeft)%60))
	
	if !get_node("/root/main/momLook").leaving:
		$lookRay.target_position = (get_node("/root/main/momLook").position-position)*2
		if $lookRay.is_colliding()&&$lookRay.get_collider().is_in_group("mom"):
			$lookRay.get_collider().leave()
	
	if currentItem != null:
		$gui/KeyE.show()

func handle_jumping():
	if jumping_enabled&&stamina>0&&!flying:
		if Input.is_action_pressed(JUMP) and is_on_floor() and !low_ceiling:
			resting = false
			$rest_timer.stop()
			$rest_timer.start()
			stamina -= 2
			if jump_animation:
				$"jump sfx".playing = true
				JUMP_ANIMATION.play("jump")
			velocity.y += jump_velocity * jumpSpeedMod

func handle_movement(delta, input_dir):
	var direction = input_dir.rotated(-HEAD.rotation.y)
	direction = Vector3(direction.x, 0, direction.y) * speedMod
	if slowed:
		direction *= 0.75
	if(!caught):
		move_and_slide()
	velocity.x = lerp(velocity.x, direction.x * speed, acceleration * delta)
	velocity.z = lerp(velocity.z, direction.z * speed, acceleration * delta)

func handle_fly(delta):
	var direction = ($Head/flyMarker.global_position-global_position)*20
	if(!caught):
		move_and_slide()
	var accel = acceleration * delta*0.1
	velocity.x = lerp(velocity.x, direction.x * speed, accel)
	velocity.y = lerp(velocity.y, direction.y * speed, accel)
	velocity.z = lerp(velocity.z, direction.z * speed, accel)

func handle_state(moving):
	if sprint_enabled:
		if Input.is_action_pressed("ui_shift") and state != "crouching":
			$rest_timer.stop()
			$rest_timer.start()
			if moving:
				if state != "sprinting"&&stamina>0:
					enter_sprint_state()
			else:
				if state == "sprinting":
					enter_normal_state()
		elif state == "sprinting":
			enter_normal_state()
	
	if crouch_enabled:
		if crouch_mode == 0:
			if Input.is_action_pressed("ui_c") and state != "sprinting":
				if state != "crouching":
					enter_crouch_state()
			elif state == "crouching":
				enter_normal_state()
		elif crouch_mode == 1:
			if Input.is_action_just_pressed("ui_c"):
				match state:
					"normal":
						enter_crouch_state()
					"crouching":
						if !$CrouchCeilingDetection.is_colliding():
							enter_normal_state()

func enter_normal_state():
	var prev_state = state
	if prev_state == "crouching":
		CROUCH_ANIMATION.play_backwards("crouch")
	state = "normal"
	speed = base_speed
	$rest_timer.start()

func enter_crouch_state():
	var prev_state = state
	state = "crouching"
	speed = crouch_speed
	CROUCH_ANIMATION.play("crouch")

func enter_sprint_state():
	var prev_state = state
	if prev_state == "crouching":
		CROUCH_ANIMATION.play_backwards("crouch")
	state = "sprinting"
	speed = sprint_speed
	resting = false


func update_camera_fov():
	var finalFov = 75.0
	if state == "sprinting":
		finalFov += 10.0
	if !$energyDrinkTimer.is_stopped():
		finalFov += 10.0
	if !$sugarCrash.is_stopped():
		finalFov -= 30.0
	CAMERA.fov = lerp(CAMERA.fov, finalFov, 0.3)

func headbob_animation(moving):
	if moving and is_on_floor():
		var was_playing : bool = false
		if HEADBOB_ANIMATION.current_animation == "headbob":
			was_playing = true
		HEADBOB_ANIMATION.play("headbob", 0.25)
		HEADBOB_ANIMATION.speed_scale = (current_speed / base_speed) * 1.75
		if !was_playing:
			HEADBOB_ANIMATION.seek(float(randi() % 2))

	else:
		HEADBOB_ANIMATION.play("RESET", 0.25)
		HEADBOB_ANIMATION.speed_scale = 1


func _process(delta):
	var status : String = state
	if !is_on_floor():
		status += " in the air"
	
	HEAD.rotation.x = clamp(HEAD.rotation.x, deg_to_rad(-90), deg_to_rad(90))

func _unhandled_input(event):
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and $slipTimer.is_stopped():# and $slipTimer.time_left <= 0:
		HEAD.rotation_degrees.y -= event.relative.x * mouse_sensitivity
		HEAD.rotation_degrees.x -= event.relative.y * mouse_sensitivity

func _on_laugh_timer_timeout():
	if !caught&&!pacified:
		$"detection sfx".stream = laugh[randi()%3]
		$"detection sfx".play()
		if !inSpawn:
			dad.heardNoise(position)
	$laugh_timer.wait_time = randf_range(15,30)
	$laugh_timer.start()

func _on_hitbox_body_entered(body):
	if body.is_in_group("bottle")&&body.visible:
		currentBottle = body

func _on_hitbox_body_exited(body):
	if body.is_in_group("bottle")&&body.visible:
		currentBottle = null

func _on_hitbox_area_entered(area):
	if area.is_in_group("enemy"):
		area.get_parent().get_parent().playerIn = true

func _on_hitbox_area_exited(area):
	if area.is_in_group("enemy"):
		area.get_parent().get_parent().playerIn = false

func _on_rest_timer_timeout():
	resting=true

func _on_spawn_body_entered(body):
	if body == self:
		inSpawn = true
		#$gui/debug.text = "True"

func _on_spawn_body_exited(body):
	if body == self:
		inSpawn = false
		#$gui/debug.text = "False"

func cry():
	$"cry sfx".play()

func bottleConsumed():
	currentBottle.disable()
	_on_laugh_timer_timeout()
	bottles+=1
	addTime(30)
	if hasFunnel:
		hasFunnel = false
	currentBottle = null
	$drink.stop()
	$gui/confetti.emitting = true
	$yay.play()
	if bottles>=bottleMax:
		main.changeGameSpeed(1)
		win()
	
	if bottles==1&&auto.day==3:
		main.spawnMom()
		await get_tree().create_timer(5).timeout
		$light.play()

func addTime(amt):
	if pacified:
		timeLeft += amt
		$gui/timer.text = str(int(timeLeft/60))+":"+str("%02d" % (int(timeLeft)%60))
		return
	var time = $starveTimer.time_left
	$starveTimer.stop()
	$starveTimer.wait_time = time+amt
	$starveTimer.start()

func win():
	get_parent().win()
	$gui/Win.show()
	$gui/confetti.emitting = true
	$yay.play()
	$win_timer.start()

func _on_win_timer_timeout():
	if $item.get_child_count()>0:
		var item = $item.get_child(0)
		$item.remove_child(item)
		auto.add_child(item)
	auto.nextDay()

func startStarving():
	$starveTimer.start()

func _on_starve_timer_timeout():
	$gui/lose.show()
	$"cry sfx".play()
	lost = true
	enter_normal_state()
	rotation.x = 90
	await get_tree().create_timer(5).timeout
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().change_scene_to_file("res://main_menu.tscn")

func slip():
	if gripped:
		return
	caught = true
	$Head/SlipAnimation.play("slip")
	$"slip sfx".play()
	cry()
	headbob_animation(false)
	$slipTimer.start()

func _on_slip_timer_timeout():
	caught = false
	$Head/SlipAnimation.play_backwards("slip")

func stopSlip():
	$slipTimer.stop()

func fly(amount):
	flying = true
	$fart.play()
	await get_tree().create_timer(amount).timeout
	flying = false

func eatSpoiledBurger():
	vomitReady = true
	stamina -= 20
	playBurp()
	
func playBurp():
	$burp.play()

func vomit():
	$Head/vomit.emitting = true
	await get_tree().create_timer(10).timeout
	$Head/vomit.emitting = false

func pacify():
	if pacified:
		$pacifierTimer.stop()
		$pacifierTimer.wait_time = 30
		$pacifierTimer.start()
		return
	pacified = true
	$pacifierTimer.start()
	$gui/pacifier.show()
	if auto.dayStarted:
		timeLeft = $starveTimer.time_left
	else:
		timeLeft = $starveTimer.wait_time
	$starveTimer.stop()

func _on_pacifier_timer_timeout():
	pacified = false
	$gui/pacifier.hide()
	$starveTimer.wait_time = timeLeft
	$starveTimer.start()
	$babySpit.play()

func placeLegos():
	var lego = legoTerrain.instantiate()
	main.add_child(lego)
	lego.position = position

func momJumpscare():
	if caught:
		return
	$gui/momJumpscare.play("jumpscare")
	await get_tree().create_timer(0.1).timeout
	teleport()

func drankEnergyDrink():
	if !$energyDrinkTimer.is_stopped():
		var timeleft = $energyDrinkTimer.time_left
		$energyDrinkTimer.stop()
		$energyDrinkTimer.wait_time += timeleft
		$energyDrinkTimer.start()
		return
	if !$sugarCrash.is_stopped():
		_on_sugar_crash_timeout()
	main.changeGameSpeed(2)
	staminaRegenMod += 1.0
	$energyDrinkTimer.start()
	$gui/shader.show()

func _on_energy_drink_timer_timeout():
	main.changeGameSpeed(0.5)
	staminaRegenMod -= 1.5
	$sugarCrash.start()
	$gui/shader.hide()
	$gui/grey.show()

func _on_sugar_crash_timeout():
	main.changeGameSpeed(1)
	staminaRegenMod += 0.5
	$gui/grey.hide()

func teleport():
	var locIndex = randi()%(roomLocs.get_child_count()-1)
	var locNode = roomLocs.get_child(locIndex)
	position = locNode.position + Vector3(0,0.2,0)
	$teleport.play()

func throwPebble():
	var pebble = Pebble.instantiate()
	main.add_child(pebble)
	$slingshot.play()
	pebble.velocity = ($Head/flyMarker.global_position-global_position)*20
	pebble.position = $Head/flyMarker.global_position
	numPebbles-=1

func spawnHotwheel():
	var hotwheel = Hotwheel.instantiate()
	hotwheel.position = position
	main.add_child(hotwheel)
	hotwheel.position = position
	hotwheel.dad = dad
