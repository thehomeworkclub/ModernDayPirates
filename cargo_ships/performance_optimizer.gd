extends Node

# Performance Optimizer for VR
# This script provides functions to optimize VR performance with cargo ships

class_name ShipPerformanceOptimizer

# LOD (Level of Detail) distances
const LOD_DISTANCES = {
	"near": 30.0,
	"medium": 60.0,
	"far": 120.0
}

# Optimization levels
enum OptimizationLevel {
	LOW,    # Visual quality prioritized
	MEDIUM, # Balanced
	HIGH    # Performance prioritized
}

# Apply optimizations to a WorldEnvironment node
static func optimize_environment(world_env: WorldEnvironment, level: int = OptimizationLevel.MEDIUM) -> void:
	if not world_env or not world_env.environment:
		print_verbose("No valid environment to optimize")
		return
		
	var env = world_env.environment
	
	# Base settings for all optimization levels
	# Disable the most expensive effects
	env.sdfgi_enabled = false
	
	match level:
		OptimizationLevel.LOW:
			# Minor optimizations, maintain quality
			env.ssao_enabled = true
			env.ssao_power = 1.5
			env.ssil_enabled = true
			env.glow_enabled = true
			env.volumetric_fog_enabled = false
			
		OptimizationLevel.MEDIUM:
			# Balanced optimizations
			env.ssao_enabled = true
			env.ssao_power = 2.0
			env.ssil_enabled = false
			env.glow_enabled = true
			env.glow_intensity = 1.0
			env.fog_enabled = true
			env.fog_density = 0.01
			
		OptimizationLevel.HIGH:
			# Maximum performance
			env.ssao_enabled = false
			env.ssil_enabled = false
			env.glow_enabled = false
			env.fog_enabled = false
	
	print_verbose("Environment optimized with level: " + str(level))

# Optimize directional light for performance
static func optimize_directional_light(light: DirectionalLight3D, level: int = OptimizationLevel.MEDIUM) -> void:
	if not light:
		return
		
	# Base settings
	light.shadow_normal_bias = 1.0
	
	match level:
		OptimizationLevel.LOW:
			light.shadow_enabled = true
			light.directional_shadow_max_distance = 150.0
			light.directional_shadow_split_1 = 0.1
			light.directional_shadow_split_2 = 0.2
			light.directional_shadow_split_3 = 0.5
			
		OptimizationLevel.MEDIUM:
			light.shadow_enabled = true
			light.directional_shadow_max_distance = 75.0
			light.directional_shadow_split_1 = 0.15
			light.directional_shadow_split_2 = 0.3
			light.directional_shadow_split_3 = 0.6
			
		OptimizationLevel.HIGH:
			light.shadow_enabled = false
	
	print_verbose("Directional light optimized with level: " + str(level))

# Optimize a ship mesh for VR performance
static func optimize_ship(ship: Node3D, level: int = OptimizationLevel.MEDIUM) -> void:
	if not ship:
		return
		
	# Find all MeshInstance3D nodes in the ship
	var meshes = find_meshes_in_node(ship)
	print_verbose("Found " + str(meshes.size()) + " meshes in ship")
	
	for mesh_instance in meshes:
		# Skip if not a MeshInstance3D
		if not mesh_instance is MeshInstance3D:
			continue
			
		match level:
			OptimizationLevel.LOW:
				# Keep cast_shadow but reduce max distance
				mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
				# Set reasonable LOD bias
				mesh_instance.lod_bias = 1.5
				
			OptimizationLevel.MEDIUM:
				# Reduce shadow quality
				mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
				# Increase LOD bias (show lower detail meshes sooner)
				mesh_instance.lod_bias = 2.0
				# Reduce gi_mode
				mesh_instance.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
				
			OptimizationLevel.HIGH:
				# Disable shadows
				mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				# Maximum LOD bias for performance
				mesh_instance.lod_bias = 4.0
				# Disable global illumination
				mesh_instance.gi_mode = GeometryInstance3D.GI_MODE_DISABLED

# Find all mesh instances in a node and its children
static func find_meshes_in_node(node: Node) -> Array:
	var meshes = []
	
	if node is MeshInstance3D:
		meshes.append(node)
		
	for child in node.get_children():
		meshes.append_array(find_meshes_in_node(child))
		
	return meshes

# Apply all optimizations to a scene
static func optimize_scene(scene: Node, level: int = OptimizationLevel.MEDIUM) -> void:
	print_verbose("Optimizing scene for VR performance...")
	
	# Find key nodes
	var world_env = scene.get_node_or_null("WorldEnvironment")
	var directional_light = scene.get_node_or_null("DirectionalLight3D")
	
	# Find ship nodes (assuming they might have "ship", "boat", or "cargo" in their name)
	var ships = []
	for child in scene.get_children():
		if "ship" in child.name.to_lower() or "boat" in child.name.to_lower() or "cargo" in child.name.to_lower():
			ships.append(child)
	
	# Apply optimizations
	if world_env:
		optimize_environment(world_env, level)
		
	if directional_light:
		optimize_directional_light(directional_light, level)
		
	for ship in ships:
		optimize_ship(ship, level)
		
	print_verbose("Scene optimization complete with level: " + str(level))

# Create LOD (Level of Detail) for a ship
static func create_ship_lod(original_ship: Node3D) -> Node3D:
	if not original_ship:
		return null
		
	# Create LOD parent node
	var lod_parent = Node3D.new()
	lod_parent.name = original_ship.name + "_LOD"
	
	# Create 3 LOD levels (progressively simpler)
	var lod_levels = 3
	
	for i in range(lod_levels):
		var lod_node = original_ship.duplicate()
		lod_node.name = "LOD" + str(i)
		
		# Apply different optimizations based on LOD level
		var meshes = find_meshes_in_node(lod_node)
		for mesh_instance in meshes:
			if not mesh_instance is MeshInstance3D:
				continue
				
			# Higher LOD index = lower detail
			if i == 1:
				# Medium LOD
				mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				mesh_instance.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
			elif i == 2:
				# Far LOD - simplest
				mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				mesh_instance.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
				# Simplify materials if possible
				if mesh_instance.material_override:
					mesh_instance.material_override.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		
		# Add visibility notifier to control LOD switching
		var notifier = VisibleOnScreenNotifier3D.new()
		notifier.aabb = AABB(Vector3(-10, -10, -10), Vector3(20, 20, 20))
		lod_node.add_child(notifier)
		
		lod_parent.add_child(lod_node)
	
	return lod_parent
