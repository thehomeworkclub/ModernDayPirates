extends Node3D

@onready var melee_enemy = preload("res://enemies/melee enemy/MeleeEnemy.tscn")
@onready var boss_spawn = $bossspawn
@onready var wave_center = $wave_center.global_position
var scene_transition = null
# Health display is now attached to the gun, so we'll access it through the VRGunController
@onready var vr_gun_controller = $XROrigin3D/VRGunController
@onready var health_display = null  # Will be initialized in _ready()

var boss_enemy = null
@onready var xr_origin = $XROrigin3D
@onready var world_env = $WorldEnvironment
@onready var directional_light = $DirectionalLight3D
@onready var ship = $Dry_Cargo_Ship
@onready var enemy_spawner = $EnemySpawner
@onready var player_boat = $Area3D
@onready var sea = $sea
@onready var round_board = $RoundBoard
@onready var bomb_cleaner = $BombCleaner

# VR optimization level (LOW=0, MEDIUM=1, HIGH=2)
var vr_optimization_level = 2  # Set to HIGH for better performance

# Player health properties (now managed by HealthHUD)
var max_player_health = 10
var current_player_health = 10

# Called when the node enters the scene tree for the first time.
func _ready():
	# Initialize VR
	var xr_interface = XRServer.find_interface("OpenXR")
	if xr_interface:
		xr_interface.initialize()
		get_viewport().use_xr = true
		
	# Initialize scene transition
	if not scene_transition:
		scene_transition = load("res://SceneTransition.tscn").instantiate()
		get_tree().root.add_child(scene_transition)
	
	# Connect to GameManager's wave_completed signal to track round completion
	GameManager.connect("wave_completed", _on_wave_completed)

	# Set up VR 
	if xr_origin:
		# Use position already set in the scene editor
		print_verbose("Using editor-defined VR origin position: " + str(xr_origin.position))
		# Add VR origin to player group for future targeting
		xr_origin.add_to_group("player")
	else:
		print("ERROR: XROrigin3D not found")
		return
		
	# Get the health display from the gun controller
	if vr_gun_controller and vr_gun_controller.health_display:
		health_display = vr_gun_controller.health_display
		print("Gun health display referenced")
	else:
		print("INFO: Health display will be initialized when gun is created")
		# Defer health display setup to ensure VRGunController has time to initialize
		call_deferred("setup_health_display")
		
	# Apply performance optimizations for VR
	optimize_for_vr()
	
	# Initialize the player boat if it exists
	if player_boat:
		print_verbose("Player boat found and initialized")
	else:
		print("WARNING: Player boat not found")
	
	# Initialize the enemy spawner if it exists
	if enemy_spawner:
		print_verbose("Enemy spawner found and initialized")
	else:
		print("WARNING: Enemy spawner not found")
	
	# Initialize the sea if it exists
	if sea:
		print_verbose("Sea/ocean found and initialized")
	else:
		print("WARNING: Sea/ocean not found")
		
	# Initialize the round board if it exists
	if round_board:
		print_verbose("Round board found and initialized")
	else:
		print("WARNING: Round board not found")
		
	# Initialize the bomb cleaner if it exists
	if bomb_cleaner:
		print_verbose("Bomb cleaner found and initialized")
	else:
		print("WARNING: Bomb cleaner not found")
		
	# Initialize enemy spawning
	if enemy_spawner:
		print("Starting enemy spawning...")
		# Force GameManager into a state where spawning will work
		GameManager.game_started = true
		# Get enemies per wave from game parameters instead of hardcoding
		GameManager.enemies_per_wave = GameManager.game_parameters.get_total_ships_per_wave()
		GameManager.current_wave = 1
		GameManager.waves_completed_in_round = 0
		GameManager.enemy_spawn_rate = 1.0
		GameManager.wave_difficulty_multiplier = 1.0
		GameManager.enemy_speed = 1.0
		GameManager.enemy_health = 1.0
		
		# Ensure the player boat is properly registered with GameManager
		if player_boat:
			GameManager.player_boat = player_boat
			if not player_boat.is_in_group("player_boat"):
				player_boat.add_to_group("player_boat")
			print("Player boat registered with GameManager")
		
		# Register enemy spawner with GameManager
		GameManager.enemy_spawner = enemy_spawner
		
		# Force spawn a wave of enemies
		if enemy_spawner.has_method("start_wave_spawning"):
			enemy_spawner.start_wave_spawning()
			print("Enemy wave spawning started")
	else:
		print("WARNING: Enemy spawner not found or initialized")

