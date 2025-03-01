extends Control

func _ready() -> void:
	# Release mouse for UI
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# Update statistics
	update_stats()
	
	# Connect buttons
	$Panel/VBoxContainer/ContinueButton.pressed.connect(_on_continue_pressed)
	$Panel/VBoxContainer/MenuButton.pressed.connect(_on_menu_pressed)

func update_stats() -> void:
	# Update round info
	$Panel/VBoxContainer/Stats.text = "Round: %d of %d\nEnemies Defeated: %d" % [
		GameManager.current_round,
		GameManager.total_rounds,
		GameManager.enemies_per_wave * GameManager.waves_per_round  # Approximate count
	]
	
	# Show rewards (these would come from the GameManager)
	var silver_reward = 30 + (10 * GameManager.current_round)
	var gold_reward = 5 + (2 * GameManager.current_round)
	
	$Panel/VBoxContainer/Rewards.text = "Silver: +%d\nGold: +%d" % [
		silver_reward,
		gold_reward
	]
	
	# Actually award the rewards
	CurrencyManager.add_silver(silver_reward)
	CurrencyManager.add_gold(gold_reward)

func _on_continue_pressed() -> void:
	# Continue to next round
	queue_free()
	get_tree().paused = false
	GameManager.continue_to_next_round()

func _on_menu_pressed() -> void:
	# Return to campaign menu
	queue_free()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://CampaignMenu.tscn")