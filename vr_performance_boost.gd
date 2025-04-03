extends Node

# This script is designed to optimize VR performance globally
# It will be loaded as an autoload singleton

@export_range(0, 2) var vr_optimization_level: int = 2 # 0=Low, 1=Medium, 2=High (default)
@export var enable_debug: bool = false

func _ready():
	print("\n=== VR Performance Optimization Running ===")
	
	# Apply optimization as early as possible
	call_deferred("apply_optimizations")
	
	# Re-apply optimizations after 2 frames to ensure they override any scene-specific settings
	get_tree().process_frame.connect(_on_second_frame, CONNECT_ONE_SHOT)

func _on_second_frame():
	apply_optimizations()

func apply_optimizations():
	print("Applying VR performance optimizations at level: " + str(vr_optimization_level))
	
	# --- Engine Settings ---
	# Reduce physics and rendering load
	Engine.max_fps = 72
	Engine.physics_ticks_per_second = 45
	Engine.time_scale = 1.0
	
	# --- Rendering Project Settings ---
	# These settings need to be applied through project settings
	# We can't easily modify these at runtime programmatically
	# But we can modify the viewport settings
	
	# Disable expensive rendering features when in high optimization mode
	if vr_optimization_level >= 1:
		# Get the main viewport
		var viewport = get_viewport()
		if viewport:
			# Adjust shadow settings
			viewport.positional_shadow_atlas_size = 2048
			viewport.mesh_lod_threshold = 2.0  # Increase LOD bias 
			
			# Disable anti-aliasing and post-processing
			viewport.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
			viewport.use_debanding = false
			viewport.msaa_3d = Viewport.MSAA_DISABLED
	
	# --- VR Specific Optimizations ---
	# Only when in VR mode
	if XRServer.primary_interface != null:
		var xr_interface = XRServer.primary_interface
		
		# Set the display refresh rate if possible
		if xr_interface.has_method("set_display_refresh_rate"):
			# Most VR headsets support 72, 80, or 90 Hz
			# Lower refresh rates reduce GPU load
			xr_interface.set_display_refresh_rate(72.0)
			print("VR refresh rate set to 72Hz")
		
		# If you have a specific method to reduce VR render resolution, you would call it here
		# This would look something like:
		# xr_interface.render_target_size_multiplier = 0.8
	
	# --- Global Optimization for ALL Nodes ---
	# Find all nodes of relevant types and optimize them
	optimize_nodes_in_tree(get_tree().root)
	
	print("Global VR performance optimization complete")

func optimize_nodes_in_tree(root_node):
	# Process the current node
	optimize_node(root_node)
	
	# Process all children recursively
	for child in root_node.get_children():
		optimize_nodes_in_tree(child)

func optimize_node(node):
	# Check node type and apply optimizations
	
	if node is MeshInstance3D:
		# These properties only exist on GeometryInstance3D
		if node is GeometryInstance3D:
			node.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
			node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF if vr_optimization_level >= 2 else GeometryInstance3D.SHADOW_CASTING_SETTING_ON
			node.lod_bias = 5.0  # Aggressive LOD adjustment
		
		# If there's a material, optimize it too
		if node.material_override:
			optimize_material(node.material_override)
		
		# Also check for mesh-specific materials
		var mesh = node.mesh
		if mesh:
			for i in range(mesh.get_surface_count()):
				var material = mesh.surface_get_material(i)
				if material:
					optimize_material(material)
	
	elif node is DirectionalLight3D or node is OmniLight3D or node is SpotLight3D:
		if vr_optimization_level >= 2:
			node.shadow_enabled = false
		else:
			node.shadow_enabled = true
			node.shadow_bias = 0.1
			node.shadow_normal_bias = 3.0
			if node is DirectionalLight3D:
				node.directional_shadow_max_distance = 50.0
		
		# Reduce light energy
		node.light_energy *= 0.7
		node.light_indirect_energy = 0.0
		
	elif node is WorldEnvironment and node.environment:
		optimize_environment(node.environment)

func optimize_material(material):
	if material is StandardMaterial3D:
		# Use simpler shading for better performance
		material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
		
		# Disable expensive effects
		material.refraction_enabled = false
		material.clearcoat_enabled = false
		material.anisotropy_enabled = false
		material.ao_enabled = false
		material.subsurface_scattering_enabled = false
		material.proximity_fade_enabled = false
		material.distance_fade_mode = BaseMaterial3D.DISTANCE_FADE_DISABLED

func optimize_environment(env):
	# Disable expensive effects
	env.sdfgi_enabled = false
	env.ssao_enabled = false
	env.ssil_enabled = false
	env.glow_enabled = false
	env.volumetric_fog_enabled = false
	
	# Reduce ambient light calculations
	env.ambient_light_energy = 1.0
	env.reflected_light_source = 0  # Disable reflections
	
	# Simplify background
	env.background_energy_multiplier = 0.8
	
	# Disable fog
	env.fog_enabled = false
