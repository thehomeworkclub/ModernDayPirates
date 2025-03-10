extends Node3D

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
	
	# Connect the clickable area's signal
	$MapDisplay/ClickableArea.input_event.connect(_on_area_input_event)

func _on_area_input_event(_camera, event, _position, _normal, _shape_idx) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		# Start a default voyage (1 for simplicity)
		_on_voyage_selected(1)

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