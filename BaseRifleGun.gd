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
	
	# Get controller references
	var vr_origin = get_parent().get_parent() # Gun → VRGunController → XROrigin3D
	if vr_origin:
		right_controller = vr_origin.get_node_or_null("XRController3DRight")
		left_controller = vr_origin.get_node_or_null("XRController3DLeft")
	
	print_verbose("Rifle gun initialized: " + str(gun_type))

func shoot() -> void:
	if current_ammo <= 0:
		# Click sound would play here
		print_verbose("Out of ammo!")
		reload()
		return
		
	if is_reloading:
		return
		
	current_ammo -= 1
	
	# Apply random spread based on accuracy
	var spread = 1.0 - accuracy
	var random_spread = Vector3(
		randf_range(-spread, spread),
		randf_range(-spread, spread),
		0
	)
	
	# Call the base gun shoot with modified parameters
	super.shoot()
	
	# Apply recoil effect
	apply_recoil()
	
	# Provide haptic feedback on both controllers
	apply_haptic_feedback()
	
	print_verbose("Rifle ammo remaining: " + str(current_ammo))
	
	# Auto-reload when empty
	if current_ammo <= 0:
		reload()

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
