# MeleeEnemy.gd
extends CharacterBody3D
class_name MeleeBoss

# Melee-specific properties
@export var attack_range: float = 2.0
@export var attack_cooldown: float = 1.0
@export var cone_attack_cooldown: float = 5.0  # Time between cone attacks
@export var cone_warning_duration: float = 3.0  # How long the warning stays before damage
@export var cone_damage: float = 25.0  # Damage dealt by cone attack
@export var cone_angle: float = 60.0  # Angle of the cone in degrees
@export var cone_length: float = 10.0  # Length of the cone

# Preload your cone indicator scene
@export var indicator_scene: PackedScene = preload("res://enemies/bosses/melee boss/cone_attack.tscn")

# Melee components
@onready var attack_timer = $Timer
@onready var animations = $character/AnimationPlayer

var speed = 5
var accel = 6
var cone_indicator = null  # Will hold the cone indicator node
var look = {"should_look": true}

func _ready():
	print("ready")
	perform_cone_attack()
	_init_enemy()
	# Add a timer for the cone attack if it doesn't exist
	if not has_node("ConeAttackTimer"):
		var timer = Timer.new()
		timer.name = "ConeAttackTimer"
		timer.wait_time = cone_attack_cooldown
		timer.autostart = true
		timer.timeout.connect(_on_cone_attack_timer_timeout)
		add_child(timer)
func _init_enemy():
	# Initialize melee-specific components
	attack_timer.wait_time = attack_cooldown
	attack_timer.one_shot = true
	print("anim play")
	animations.get_animation("passive").loop_mode = (Animation.LOOP_LINEAR)
	animations.play("passive")

func _physics_process(delta):
	# Make the boss face the player
	if look.should_look:
		look_at(Vector3(PlayerVariables.player.global_position.x, global_position.y, PlayerVariables.player.global_position.z), Vector3.UP)

func _on_cone_attack_timer_timeout():
	perform_cone_attack()

func perform_cone_attack():
	look_at(Vector3(PlayerVariables.player.global_position.x, global_position.y, PlayerVariables.player.global_position.z), Vector3.UP)
	
	# Create cone indicator using your preloaded scene
	spawn_cone_indicator()
	
	# Schedule the attack to happen after warning duration
	var damage_timer = get_tree().create_timer(cone_warning_duration)
	damage_timer.timeout.connect(_on_cone_attack_damage)

func spawn_cone_indicator():
	print("indicator called")
	# Remove any existing indicator
	if cone_indicator != null and is_instance_valid(cone_indicator):
		cone_indicator.queue_free()
	
	# Instance your custom indicator scene
	if indicator_scene:
		print("indicator spawned")
		cone_indicator = indicator_scene.instantiate()
		add_child(cone_indicator)
		
		# Position it slightly above ground
		cone_indicator.global_position = Vector3(global_position.x, global_position.y+.1, global_position.z)
		
		# Scale it according to your cone length and angle if needed
		var scale_factor = cone_length / 10.0  # Adjust this divisor based on your default indicator size
		
		# Add pulsing effect for better visibility if your scene doesn't already have one
		add_pulse_effect_to_indicator()
	else:
		push_error("No indicator scene assigned to MeleeBoss")

func add_pulse_effect_to_indicator():
	# Find materials in your indicator to pulse
	# This assumes your indicator has a MeshInstance3D as a child or is one itself
	var mesh_instance = null
	
	if cone_indicator is MeshInstance3D:
		mesh_instance = cone_indicator
	else:
		# Try to find a MeshInstance3D child
		for child in cone_indicator.get_children():
			if child is MeshInstance3D:
				mesh_instance = child
				break
	
	if mesh_instance and mesh_instance.get_surface_override_material_count() > 0:
		var material = mesh_instance.get_surface_override_material(0)
		if material:
			# Create a pulsing effect
			var tween = create_tween().set_loops()
			if material.has_method("get_albedo_color"):
				var base_color = material.get_albedo_color()
				var bright_color = Color(base_color.r, base_color.g, base_color.b, min(base_color.a + 0.3, 1.0))
				var dim_color = Color(base_color.r, base_color.g, base_color.b, max(base_color.a - 0.3, 0.2))
				
				tween.tween_property(material, "albedo_color", bright_color, 0.5)
				tween.tween_property(material, "albedo_color", dim_color, 0.5)

func _on_cone_attack_damage():
	if not PlayerVariables.player or not cone_indicator or not is_instance_valid(cone_indicator):
		return
	
	# Check if player is inside the cone
	var player_in_cone = is_player_in_cone()
	
	if player_in_cone:
		# Deal damage to player
		PlayerVariables.player.damage(cone_damage)
		print("Cone attack hit player!")
	
	# Remove the indicator
	if cone_indicator and is_instance_valid(cone_indicator):
		cone_indicator.queue_free()
		cone_indicator = null

func is_player_in_cone():
	if not PlayerVariables.player:
		return false
	
	# Get player position relative to boss
	var to_player = PlayerVariables.player.global_position - global_position
	to_player.y = 0  # Ignore height difference
	
	# Check distance
	var distance = to_player.length()
	if distance > cone_length:
		return false
	
	# Check angle
	var forward = -global_transform.basis.z  # Forward direction of the boss
	forward.y = 0
	forward = forward.normalized()
	
	var to_player_normalized = to_player.normalized()
	var angle = rad_to_deg(acos(forward.dot(to_player_normalized)))
	
	return angle <= cone_angle / 2
