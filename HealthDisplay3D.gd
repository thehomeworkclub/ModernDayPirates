extends Node3D

# Load heart textures
var full_heart_texture = null
var empty_heart_texture = null

# Health settings
var max_health = 10
var current_health = 10
var heart_spacing = 0.15  # Space between hearts
var heart_scale = 0.1     # Size of each heart sprite

# References to heart sprites
var heart_sprites = []

func _ready():
	# Load textures
	full_heart_texture = load("res://art/fullheart.png")
	if full_heart_texture == null:
		push_error("Failed to load fullheart.png")
		return
		
	empty_heart_texture = load("res://art/emptyheart.png")
	if empty_heart_texture == null:
		push_error("Failed to load emptyheart.png")
		return
	
	# Create heart container
	call_deferred("create_hearts")
	
	# Create a timer for damage cooldown
	var timer = Timer.new()
	timer.name = "DamageTimer"
	timer.wait_time = 0.5
	timer.one_shot = true
	add_child(timer)

func _process(delta):
	# Check for damage input (key 9)
	if Input.is_key_pressed(KEY_9):
		# Add a small delay to prevent multiple hits in one press
		if has_node("DamageTimer") and !$DamageTimer.is_stopped():
			return
			
		take_damage(1)
		if has_node("DamageTimer"):
			$DamageTimer.start()

func create_hearts():
	# Safety check
	if full_heart_texture == null or empty_heart_texture == null:
		push_error("Cannot create hearts: textures not loaded")
		return
		
	# Remove any existing hearts
	for heart in heart_sprites:
		if is_instance_valid(heart):
			heart.queue_free()
	
	heart_sprites = []
	
	# Create 10 hearts in a row
	for i in range(max_health):
		var heart = Sprite3D.new()
		heart.texture = full_heart_texture
		heart.pixel_size = 0.005  # Increase for better visibility
		heart.scale = Vector3(heart_scale, heart_scale, heart_scale)
		
		# Position hearts side by side with a bit more spacing
		# Start from negative position so hearts are centered
		heart.transform.origin.x = (i - max_health/2.0) * heart_spacing
		
		# Make sure hearts are visible and well-lit
		heart.shaded = false
		heart.billboard = BaseMaterial3D.BILLBOARD_ENABLED  # Always face camera
		heart.double_sided = true
		heart.no_depth_test = true
		heart.fixed_size = true
		
		add_child(heart)
		heart_sprites.append(heart)
	
	call_deferred("update_hearts")

func take_damage(amount):
	current_health = max(0, current_health - amount)
	update_hearts()
	print("Player took damage! Health: " + str(current_health) + "/" + str(max_health))

func heal(amount):
	current_health = min(max_health, current_health + amount)
	update_hearts()
	print("Player healed! Health: " + str(current_health) + "/" + str(max_health))

func update_hearts():
	# Safety check
	if full_heart_texture == null or empty_heart_texture == null:
		return
		
	# Update the heart textures based on current health
	for i in range(heart_sprites.size()):
		if is_instance_valid(heart_sprites[i]):
			if i < current_health:
				heart_sprites[i].texture = full_heart_texture
			else:
				heart_sprites[i].texture = empty_heart_texture
