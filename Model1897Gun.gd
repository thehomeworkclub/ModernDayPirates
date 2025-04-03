extends "res://BaseRifleGun.gd"

# Animation reference
@onready var animation_player = $AnimationPlayer

# Shotgun specific properties
var pellets_per_shot: int = 8
var spread_angle: float = 12.0 # degrees
var pump_action_time: float = 0.7
var is_pumping: bool = false
var pump_timer: Timer

func _ready() -> void:
	# Set Model 1897 specific properties
	gun_type = "model1897"
	fire_rate = 1.0  # Slow fire rate for pump action
	bullet_damage = 2  # Damage per pellet
	magazine_size = 2  # Small magazine - just 2 shells
	reload_time = 0.8  # Quick individual reload
	accuracy = 0.7  # Low accuracy due to shotgun spread
	recoil = 0.9   # High recoil for shotgun
	automatic = false  # Manual pump action
	
	# Create pump action timer
	pump_timer = Timer.new()
	pump_timer.one_shot = true
	add_child(pump_timer)
	pump_timer.timeout.connect(_on_pump_timer_timeout)
	
	# Call parent _ready after setting properties
	super._ready()
	
	print_verbose("Model 1897 shotgun initialized")

# Override shoot method completely to implement shotgun mechanics
func shoot() -> void:
	# Don't shoot if pumping or reloading
	if is_pumping or is_reloading:
		return
		
	# Stop shooting if empty
	if current_ammo <= 0:
		# Click sound would play here
		print("Out of ammo!")
		return
		
	# Play recoil animation
	if animation_player != null and animation_player.has_animation("recoil"):
		animation_player.stop()
		animation_player.play("recoil")
	
	# Prevent rapid firing
	can_shoot = false
	
	# Decrease ammo
	current_ammo -= 1
	
	# Spawn multiple pellets in a cone
	spawn_pellets()
	
	# Show muzzle flash
	show_muzzle_flash()
	
	# Apply strong recoil effect
	apply_recoil()
	
	# Provide strong haptic feedback on both controllers
	if right_controller:
		right_controller.trigger_haptic_pulse("haptic", 1.0, 0.4, 1.0, 0.0)
	if left_controller:
		left_controller.trigger_haptic_pulse("haptic", 0.9, 0.3, 1.0, 0.0)
	
	if debug_enabled:
		print("Shotgun ammo remaining: " + str(current_ammo))
	
	# Start pump action
	is_pumping = true
	pump_timer.wait_time = pump_action_time
	pump_timer.start()
	
	# Detach magazine automatically if empty (to simulate ejecting shell)
	if current_ammo <= 0:
		detach_magazine()

func spawn_pellets() -> void:
	if not bullet_scene:
		print("ERROR: No bullet scene assigned")
		return
		
	# Find muzzle position
	var muzzle = $Muzzle
	if not muzzle:
		print("ERROR: Muzzle node not found")
		return
		
	# Calculate base shooting direction
	var base_direction = -global_transform.basis.z.normalized()
	
	# Spawn multiple pellets in a cone pattern
	for i in range(pellets_per_shot):
		# Calculate random spread within the cone
		var spread_rad = deg_to_rad(spread_angle)
		var random_spread = Vector3(
			randf_range(-spread_rad, spread_rad),
			randf_range(-spread_rad, spread_rad),
			0
		)
		
		# Apply spread and normalize
		var direction = base_direction.rotated(Vector3.RIGHT, random_spread.x)
		direction = direction.rotated(Vector3.UP, random_spread.y)
		direction = direction.normalized()
		
		# Create bullet instance
		var bullet = bullet_scene.instantiate()
		
		# Set bullet properties
		bullet.direction = direction
		bullet.damage = bullet_damage
		
		# Reduce pellet lifetime for visual effect
		if bullet.has_method("set_lifetime"):
			bullet.set_lifetime(0.5)
		
		# Add bullet to scene
		get_tree().current_scene.add_child(bullet)
		
		# Position bullet at muzzle with slight random offset
		var random_offset = Vector3(
			randf_range(-0.02, 0.02),
			randf_range(-0.02, 0.02),
			0
		)
		bullet.global_position = muzzle.global_position + random_offset

func _on_pump_timer_timeout() -> void:
	is_pumping = false
	can_shoot = true
	
	# Play pump action sound/animation here
	
	print_verbose("Pump action complete")

# Shotguns reload one shell at a time
func reload() -> void:
	if is_reloading or is_pumping or current_ammo == magazine_size:
		return
		
	print("Reloading shotgun...")
	is_reloading = true
	
	# Play reload animation/sound here
	
	reload_timer.wait_time = reload_time
	reload_timer.start()

func _on_reload_timer_timeout() -> void:
	# Add just one shell at a time
	current_ammo += 1
	is_reloading = false
	
	print("Loaded one shell. Ammo: " + str(current_ammo))
	
	# If we're still not full, prompt for another reload
	if current_ammo < magazine_size:
		print("Ready for next shell...")
	
# Override detach_magazine to represent removing a shell
func detach_magazine() -> void:
	if not magazine_node or magazine_state == MagazineState.DETACHED:
		return
		
	if debug_enabled:
		print("Ejecting shotgun shell. Current ammo: " + str(current_ammo))
	
	# Set cooldown to prevent immediate reattachment
	detachment_cooldown = 0.5
	
	# Clean up any existing hand magazine
	var existing_hand_mag = left_controller.get_node_or_null("HandMagazine")
	if existing_hand_mag:
		existing_hand_mag.queue_free()
	
	# Change state
	magazine_state = MagazineState.DETACHED
	
	# Create a new magazine on the left controller
	var hand_magazine = Node3D.new()
	hand_magazine.name = "HandMagazine"
	left_controller.add_child(hand_magazine)
	
	# Position it
	hand_magazine.transform.origin = hand_magazine_position
	
	# Create a basic magazine model
	create_hand_magazine_model(hand_magazine)
	
	# Hide magazine on gun
	hide_gun_magazine(true)
	
	# Trigger haptic feedback
	if left_controller:
		left_controller.trigger_haptic_pulse("haptic", 0.5, 0.1, 1.0, 0.0)
