extends CanvasLayer

# Health settings
var max_health = 10
var current_health = 10

# Heart textures
var full_heart_texture = preload("res://art/fullheart.png")
var empty_heart_texture = preload("res://art/emptyheart.png")

# References to individual heart sprites
var heart_sprites = []

func _ready():
	# Collect references to all heart sprites
	for i in range(1, max_health + 1):
		var heart = get_node("Container/Heart" + str(i))
		if heart:
			heart_sprites.append(heart)
	
	# Initialize hearts display
	update_hearts()
	
	# Set up the damage timer
	$DamageTimer.wait_time = 0.3
	$DamageTimer.one_shot = true

func _process(_delta):
	# Check for damage input (key 9)
	if Input.is_key_pressed(KEY_9):
		# Add a small delay to prevent multiple hits in one press
		if $DamageTimer.is_stopped():
			take_damage(1)
			$DamageTimer.start()

func take_damage(amount):
	current_health = max(0, current_health - amount)
	update_hearts()
	print("Player took damage! Health: " + str(current_health) + "/" + str(max_health))
	
	# Check for death
	if current_health <= 0:
		print("Player died!")
		# For testing, reset health after death
		await get_tree().create_timer(1.0).timeout
		heal(max_health)

func heal(amount):
	current_health = min(max_health, current_health + amount)
	update_hearts()
	print("Player healed! Health: " + str(current_health) + "/" + str(max_health))

func update_hearts():
	# Update heart textures based on current health
	for i in range(heart_sprites.size()):
		if i < current_health:
			heart_sprites[i].texture = full_heart_texture
		else:
			heart_sprites[i].texture = empty_heart_texture
