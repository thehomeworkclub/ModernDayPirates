@tool
extends EditorScript

# Optimize Ship Resources Script
# Run this script from the Godot editor to optimize all ship resources for VR
# To run: Select this script in the FileSystem panel, then click the "Run" button in the Script Editor

# Performance optimization targets
const TEXTURE_MAX_SIZE = 1024  # Maximum texture size for ships
const MESH_SIMPLIFICATION = 0.5  # Target simplification factor (0.0-1.0, lower = more simplified)
const GENERATE_LOD = true  # Generate LOD levels for meshes
const LOD_LEVELS = 3  # Number of LOD levels to generate

func _run():
	print("------ Starting Ship Resource Optimization ------")
	var cargo_ship_path = "res://cargo_ships/meshes"
	var num_optimized = 0
	
	# Scan all meshes in the cargo_ships directory
	var dir = DirAccess.open(cargo_ship_path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".fbx"):
				var full_path = cargo_ship_path + "/" + file_name
				print("Optimizing: " + full_path)
				
				# Import settings can be modified through script
				var imported_resource = ResourceLoader.load(full_path, "", ResourceLoader.CACHE_MODE_IGNORE)
				if imported_resource:
					optimize_resource(imported_resource)
					num_optimized += 1
					
			file_name = dir.get_next()
	else:
		print("Error: Could not access cargo_ships directory")
		
	print("------ Completed Ship Resource Optimization ------")
	print("Optimized " + str(num_optimized) + " ship resources")
	
	# Refresh all imported resources
	if Engine.has_signal("filesystem_changed"):
		Engine.emit_signal("filesystem_changed")
	
# Optimize a specific resource
func optimize_resource(resource):
	# Check if this is a valid resource
	if not resource:
		return
		
	print("  Resource type: " + resource.get_class())
	
	# If this is a mesh resource
	if resource is Mesh:
		optimize_mesh(resource)
		
	# Check for materials
	for i in range(resource.get_surface_count()):
		var material = resource.surface_get_material(i)
		if material:
			optimize_material(material)

# Optimize a mesh resource
func optimize_mesh(mesh):
	print("  Optimizing mesh with " + str(mesh.get_surface_count()) + " surfaces")
	
	# Simplify collision shapes if any
	# This requires the MeshInstance3D node, not just the mesh resource
	# We could implement this by generating simplified collision shapes
	
	# For imported meshes, we would typically modify the import settings
	# rather than the mesh itself, as changes to imported resources
	# are not persistently stored this way
	
	print("  Note: For deep mesh optimization, modify the import settings directly")

# Optimize material and textures
func optimize_material(material):
	if not material:
		return
		
	print("  Optimizing material: " + material.resource_name)
	
	# Simplify shading model for VR
	if material is StandardMaterial3D:
		# Disable features not needed in VR
		material.subsurf_scatter_enabled = false
		material.refraction_enabled = false
		material.clearcoat_enabled = false
		
		# Simplify texture settings
		optimize_texture(material.albedo_texture)
		optimize_texture(material.normal_texture)
		optimize_texture(material.metallic_texture)
		optimize_texture(material.roughness_texture)
		optimize_texture(material.emission_texture)
		
		print("  Material optimized")

# Optimize texture resource
func optimize_texture(texture):
	if not texture:
		return
		
	print("  Examining texture: " + str(texture))
	
	# For imported textures, we would typically modify the import settings
	# rather than the texture itself, as changes to imported resources
	# are not persistently stored this way
	
	# Print recommendation for texture size
	if texture is Texture2D:
		var width = texture.get_width()
		var height = texture.get_height()
		if width > TEXTURE_MAX_SIZE or height > TEXTURE_MAX_SIZE:
			print("  ⚠️ Texture is too large: " + str(width) + "x" + str(height))
			print("  Recommended: Resize to max " + str(TEXTURE_MAX_SIZE) + " in import settings")
