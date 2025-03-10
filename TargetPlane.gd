@tool
extends MeshInstance3D

# This script creates a visible target plane in the editor
# that will be used by the ShipPositioner to determine where ships will stop

@export var width: float = 40.0 : set = set_width
@export var depth: float = 30.0 : set = set_depth
@export var color: Color = Color(0.0, 0.5, 1.0, 0.2) : set = set_color
@export var visible_in_game: bool = false

func _ready():
	if not Engine.is_editor_hint():
		# Make invisible in game if requested
		if not visible_in_game:
			visible = false
	
	update_mesh()

func set_width(value: float):
	width = value
	update_mesh()

func set_depth(value: float):
	depth = value
	update_mesh()

func set_color(value: Color):
	color = value
	update_material()

func update_mesh():
	if !mesh or !(mesh is PlaneMesh):
		mesh = PlaneMesh.new()
	
	var plane_mesh = mesh as PlaneMesh
	plane_mesh.size = Vector2(width, depth)
	
	# This will ensure material gets created if needed
	update_material()

func update_material():
	if !material_override:
		material_override = StandardMaterial3D.new()
	
	material_override.albedo_color = color
	material_override.emission_enabled = true
	material_override.emission = Color(color.r, color.g, color.b, 0.5)
	material_override.emission_energy = 0.3
	material_override.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA