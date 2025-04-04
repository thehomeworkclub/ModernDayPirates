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
	if GameManager.has_method("get") and GameManager.get("current_round") != null:
		label.text = "Round: " + str(GameManager.current_round)
	else:
		label.text = "Round: 1"
