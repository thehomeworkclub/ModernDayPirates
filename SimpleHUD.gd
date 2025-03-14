extends CanvasLayer

var hearts = []
var heart_container = null

# Heart textures
var full_heart = preload("res://art/fullheart.png")
var empty_heart = preload("res://art/emptyheart.png")

func _ready():
	# Create container with a flat structure
	heart_container = HBoxContainer.new()
	heart_container.name = "HeartContainer"
	heart_container.position = Vector2(20, 20) # Top-left position
	heart_container.add_theme_constant_override("separation", 10)
	add_child(heart_container)
	
	print("DEBUG: Simple HUD created")
	
	# Display test hearts
	display_health(5, 10)

# Display health with the specified number of hearts
func display_health(current_health: int, max_health: int):
	print("DEBUG: Updating health display: ", current_health, "/", max_health)
	
	# Clear any existing hearts
	for heart in hearts:
		if is_instance_valid(heart):
			heart.queue_free()
	hearts.clear()
	
	# Create new heart icons
	for i in range(max_health):
		var texture_rect = TextureRect.new()
		texture_rect.name = "Heart_" + str(i)
		
		# Apply correct texture based on health
		texture_rect.texture = full_heart if i < current_health else empty_heart
		
		# Configure size and appearance
		texture_rect.custom_minimum_size = Vector2(40, 40)
		texture_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		
		# Add to container
		heart_container.add_child(texture_rect)
		hearts.append(texture_rect)
	
	print("DEBUG: Created ", hearts.size(), " heart icons")

# Called by Player when health changes
func on_player_health_changed(current_health: int, max_health: int):
	print("DEBUG: Health changed to ", current_health, "/", max_health)
	display_health(current_health, max_health)