func _input(event):
	# TEST FOR DAMAGE: Press 9 for damage test
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_9:
			damage_player(1)
			print("Input damage test triggered (key 9)")
			
	# TEST SCENE TRANSITION: Press 0 for scene transition test
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_0:
			print("Testing scene transition to shop")
			transition_to_shop()

# Setup the health display after everything is initialized
func setup_health_display():
	await get_tree().create_timer(0.1).timeout  # Give time for VRGunController to initialize
	
	# Try to get the health display again
	if vr_gun_controller:
		if vr_gun_controller.health_display:
			health_display = vr_gun_controller.health_display
			print("Gun health display initialized via deferred setup")
		else:
			# Force health display creation
			vr_gun_controller.add_health_display_to_gun()
			await get_tree().create_timer(0.1).timeout
			
			health_display = vr_gun_controller.health_display
			print("Gun health display created via forced initialization")
			
		# Ensure a connection to the boat
		var player_boat = get_tree().get_first_node_in_group("player_boat")
		if player_boat and health_display:
			if player_boat.has_method("get") and player_boat.get("health") != null:
				health_display.current_health = player_boat.health
				health_display.max_health = player_boat.max_health
				health_display.update_hearts()
				print("Synchronized health display with player boat: " + str(health_display.current_health) + "/" + str(health_display.max_health))

# Apply performance optimizations for VR
func optimize_for_vr():
	print("Applying VR performance optimizations...")
	
	# Optimize environment settings
	if world_env and world_env.environment:
		var env = world_env.environment
		# Disable most expensive rendering features
		env.sdfgi_enabled = false
		env.ssil_enabled = false
		env.ssao_enabled = false
		env.glow_enabled = false
		env.volumetric_fog_enabled = false
		
		# Reduce quality of other features
		if vr_optimization_level < 2:  # Only enable these in lower optimization modes
			env.ssao_enabled = true
			env.ssao_detail = 0  # Lower quality SSAO
			env.glow_enabled = true
			env.glow_intensity = 0.8  # Reduce glow intensity
		
		# Further reduce quality for all levels
		env.ambient_light_energy = 1.5  # Reduce light calculation complexity
		env.reflected_light_source = 0  # Disable reflections
		env.fog_enabled = false  # Disable fog for performance
		
		print("Optimized environment settings for VR optimization level: " + str(vr_optimization_level))
		
	# Optimize directional light
	if directional_light:
		# Disable shadows in HIGH mode, severely limit in other modes
		directional_light.shadow_enabled = vr_optimization_level < 2
		
		if directional_light.shadow_enabled:
			directional_light.shadow_bias = 0.1  # Increase bias to reduce artifacts with lower quality
			directional_light.shadow_normal_bias = 4.0  # Higher normal bias for better performance
			directional_light.directional_shadow_max_distance = 50.0  # Dramatically reduce shadow distance
			directional_light.shadow_blur = 1.0  # Increase blur for softer shadows (less detail)
			
		# Reduce light energy for better performance
		directional_light.light_energy = 0.8
		directional_light.light_indirect_energy = 0.0  # Disable indirect lighting
		print("Optimized directional light")
	
	# Optimize all meshes
	var all_meshes = find_all_mesh_instances(self)
	var mesh_count = 0
	
	for mesh_instance in all_meshes:
		# Disable global illumination for better performance
		mesh_instance.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
		
		# Disable shadow casting in HIGH mode
		mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		
		# Set LOD bias to render lower detail meshes sooner
		mesh_instance.lod_bias = 4.0  # Aggressive LOD adjustment
		
		# Additional optimizations
		if mesh_instance.material_override:
			# Force low quality shading
			mesh_instance.material_override.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
			
		mesh_count += 1
	
	print("Optimized " + str(mesh_count) + " mesh instances across entire scene")
	
	# Optimize ship specifically if exists
	if ship:
		# Ship might be a Node3D and not a GeometryInstance3D
		# Find all mesh instances in the ship and optimize them instead
		var ship_meshes = find_all_mesh_instances(ship)
		print("Applied additional optimizations to " + str(ship_meshes.size()) + " ship meshes")
		
	# Engine optimizations
	Engine.physics_ticks_per_second = 45  # Reduce physics calculations
	Engine.max_fps = 72  # Reduce target FPS for better stability
	
	# Rendering settings
	get_viewport().screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED  # Disable anti-aliasing
	get_viewport().use_debanding = false  # Disable debanding
	get_viewport().msaa_3d = Viewport.MSAA_DISABLED  # Disable MSAA
	
	print("Applied aggressive VR performance optimizations")

