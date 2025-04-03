extends "res://Gun.gd"

# Rifle-specific properties
@export_range(1, 30) var magazine_size: int = 30
@export var reload_time: float = 2.0
@export_range(0.0, 1.0) var accuracy: float = 0.9  # 1.0 = perfect accuracy
@export_range(0.0, 1.0) var recoil: float = 0.2    # Recoil intensity
@export var automatic: bool = false                # Whether the gun can fire continuously

# Internal state
var current_ammo: int
var is_reloading: bool = false
var reload_timer: Timer

# Controller references
var right_controller: XRController3D = null
var left_controller: XRController3D = null

# Muzzle flash reference
var muzzle_flash_scene = preload("res://MuzzleFlash.tscn")
var muzzle_flash_instance = null
var muzzle_flash_timer: Timer

func _process(delta: float) -> void:
	if automatic and Input.is_action_pressed("shoot") and can_shoot and current_ammo > 0 and not is_reloading:
		shoot()
	elif Input.is_action_just_pressed("shoot") and can_shoot and current_ammo > 0 and not is_reloading:
		shoot()
	
	if Input.is_action_just_pressed("reload") and not is_reloading and current_ammo < magazine_size:
		reload()

func _ready() -> void:
	super._ready()
	
	# Set initial ammo
	current_ammo = magazine_size
	
	# Create reload timer
	reload_timer = Timer.new()
	reload_timer.one_shot = true
	add_child(reload_timer)
	reload_timer.timeout.connect(_on_reload_timer_timeout)
	
	# Create muzzle flash timer
	muzzle_flash_timer = Timer.new()
	muzzle_flash_timer.wait_time = 0.1  # Short duration for muzzle flash
	muzzle_flash_timer.one_shot = true
	add_child(muzzle_flash_timer)
	muzzle_flash_timer.timeout.connect(_on_muzzle_flash_timeout)
	
	# Get controller references
	var vr_origin = get_parent().get_parent() # Gun → VRGunController → XROrigin3D
	if vr_origin:
		right_controller = vr_origin.get_node_or_null("XRController3DRight")
		left_controller = vr_origin.get_node_or_null("XRController3DLeft")
	
	print_verbose("Rifle gun initialized: " + str(gun_type))

# Override the shoot method completely - DON'T call super.shoot()
func shoot() -> void:
	# Stop shooting if empty or reloading
	if current_ammo <= 0:
		# Click sound would play here
		print_verbose("Out of ammo!")
		reload()
		return
		
	if is_reloading:
		return
	
	# Prevent rapid firing
	can_shoot = false
	
	# Decrease ammo
	current_ammo -= 1
	
	# Apply very minimal random spread based on accuracy for rifles
	var spread = (1.0 - accuracy) * 0.05  # Tiny spread for rifles
	var random_spread = Vector3(
		randf_range(-spread, spread),
		randf_range(-spread, spread),
		0
	)
	
	# Spawn exactly ONE bullet
	spawn_bullet(random_spread)
	
	# Show muzzle flash
	show_muzzle_flash()
	
	# Apply recoil effect
	apply_recoil()
	
	# Provide haptic feedback on both controllers
	apply_haptic_feedback()
	
	print_verbose("Rifle ammo remaining: " + str(current_ammo))
	
	# Start cooldown timer
	shoot_timer.wait_time = fire_rate
	shoot_timer.start()
	
	# Auto-reload when empty
	if current_ammo <= 0:
		reload()

func spawn_bullet(spread_offset: Vector3) -> void:
	if not bullet_scene:
		print_verbose("ERROR: No bullet scene assigned")
		return
		
	# Find muzzle position
	var muzzle = $Muzzle
	if not muzzle:
		print_verbose("ERROR: Muzzle node not found")
		return
		
	# Calculate shooting direction with spread
	var direction = -global_transform.basis.z.normalized()
	direction += spread_offset
	direction = direction.normalized()
	
	# Create a single bullet instance
	var bullet = bullet_scene.instantiate()
	
	# Set bullet properties
	bullet.direction = direction
	bullet.damage = bullet_damage
	
	# Add bullet to scene
	get_tree().current_scene.add_child(bullet)
	
	# Position bullet at muzzle
	bullet.global_position = muzzle.global_position
	
	print_verbose("Spawned single rifle bullet with damage: " + str(bullet_damage))

func show_muzzle_flash() -> void:
	# If a muzzle flash is already active, remove it
	if muzzle_flash_instance:
		muzzle_flash_instance.queue_free()
		muzzle_flash_instance = null
	
	# Create a new muzzle flash
	muzzle_flash_instance = muzzle_flash_scene.instantiate()
	
	# Get muzzle node
	var muzzle = $Muzzle
	if not muzzle:
		print_verbose("ERROR: Muzzle node not found")
		return
		
	# Add muzzle flash to muzzle
	muzzle.add_child(muzzle_flash_instance)
	
	# Start particle emission
	var particles = muzzle_flash_instance.get_node("FireParticles")
	if particles:
		particles.emitting = true
	
	# Start timer to remove muzzle flash
	muzzle_flash_timer.start()

func _on_muzzle_flash_timeout() -> void:
	if muzzle_flash_instance:
		muzzle_flash_instance.queue_free()
		muzzle_flash_instance = null

func reload() -> void:
	if is_reloading or current_ammo == magazine_size:
		return
		
	print_verbose("Reloading rifle...")
	is_reloading = true
	
	# Play reload animation/sound here
	
	reload_timer.wait_time = reload_time
	reload_timer.start()

func _on_reload_timer_timeout() -> void:
	current_ammo = magazine_size
	is_reloading = false
	print_verbose("Reload complete. Ammo: " + str(current_ammo))

func apply_recoil() -> void:
	# This would normally apply a recoil effect to the camera or gun model
	# For now, we'll just print a debug message
	if recoil > 0:
		print_verbose("Applied recoil: " + str(recoil))

func apply_haptic_feedback() -> void:
	# Apply haptic feedback to both controllers based on the gun's recoil
	var intensity = 0.5 + recoil * 0.5 # Scale intensity based on recoil (0.5-1.0)
	var duration = 0.1 + recoil * 0.2  # Scale duration based on recoil (0.1-0.3s)
	
	# Apply to right controller (stronger feedback)
	if right_controller:
		right_controller.trigger_haptic_pulse("haptic", intensity, duration, 1.0, 0.0)
	
	# Apply to left controller (weaker feedback to simulate supporting hand)
	if left_controller:
		left_controller.trigger_haptic_pulse("haptic", intensity * 0.6, duration * 0.8, 0.8, 0.0)
		
	print_verbose("Applied haptic feedback - Intensity: " + str(intensity) + " Duration: " + str(duration))
