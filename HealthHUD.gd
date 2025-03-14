extends Control

var hearts = []
var container

# Preload textures
var full_heart_texture = preload("res://art/fullheart.png")
var empty_heart_texture = preload("res://art/emptyheart.png")

func _ready():
	# Get reference to the container
	container = $HBoxContainer
	
	# Make sure we found the container
	if !container:
		print("ERROR: HBoxContainer not found!")
		return
	
	# Remove test heart
	var test_heart = container.get_node_or_null("TestHeart")
	if test_heart:
		test_heart.queue_free()
	
	print("DEBUG: HealthHUD initialized")
	
	# Show test hearts to confirm visibility
	update_health(5, 10)

# Update the health display
func update_health(current_health: int, max_health: int):
	print("DEBUG: HealthHUD updating: ", current_health, "/", max_health)
	
	# Safety check
	if !container:
		print("ERROR: Container not found!")
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
		
		# Set texture based on health
		if i < current_health:
			heart.texture = full_heart_texture
		else:
			heart.texture = empty_heart_texture
		
		# Configure appearance
		heart.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		heart.custom_minimum_size = Vector2(40, 40)
		
		# Add to container
		container.add_child(heart)
		hearts.append(heart)
	
	print("DEBUG: Created ", hearts.size(), " heart icons")

# Called by Player when health changes
func on_player_health_changed(current_health: int, max_health: int):
	print("DEBUG: Health changed to ", current_health, "/", max_health)
	update_health(current_health, max_health)
