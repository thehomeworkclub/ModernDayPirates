extends Node3D

@onready var melee_enemy = preload("res://enemies/melee enemy/MeleeEnemy.tscn")
@onready var boss_spawn = $bossspawn
@onready var wave_center = $wave_center.global_position
# Health display is now attached to the gun, so we'll access it through the VRGunController
@onready var vr_gun_controller = $XROrigin3D/VRGunController
@onready var health_display = null  # Will be initialized in _ready()

var boss_enemy = null
@onready var xr_origin = $XROrigin3D
@onready var world_env = $WorldEnvironment
@onready var directional_light = $DirectionalLight3D
@onready var ship = $Dry_Cargo_Ship

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
		print_verbose("Gun health display referenced")
	else:
		print("INFO: Health display will be initialized when gun is created")
		
	# Apply performance optimizations for VR
	optimize_for_vr()
	
	# Enemy spawning disabled while focusing on player actions
	# wave_1()
	# boss_wave()
	
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
	if health_display:
		health_display.take_damage(amount)
		print("Player took " + str(amount) + " damage")
		
		# Check for death
		if health_display.current_health <= 0:
			print("Player died!")
			# Handle death - could restart level, show game over, etc.
			# For now just reset health to demonstrate system
			heal_player(max_player_health)
	
func heal_player(amount):
	if health_display:
		health_display.heal(amount)
		print("Player healed " + str(amount) + " health")

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
