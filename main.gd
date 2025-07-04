extends Node3D

var winSound = preload("res://sfx/win.mp3")
var bgms = [preload("res://music/day1.mp3"),preload("res://music/day2.mp3"),\
preload("res://music/day3.mp3")]
var lastbgm = preload("res://music/bowelMovement.mp3")

var neighbor = preload("res://neighbor.tscn")
var mom = preload("res://mom.tscn")

var normalMode = preload("res://default.tres")
var darkMode = preload("res://dark.tres")

var items = [preload("res://items/laxative/laxative.tscn"),\
preload("res://items/chocolate/chocolate.tscn"),\
preload("res://items/spoiledBurger/spoiledBurger.tscn"),\
preload("res://items/pacifier/pacifier.tscn"),\
preload("res://items/legoBricks/legoBricks.tscn"),\
preload("res://items/grippySocks/grippySocks.tscn"),\
preload("res://items/chorusFruit/chorusDruit.tscn"),\
preload("res://items/energyDrink/energyDrink.tscn"),\
preload("res://items/hotWheels/hotWheels.tscn"),\
preload("res://items/pogoStick/pogoStick.tscn"),\
preload("res://items/slingShot/slingShot.tscn"),\
preload("res://items/funnel/funnel.tscn")
]

var day3Blur = preload("res://day3.tres")

@onready var BABY = $baby

var bottlecount = [3,5,7]
var bottleSpawn = [6,7,8]
var itemSpawn = [10,15,20]

var volume = 50
var sensitivity = 50

func _ready():
	#var pitch_shift = AudioServer.get_bus_effect(0,0)
	#pitch_shift.pitch_scale = 0.5
	#spawnBottles(20)
	#spawnItems(31)
	spawnBottles(bottleSpawn[auto.day-1])
	spawnItems(itemSpawn[auto.day-1])
	$baby.bottleMax = bottlecount[auto.day-1]
	if auto.day >= 2:
		var Neighbor = neighbor.instantiate()
		add_child(Neighbor)
		Neighbor.position = Vector3(-1,-8,13)

func _process(_delta):
	if Input.is_action_just_pressed("ui_left_click"):
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), volume-50)
	BABY.mouse_sensitivity = sensitivity/200

func spawnBottles(amt):
	var i = 0
	while i < amt:
		var bottle = $bottlespawns.get_child(randi()%$bottlespawns.get_child_count())
		if !bottle.visible:
			bottle.enable()
			i+=1

func spawnItems(amt):
	spawnItem(randi()%items.size(),$spawnItemLoc.position)
	#spawnItem(8,$spawnItemLoc.position)
	var itemSlots = [] #is slot filled
	itemSlots.resize(31)
	for j in range(31):
		itemSlots[j] = false
	var i = 0
	while i < amt:
		var randItemIndex = randi()%items.size()
		var randPosIndex = randi()%31
		if itemSlots[randPosIndex]:
			continue
		itemSlots[randPosIndex] = true
		spawnItem(randItemIndex,$itemLocs.get_child(randPosIndex).position)
		i+=1

func spawnItem(itemId,pos):
	var Item = items[itemId].instantiate()
	add_child(Item)
	Item.position = pos

func win():
	$bgm.stop()
	$bgm.stream = winSound
	$bgm.play()

func playMusic():
	$bgm.stream = bgms[auto.day-1]
	$bgm.play()

func spawnMom():
	auto.momOut = true
	$bgm.stop()
	await get_tree().create_timer(5).timeout
	$WorldEnvironment.environment = darkMode
	await get_tree().create_timer(0.1).timeout
	$WorldEnvironment.environment = normalMode
	await get_tree().create_timer(0.04).timeout
	$WorldEnvironment.environment = darkMode
	await get_tree().create_timer(0.14).timeout
	$WorldEnvironment.environment = normalMode
	await get_tree().create_timer(0.05).timeout
	$WorldEnvironment.environment = darkMode
	await get_tree().create_timer(0.1).timeout
	$WorldEnvironment.environment = normalMode
	await get_tree().create_timer(0.04).timeout
	$WorldEnvironment.environment = darkMode
	await get_tree().create_timer(0.1).timeout
	$WorldEnvironment.environment = normalMode
	await get_tree().create_timer(0.07).timeout
	$WorldEnvironment.environment = darkMode
	await get_tree().create_timer(0.08).timeout
	$WorldEnvironment.environment = normalMode
	await get_tree().create_timer(0.05).timeout
	$WorldEnvironment.environment = darkMode
	$WorldEnvironment.camera_attributes = day3Blur
	var Mom = mom.instantiate()
	add_child(Mom)
	Mom.position = Vector3(-1,-8,13)
	$mom/door.play()
	$bgm.stream = lastbgm
	$bgm.play()
	
func unstuckChild():
	if !BABY.caught:
		BABY.position = Vector3(0,1.5,-2)

func changeGameSpeed(spd):
	Engine.time_scale = spd
	for audio_player in get_tree().get_nodes_in_group("audio_players"):
		audio_player.pitch_scale = spd
