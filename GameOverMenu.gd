extends Control

func _ready() -> void:
	# Release mouse for UI interaction
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# Update stats
	$Panel/VBoxContainer/Stats.text = "Voyage: %d - %s\nDifficulty: %s\nCompleted Waves: %d" % [
		GameManager.current_voyage,
		GameManager.voyage_name,
		GameManager.difficulty,
		(GameManager.current_round - 1) * GameManager.waves_per_round + (GameManager.current_wave - 1)
	]
	
	# Connect buttons
	$Panel/VBoxContainer/RestartButton.pressed.connect(_on_restart_pressed)
	$Panel/VBoxContainer/MenuButton.pressed.connect(_on_menu_pressed)

func _on_restart_pressed() -> void:
	# Restart the same voyage
	get_tree().paused = false
	GameManager.start_campaign()
	get_tree().change_scene_to_file("res://Main.tscn")
	queue_free()

func _on_menu_pressed() -> void:
	# Return to campaign menu
	get_tree().paused = false
	get_tree().change_scene_to_file("res://CampaignMenu.tscn")
	queue_free()