extends SubViewport

# Heart textures
@onready var full_heart_texture = preload("res://art/fullheart.png")
@onready var empty_heart_texture = preload("res://art/emptyheart.png")
@onready var heart_container = $HeartContainer

# Health tracking
var current_health = 5
var max_health = 10

func _ready():
	# Set up initial display
	size = Vector2i(500, 100)  # Width, height of viewport
	render_target_update_mode = SubViewport.UPDATE_ALWAYS
	
	# Set up the heart container to hold our hearts
	heart_container.size = size
	
	# Clear the sample hearts and create proper display
	clear_hearts()
	update_health_display(current_health, max_health)
	
	print("DEBUG: HealthViewport ready with size ", size)

# Update health display when health changes
func update_health(new_health: int, max_health_value: int = 10):
	current_health = new_health
	max_health = max_health_value
	update_health_display(current_health, max_health)

# Create heart display based on current/max health
func update_health_display(current_health: int, max_health: int):
	# Clear existing hearts first
	clear_hearts()
	
	# Create heart sprites for current health
	for i in range(max_health):
		var heart = TextureRect.new()
		heart.name = "Heart_" + str(i)
		
		# Set texture based on current health
		if i < current_health:
			heart.texture = full_heart_texture
		else:
			heart.texture = empty_heart_texture
			
		# Configure appearance
		heart.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		heart.custom_minimum_size = Vector2(40, 40)
		
		# Add to container
		heart_container.add_child(heart)
	
	print("DEBUG: Updated health display: ", current_health, "/", max_health)

# Clear all hearts from the container
func clear_hearts():
	# Remove any existing hearts (except the original samples)
	for child in heart_container.get_children():
		child.queue_free()
