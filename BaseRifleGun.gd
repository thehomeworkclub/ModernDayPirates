extends "res://Gun.gd"

# Rifle-specific properties
@export_range(1, 30) var magazine_size: int = 30
@export var reload_time: float = 0.5  # Time to complete reload once magazine is inserted
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

# Magazine state
enum MagazineState { ATTACHED_TO_GUN, DETACHED }
var magazine_state = MagazineState.ATTACHED_TO_GUN
var magazine_node: Node3D = null
var magazine_original_transform: Transform3D
var hand_magazine_position = Vector3(0, 0, 0.05)  # Position relative to left controller
var magazine_detection_distance: float = 0.2  # Distance for detecting magazine insertion (doubled for easier reattachment)
var debug_distance: float = 0.0  # For debugging
var detachment_cooldown: float = 0.0  # Cooldown timer

# Debug info
var debug_enabled: bool = true

func _process(delta: float) -> void:
	if automatic and Input.is_action_pressed("shoot") and can_shoot and current_ammo > 0 and not is_reloading:
		shoot()
	elif Input.is_action_just_pressed("shoot") and can_shoot and current_ammo > 0 and not is_reloading:
		shoot()
	
	# Manual detachment/reattachment with reload button (for debugging)
	if Input.is_action_just_pressed("reload"):
		if magazine_state == MagazineState.ATTACHED_TO_GUN:
			detach_magazine()
		else:
			check_for_reattachment()
	
	# Update detachment cooldown
	if detachment_cooldown > 0:
		detachment_cooldown -= delta
	
	# Always check for controller positions
	update_controller_positions()

func _ready() -> void:
	super._ready()
	
	# Set initial ammo
	current_ammo = magazine_size
	
	# Find magazine node
	magazine_node = find_magazine_node()
	if magazine_node:
		magazine_original_transform = magazine_node.transform
		print("Found magazine node: " + magazine_node.name)
	else:
		print("WARNING: Magazine node not found")
	
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
	
	print("Rifle gun initialized: " + str(gun_type))

# Find the magazine node in the model
func find_magazine_node() -> Node3D:
	var model = $Model
	if model:
		return model.get_node_or_null("Magazine")
	return null

# Update controller positions and check for detachment/reattachment
func update_controller_positions() -> void:
	if not right_controller or not left_controller:
		return
	
	if magazine_state == MagazineState.ATTACHED_TO_GUN:
		check_for_detachment()
	else:
		check_for_reattachment()

# Check if left controller has moved away from right controller's "line"
func check_for_detachment() -> void:
	if detachment_cooldown > 0:
		return
		
	# Auto-detach empty magazines
	if current_ammo <= 0:
		detach_magazine()
		return
		
	# Get right controller's forward direction
	var right_forward = -right_controller.global_transform.basis.z.normalized()
	
	# Calculate vector from right to left controller
	var right_to_left = left_controller.global_position - right_controller.global_position
	
	# Project right_to_left onto right_forward to get the parallel component
	var parallel_component = right_to_left.dot(right_forward) * right_forward
	
	# Perpendicular component is what we need to check
	var perpendicular_component = right_to_left - parallel_component
	
	# Track distance for debugging
	debug_distance = perpendicular_component.length()
	
	# If perpendicular distance is above threshold, detach magazine
	if debug_distance > 0.3:  # Threshold distance (doubled for easier detachment)
		print("Perpendicular distance: " + str(debug_distance) + ", detaching magazine")
		detach_magazine()

# Check if left controller is in position to reattach magazine
func check_for_reattachment() -> void:
	if is_reloading:
		return
		
	# Get the magazine well position in global space
	var model = $Model
	if not model:
		return
		
	var magazine_well_global = global_transform * model.transform * magazine_original_transform.origin
	
	# Calculate distance from left controller to magazine well
	var distance = (left_controller.global_position - magazine_well_global).length()
	
	# If left controller is close enough to the magazine well, reattach
	if distance < magazine_detection_distance:
		print("Controller distance to magazine well: " + str(distance) + ", reattaching")
		reattach_magazine()

# Detach magazine from gun
func detach_magazine() -> void:
	if not magazine_node or magazine_state == MagazineState.DETACHED:
		return
		
	if debug_enabled:
		print("Detaching magazine. Current ammo: " + str(current_ammo))
	
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

# Helper to create a magazine model on the hand
func create_hand_magazine_model(parent: Node3D) -> void:
	if magazine_node.get_child_count() > 0:
		var magazine_model = magazine_node.get_child(0).duplicate()
		parent.add_child(magazine_model)
	else:
		# Fallback simple magazine if no model exists
		var mesh = CSGBox3D.new()
		mesh.size = Vector3(0.05, 0.12, 0.02)
		parent.add_child(mesh)

# Helper to show/hide gun magazine
func hide_gun_magazine(hide: bool) -> void:
	if magazine_node:
		for child in magazine_node.get_children():
			child.visible = !hide

# Reattach magazine to gun and start reload process
func reattach_magazine() -> void:
	if magazine_state == MagazineState.ATTACHED_TO_GUN:
		return
		
	if debug_enabled:
		print("Reattaching magazine")
	
	# Find and remove hand magazine
	var hand_magazine = left_controller.get_node_or_null("HandMagazine")
	if hand_magazine:
		hand_magazine.queue_free()
	
	# Show magazine on gun again
	hide_gun_magazine(false)
	
	# Change state before starting reload
	magazine_state = MagazineState.ATTACHED_TO_GUN
	
	# Trigger haptic feedback
	if right_controller:
		right_controller.trigger_haptic_pulse("haptic", 0.7, 0.2, 1.0, 0.0)
	if left_controller:
		left_controller.trigger_haptic_pulse("haptic", 0.7, 0.2, 1.0, 0.0)
	
	# Start reload process
	reload()

# Override the shoot method completely - DON'T call super.shoot()
func shoot() -> void:
	# Stop shooting if empty or reloading
	if current_ammo <= 0:
		# Click sound would play here
		print("Out of ammo!")
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
	
	if debug_enabled:
		print("Rifle ammo remaining: " + str(current_ammo))
	
	# Start cooldown timer
	shoot_timer.wait_time = fire_rate
	shoot_timer.start()
	
	# Detach magazine automatically if empty (to simulate ejecting the empty mag)
	if current_ammo <= 0:
		detach_magazine()

func spawn_bullet(spread_offset: Vector3) -> void:
	if not bullet_scene:
		print("ERROR: No bullet scene assigned")
		return
		
	# Find muzzle position
	var muzzle = $Muzzle
	if not muzzle:
		print("ERROR: Muzzle node not found")
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
		print("ERROR: Muzzle node not found")
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
		
	print("Reloading rifle...")
	is_reloading = true
	
	# Play reload animation/sound here
	
	reload_timer.wait_time = reload_time
	reload_timer.start()

func _on_reload_timer_timeout() -> void:
	current_ammo = magazine_size
	is_reloading = false
	
	print("Reload complete. Ammo: " + str(current_ammo))

func apply_recoil() -> void:
	var animation_player = $AnimationPlayer
	if animation_player and animation_player.has_animation("recoil"):
		animation_player.stop()
		animation_player.play("recoil")

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
