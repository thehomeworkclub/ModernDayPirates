extends Node3D

@onready var melee_enemy = preload("res://enemies/melee enemy/MeleeEnemy.tscn")
@onready var boss_spawn = $bossspawn
@onready var wave_center = $wave_center.global_position

var boss_enemy = null
@onready var xr_origin = $XROrigin3D
@onready var world_env = $WorldEnvironment
@onready var directional_light = $DirectionalLight3D
@onready var ship = $Dry_Cargo_Ship

# VR optimization level (LOW=0, MEDIUM=1, HIGH=2)
var vr_optimization_level = 1  # Default to medium

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
		# Add VR origin to player group for enemy targeting
		xr_origin.add_to_group("player")
	else:
		print("ERROR: XROrigin3D not found")
		return
		
	# Apply performance optimizations for VR
	optimize_for_vr()

	# Start waves after setup
	wave_1()
	boss_wave()
	
# Apply performance optimizations for VR
func optimize_for_vr():
	print("Applying VR performance optimizations...")
	
	# Optimize environment settings
	if world_env and world_env.environment:
		var env = world_env.environment
		# Disable most expensive rendering features
		env.sdfgi_enabled = false
		env.ssil_enabled = false
		env.volumetric_fog_enabled = false
		# Reduce quality of other features
		env.ssao_enabled = vr_optimization_level < 2  # Disable in HIGH mode
		env.ssao_detail = 0  # Lower quality SSAO
		env.glow_enabled = vr_optimization_level < 2  # Disable in HIGH mode
		env.glow_intensity = 1.0  # Reduce glow intensity
		print("Optimized environment settings")
		
	# Optimize directional light
	if directional_light:
		# Reduce shadow quality for better performance
		directional_light.shadow_enabled = vr_optimization_level < 2  # Disable in HIGH mode
		directional_light.shadow_bias = 0.05
		directional_light.shadow_normal_bias = 2.0
		directional_light.directional_shadow_max_distance = 100.0
		directional_light.directional_shadow_split_1 = 0.1
		directional_light.directional_shadow_split_2 = 0.2
		directional_light.directional_shadow_split_3 = 0.5
		print("Optimized directional light")
		
	# Optimize ship mesh
	if ship:
		# Find all MeshInstance3D nodes in the ship
		var mesh_instances = find_all_mesh_instances(ship)
		for mesh_instance in mesh_instances:
			# Disable global illumination for better performance
			mesh_instance.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
			
			# Set shadow casting based on optimization level
			if vr_optimization_level == 2:  # HIGH
				mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			else:
				mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
				
			# Set LOD bias to render lower detail meshes sooner
			mesh_instance.lod_bias = 2.0 + vr_optimization_level
		
		print("Optimized ship mesh with " + str(mesh_instances.size()) + " mesh instances")
		
	# Set physics tick rate to improve performance
	Engine.physics_ticks_per_second = 60
	
	# Set target FPS for VR
	Engine.max_fps = 90
	
	print("VR performance optimizations applied")

# Helper function to find all MeshInstance3D nodes in a node hierarchy
func find_all_mesh_instances(node: Node) -> Array:
	var result = []
	
	if node is MeshInstance3D:
		result.append(node)
		
	for child in node.get_children():
		result.append_array(find_all_mesh_instances(child))
		
	return result

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
