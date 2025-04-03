extends CanvasLayer

# Preload heart textures
var full_heart_texture = null
var empty_heart_texture = null

# Health settings
var max_health = 10
var current_health = 10
var heart_spacing = 40  # Space between hearts in pixels
var heart_size = Vector2(32, 32)  # Size of each heart sprite

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
		
	# Create hearts
	call_deferred("create_hearts")
	
	# Add input handling for the 9 key
	set_process_input(true)
	set_process(true)

func _input(event):
	# Check for damage input (key 9)
	if event is InputEventKey and event.keycode == KEY_9 and event.pressed and not event.echo:
		take_damage(1)
		print("Damage taken! Health: " + str(current_health) + "/" + str(max_health))

func _process(delta):
	# Alternative method for checking key press
	if Input.is_key_pressed(KEY_9):
		# We need to throttle this to avoid multiple hits
		if not $DamageTimer.is_stopped():
			return
			
		take_damage(1)
		$DamageTimer.start()

func create_hearts():
	# Safety check
	if full_heart_texture == null or empty_heart_texture == null:
		push_error("Cannot create hearts: textures not loaded")
		return
		
	# Create a timer for damage cooldown
	var timer = Timer.new()
	timer.name = "DamageTimer"
	timer.wait_time = 0.3
	timer.one_shot = true
	add_child(timer)
	
	# Create heart container
	var container = Control.new()
	container.name = "HeartContainer"
	container.set_anchors_preset(Control.PRESET_TOP_LEFT)
	container.position = Vector2(20, 20)  # Adjust position as needed
	add_child(container)
	
	# Create heart sprites
	for i in range(max_health):
		var heart = TextureRect.new()
		heart.texture = full_heart_texture
		heart.expand_mode = TextureRect.EXPAND_KEEP_SIZE
		heart.custom_minimum_size = heart_size
		heart.size = heart_size
		heart.position.x = i * heart_spacing
		
		container.add_child(heart)
		heart_sprites.append(heart)
	
	update_hearts()

func take_damage(amount):
	current_health = max(0, current_health - amount)
	update_hearts()

func heal(amount):
	current_health = min(max_health, current_health + amount)
	update_hearts()

func update_hearts():
	# Update heart textures based on current health
	for i in range(heart_sprites.size()):
		if i < current_health:
			heart_sprites[i].texture = full_heart_texture
		else:
			heart_sprites[i].texture = empty_heart_texture
