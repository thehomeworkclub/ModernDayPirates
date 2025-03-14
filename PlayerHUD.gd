extends CanvasLayer

# Heart icons array
var hearts = []

# Textures
@onready var full_heart_texture = preload("res://art/fullheart.png")
@onready var empty_heart_texture = preload("res://art/emptyheart.png")

# Reference to container in scene
@onready var container = $Control/MarginContainer/HeartContainer

func _ready():
	# Make sure nodes are initialized
	await get_tree().process_frame
	
	# Ensure our container reference is valid
	if !container:
		print("ERROR: Heart container not found, creating manually")
		_create_container_structure()
	
	print("DEBUG: HUD ready, waiting for player health update")
	
	# Show test hearts
	update_hearts(5, 10)

# Create UI structure if scene fails to load properly
func _create_container_structure():
	# Root control
	var control = Control.new()
	control.name = "Control"
	control.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(control)
	
	# Margin container
	var margin = MarginContainer.new()
	margin.name = "MarginContainer"
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_top", 20)
	control.add_child(margin)
	
	# Heart container
	container = HBoxContainer.new()
	container.name = "HeartContainer"
	container.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	container.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	container.add_theme_constant_override("separation", 10)
	margin.add_child(container)
	
	print("DEBUG: Created UI container structure manually")

func update_hearts(current_health: int, max_health: int):
	print("DEBUG: HUD updating hearts: " + str(current_health) + "/" + str(max_health))
	
	# Safety check
	if !container:
		print("ERROR: Heart container still null, cannot update hearts")
		return
	
	# Clear existing hearts
	for heart in hearts:
		if is_instance_valid(heart):
			heart.queue_free()
	hearts.clear()
	
	# Add new hearts
	for i in range(max_health):
		var heart = TextureRect.new()
		heart.name = "Heart_" + str(i)
		heart.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		heart.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		heart.custom_minimum_size = Vector2(32, 32)
		
		# Set texture based on health
		if i < current_health:
			heart.texture = full_heart_texture
		else:
			heart.texture = empty_heart_texture
			
		# Add to container
		container.add_child(heart)
		hearts.append(heart)
	
	print("DEBUG: HUD created " + str(hearts.size()) + " hearts")

# Called by player when health changes
func on_player_health_changed(current_health: int, max_health: int):
	print("DEBUG: HUD received health change: " + str(current_health) + "/" + str(max_health))
	update_hearts(current_health, max_health)
