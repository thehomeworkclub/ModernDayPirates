extends Node3D

# Label for displaying round information
var label: Label3D

func _ready() -> void:
	# Create and configure the 3D label
	label = Label3D.new()
	label.font_size = 24
	label.modulate = Color(0.9, 0.2, 0.2)  # Red color
	label.outline_modulate = Color(0, 0, 0)
	label.outline_size = 3
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = Vector3(0, 0, 0)
	label.pixel_size = 0.01
	add_child(label)
	
	# Update the display immediately
	update_display()

func _process(_delta: float) -> void:
	# Update the label text with the current round
	update_display()
	
func update_display() -> void:
	if GameManager.has_method("get"):
		var round_text = "Round: " + str(GameManager.current_round)
		
		# Add wave information if available
		if GameManager.get("current_wave") != null and GameManager.get("game_parameters") != null:
			var total_waves = GameManager.game_parameters.waves_per_round
			var current_wave = GameManager.waves_completed_in_round + 1
			if current_wave > total_waves:
				current_wave = total_waves
			round_text += "\nWave: " + str(current_wave) + "/" + str(total_waves)
		
		label.text = round_text
	else:
		label.text = "Round: 1\nWave: 1/5"
