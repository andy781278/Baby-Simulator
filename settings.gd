extends Control

func _ready():
	hide()

func _process(_delta):
	if Input.is_action_just_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			get_tree().paused = true
			show()
		elif Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			get_tree().paused = false
			hide()
			
	
	get_parent().volume = $vbox/volume/HSlider.value
	get_parent().sensitivity = $vbox/sense/HSlider.value
	$vbox/volume/value.text = str(get_parent().volume)
	$vbox/sense/value.text = "%.3f" % (get_parent().sensitivity/200)

func _on_return_pressed():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	get_tree().paused = false
	hide()

func _on_reset_pressed():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	get_tree().paused = false
	hide()
	get_tree().reload_current_scene()

func _on_stuck_pressed():
	get_parent().unstuckChild()
	_on_return_pressed()
