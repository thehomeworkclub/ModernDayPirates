extends Control

# Dictionary defining voyage data with difficulty parameters
var voyage_data = {
	1: {
		"name": "Calm Waters",
		"difficulty": "Easy",
		"enemy_spawn_rate": 4.0, # seconds
		"enemy_speed": 1.0,
		"enemy_health": 1.0
	},
	2: {
		"name": "Rough Seas",
		"difficulty": "Normal",
		"enemy_spawn_rate": 3.0,
		"enemy_speed": 1.2,
		"enemy_health": 1.5
	},
	3: {
		"name": "Storm Warning",
		"difficulty": "Hard",
		"enemy_spawn_rate": 2.0,
		"enemy_speed": 1.5,
		"enemy_health": 2.0
	},
	4: {
		"name": "Hurricane",
		"difficulty": "Very Hard",
		"enemy_spawn_rate": 1.5,
		"enemy_speed": 1.8,
		"enemy_health": 2.5
	},
	5: {
		"name": "Maelstrom",
		"difficulty": "Extreme",
		"enemy_spawn_rate": 1.0,
		"enemy_speed": 2.0,
		"enemy_health": 3.0
	}
}

func _ready() -> void:
	# Release the mouse for menu interaction
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# Update voyage information displays
	update_voyage_displays()
	
	# Connect button signals
	for i in range(1, 6):
		var button = get_node("Panel/VBoxContainer/Voyage" + str(i))
		button.pressed.connect(_on_voyage_selected.bind(i))
	
	# Connect shop button if it exists
	if has_node("Panel/ShopButton"):
		$Panel/ShopButton.pressed.connect(_on_shop_button_pressed)

func update_voyage_displays() -> void:
	# Update each voyage button with difficulty and round info
	for i in range(1, 6):
		var button = get_node("Panel/VBoxContainer/Voyage" + str(i))
		var label = button.get_node("Label") if button.has_node("Label") else null
		
		if label:
			var data = voyage_data[i]
			var rounds = 1
			
			# Determine rounds based on difficulty
			match data["difficulty"]:
				"Easy", "Normal": rounds = 1
				"Hard", "Very Hard": rounds = 2
				"Extreme": rounds = 3
			
			# Update the label text
			label.text = data["name"] + "\nDifficulty: " + data["difficulty"] + "\nRounds: " + str(rounds)

func _on_shop_button_pressed() -> void:
	# Show permanent upgrades shop
	var shop_scene = load("res://PermanentShopMenu.tscn")
	if shop_scene:
		var shop_instance = shop_scene.instantiate()
		add_child(shop_instance)
	else:
		print("ERROR: PermanentShopMenu.tscn not found")

func _on_voyage_selected(voyage_number: int) -> void:
	# Set voyage data in GameManager
	var data = voyage_data[voyage_number]
	GameManager.set_voyage(voyage_number, data["difficulty"])
	GameManager.enemy_spawn_rate = data["enemy_spawn_rate"]
	GameManager.enemy_speed = data["enemy_speed"]
	GameManager.enemy_health = data["enemy_health"]
	
	# Start the game
	GameManager.start_campaign()
	get_tree().change_scene_to_file("res://Main.tscn")