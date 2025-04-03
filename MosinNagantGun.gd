extends "res://BaseRifleGun.gd"

# Animation reference
@onready var animation_player = $AnimationPlayer

# Bolt action state
var is_bolt_cycling: bool = false
var bolt_cycle_time: float = 1.2
var bolt_timer: Timer

func _ready() -> void:
	# Set Mosin Nagant specific properties
	gun_type = "mosin"
	fire_rate = 1.5  # Very slow fire rate for bolt action
	bullet_damage = 8  # High damage
	magazine_size = 5  # Small magazine
	reload_time = 3.0  # Slow reload
	accuracy = 0.98  # Very high accuracy
	recoil = 0.8     # High recoil
	automatic = false  # Single shot only
	
	# Create bolt cycle timer
	bolt_timer = Timer.new()
	bolt_timer.one_shot = true
	add_child(bolt_timer)
	bolt_timer.timeout.connect(_on_bolt_timer_timeout)
	
	# Call parent _ready after setting properties
	super._ready()
	
	print_verbose("Mosin Nagant rifle initialized")

# Override shoot method to implement bolt action mechanism
func shoot() -> void:
	# Don't shoot if bolt is cycling
	if is_bolt_cycling:
		return
		
	# Play recoil animation
	if animation_player != null and animation_player.has_animation("recoil"):
		animation_player.stop()
		animation_player.play("recoil")
	
	# Call the parent shoot method
	super.shoot()
	
	# Start bolt cycling
	is_bolt_cycling = true
	bolt_timer.wait_time = bolt_cycle_time
	bolt_timer.start()
	
	# Apply stronger controller feedback for the powerful rifle
	if right_controller:
		right_controller.trigger_haptic_pulse("haptic", 1.0, 0.3, 1.0, 0.0)
	if left_controller:
		left_controller.trigger_haptic_pulse("haptic", 0.8, 0.2, 1.0, 0.0)

func _on_bolt_timer_timeout() -> void:
	is_bolt_cycling = false
	
	# If we have bullets, simulate bolt action sound/animation here
	if current_ammo > 0:
		# Play bolt action sound/animation
		pass