# Helper function to find all MeshInstance3D nodes in a node hierarchy
func find_all_mesh_instances(node: Node) -> Array:
	var result = []
	
	if node is MeshInstance3D:
		result.append(node)
		
	for child in node.get_children():
		result.append_array(find_all_mesh_instances(child))
		
	return result

# Player damage/health functions
func damage_player(amount):
	print("Level script damage_player called with amount: " + str(amount))

	# Ensure we have health display
	if not health_display and vr_gun_controller:
		health_display = vr_gun_controller.health_display
		print("Retrieving health display reference for damage")

	if health_display:
		print("Applying " + str(amount) + " damage to health display")
		health_display.take_damage(amount)
		
		# Debug output
		print("Player took " + str(amount) + " damage, health now: " + str(health_display.current_health))
		
		# Check for death
		if health_display.current_health <= 0:
			print("Player died!")
			# Handle death - could restart level, show game over, etc.
			# For now just reset health to demonstrate system
			heal_player(max_player_health)
	else:
		print("ERROR: Cannot apply damage - health display not found!")
		
		# Try to find the health display again by searching the scene
		var gun_controller = get_node_or_null("XROrigin3D/VRGunController")
		if gun_controller:
			if gun_controller.has_node("GunInstance/HealthDisplay"):
				health_display = gun_controller.get_node("GunInstance/HealthDisplay")
				health_display.take_damage(amount)
				print("Found health display via direct path and applied damage")
			else:
				print("GunInstance/HealthDisplay node not found")
		else:
			print("VRGunController node not found")
	
func heal_player(amount):
	if health_display:
		health_display.heal(amount)
		print("Player healed " + str(amount) + " health")

# Handle wave completion notification from GameManager
func _on_wave_completed():
	print("LEVEL1: Received wave_completed signal")
	print("LEVEL1: Current wave progress: " + str(GameManager.waves_completed_in_round) + "/" + 
		str(GameManager.game_parameters.waves_per_round))
	
	# Check if all waves in the round are completed
	if GameManager.waves_completed_in_round >= GameManager.game_parameters.waves_per_round:
		print("LEVEL1: All waves in round completed, transitioning to shop in 2 seconds")
		# Wait a moment before transitioning to shop to allow for cleanup
		get_tree().create_timer(2.0).timeout.connect(transition_to_shop)
	else:
		print("LEVEL1: More waves remain in this round: " + str(GameManager.waves_completed_in_round) + "/" + 
			str(GameManager.game_parameters.waves_per_round))

# Transition to shop scene with fade effect
func transition_to_shop():
	print("LEVEL1: Transitioning to shop scene now")
	# Try to use the global SceneTransition singleton first
	if get_node_or_null("/root/SceneTransition") != null:
		print("LEVEL1: Using global SceneTransition singleton")
		get_node("/root/SceneTransition").change_scene_with_fade("res://shop1.tscn")
	# Fall back to our local scene_transition if global isn't working
	elif scene_transition:
		print("LEVEL1: Using local scene_transition instance")
		scene_transition.change_scene_with_fade("res://shop1.tscn")
	else:
		# Fallback if scene transition not available
		print("LEVEL1: No transition available, using direct scene change")
		get_tree().change_scene_to_file("res://shop1.tscn")

func boss_wave():
	if ResourceLoader.exists("res://enemies/bosses/melee boss/boss.tscn"):
		if boss_enemy == null:
			boss_enemy = load("res://enemies/bosses/melee boss/boss.tscn")
		var boss = boss_enemy.instantiate()
		if boss_spawn:
			boss.position = boss_spawn.global_position
		else:
			print("WARNING: boss_spawn not found, using default position")
		add_child(boss)
	else:
		print("Boss scene not found, skipping boss wave")

func wave_1():
	if !is_instance_valid(GlobalVars):
		print("ERROR: GlobalVars not found")
		return
		
	if !is_instance_valid(Level1Vars):
		print("ERROR: Level1Vars not found")
		return
		
	if !wave_center:
		print("ERROR: wave_center not found")
		return
	
	var wave_data = Level1Vars.get_current_wave_data()
	var enemy_count = wave_data["enemy_count"]
	
	print("Spawning wave with " + str(enemy_count) + " enemies")
	
	for i in range(enemy_count):
		var offset = Vector3(
			(i - enemy_count/2.0) * 5.0, # Space enemies horizontally
			0,
			0
		)
		GlobalVars.spawn_melee(Level1Vars, wave_center + offset, self)
	
	# Advance to next wave
	Level1Vars.current_wave += 1
