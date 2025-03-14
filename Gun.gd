extends Node3D

@export var bullet_scene: PackedScene
@export var fire_rate: float = 0.5  # Time between shots in seconds
@export var bullet_damage: int = 1

var gun_type: String = "standard"
var can_shoot: bool = true
var shoot_timer: Timer
var is_vr_gun: bool = false

func _ready() -> void:
	# Create timer for fire rate
	shoot_timer = Timer.new()
	shoot_timer.one_shot = true
	add_child(shoot_timer)
	shoot_timer.timeout.connect(_on_shoot_timer_timeout)
	
	# Set gun type based on GameManager
	set_gun_type(GameManager.gun_type)
	
	# Debug check if Muzzle exists
	if not has_node("Muzzle"):
		print("ERROR: Muzzle node not found in Gun scene!")
		
	# Detect if we're attached to a controller in VR
	if get_parent() is XRController3D:
		is_vr_gun = true
		print("DEBUG: Gun attached to VR controller")

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("shoot") and can_shoot:
		shoot()

func set_gun_type(type: String) -> void:
	gun_type = type
	
	# Update gun properties based on type
	match gun_type:
		"standard":
			fire_rate = 0.5
			bullet_damage = 1
		"rapid":
			fire_rate = 0.2
			bullet_damage = 1
		"double":
			fire_rate = 0.6
			bullet_damage = 1
		"spread":
			fire_rate = 0.7
			bullet_damage = 1
		"power":
			fire_rate = 0.8
			bullet_damage = 3

func shoot() -> void:
	can_shoot = false
	print("DEBUG: Shooting gun of type " + gun_type)
	
	# Different shooting behaviors based on gun type
	match gun_type:
		"standard":
			create_bullet(Vector3.ZERO)
		"rapid":
			create_bullet(Vector3.ZERO)
		"double":
			create_bullet(Vector3(-0.2, 0, 0))
			create_bullet(Vector3(0.2, 0, 0))
		"spread":
			create_bullet(Vector3.ZERO)
			var bullet1 = create_bullet(Vector3(0, 0.1, 0))
			if bullet1:
				bullet1.rotation_degrees.x = -5
			var bullet2 = create_bullet(Vector3(0, -0.1, 0))
			if bullet2:
				bullet2.rotation_degrees.x = 5
		"power":
			var bullet = create_bullet(Vector3.ZERO)
			if bullet:
				bullet.scale = Vector3(1.5, 1.5, 1.5)
	
	# Apply haptic feedback in VR mode
	if is_vr_gun and get_parent() is XRController3D:
		var controller = get_parent() as XRController3D
		controller.trigger_haptic_pulse("haptic", 0.5, 0.2, 0.5, 0.0)
	
	# Start cooldown
	shoot_timer.wait_time = fire_rate
	shoot_timer.start()

func create_bullet(local_offset: Vector3) -> Node3D:
	if not bullet_scene:
		print("ERROR: No bullet scene assigned to gun")
		return null
	
	# Get muzzle position
	var muzzle = $Muzzle
	if not muzzle:
		print("ERROR: Muzzle node not found")
		return null
	
	var forward_dir: Vector3
	
	# Determine aiming direction based on if we're in VR or not
	if is_vr_gun:
		# In VR, use the controller's forward direction
		forward_dir = -global_transform.basis.z.normalized()
		print("DEBUG: VR Controller forward direction: ", forward_dir)
	else:
		# In desktop mode, use the camera's forward direction
		var head = get_parent().get_parent()
		var camera = head.get_node("Camera3D")
		forward_dir = -camera.global_transform.basis.z.normalized()
		print("DEBUG: Camera forward direction: ", forward_dir)
	
	# Create the bullet instance
	var bullet = bullet_scene.instantiate()
	
	# Calculate spawn position
	var spawn_position = muzzle.global_position
	
	# Apply local offset if needed
	if local_offset != Vector3.ZERO:
		var global_offset = global_transform.basis * local_offset
		spawn_position += global_offset
	
	# Calculate damage with bonuses
	var final_damage = int(bullet_damage * (1.0 + GameManager.damage_bonus) * CurrencyManager.damage_multiplier)
	bullet.damage = final_damage
	
	# Set bullet direction 
	bullet.direction = forward_dir
	
	# Add the bullet to the scene
	get_tree().current_scene.add_child(bullet)
	
	# Set position AFTER adding to scene
	bullet.global_position = spawn_position
	
	print("DEBUG: Bullet spawned at: ", bullet.global_position)
	
	return bullet

func _on_shoot_timer_timeout() -> void:
	can_shoot = true
