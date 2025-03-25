extends Node3D

signal item_selected(item_name: String)
signal tab_selected(tab_name: String)

@onready var bronze_shop = $ShopBackgrounds/BronzeShop
@onready var silver_shop = $ShopBackgrounds/SilverShop
@onready var gold_shop = $ShopBackgrounds/GoldShop

# Controller and visualization references
var right_controller: XRController3D = null
var left_controller: XRController3D = null 
var right_ray: RayCast3D = null
var left_ray: RayCast3D = null
var right_laser_dot: MeshInstance3D = null
var left_laser_dot: MeshInstance3D = null
var ray_length = 10.0
var normal_ray_color = Color(0, 0.5, 1, 0.6)  # Blue
var hover_ray_color = Color(0, 1, 0, 0.6)     # Green

var current_shop = "bronze"

func _ready():
	print("\n=== Shop Menu Initializing ===")
	
	# Initialize VR controllers
	right_controller = $XROrigin3D/XRController3DRight
	left_controller = $XROrigin3D/XRController3DLeft

	if right_controller:
		print("Found right controller")
		right_controller.button_pressed.connect(_on_button_pressed.bind("right"))
		right_ray = right_controller.get_node("RayCastRight")
		right_laser_dot = right_controller.get_node("LaserDotRight")
		
		if right_ray:
			print("Found right raycast")
			right_ray.target_position = Vector3(0, 0, -ray_length)
			print("Right ray collision mask: " + str(right_ray.collision_mask))
			
		# Initialize right laser material
		var right_laser = right_controller.get_node("LaserBeamRight")
		if right_laser:
			var material = StandardMaterial3D.new()
			material.flags_transparent = true
			material.albedo_color = normal_ray_color
			material.emission_enabled = true
			material.emission = normal_ray_color
			material.emission_energy = 2.0
			right_laser.material_override = material
			print("Initialized right laser material")

	if left_controller:
		print("Found left controller")
		left_controller.button_pressed.connect(_on_button_pressed.bind("left"))
		left_ray = left_controller.get_node("RayCastLeft")
		left_laser_dot = left_controller.get_node("LaserDotLeft")
		
		if left_ray:
			print("Found left raycast")
			left_ray.target_position = Vector3(0, 0, -ray_length)
			print("Left ray collision mask: " + str(left_ray.collision_mask))
			
		# Initialize left laser material
		var left_laser = left_controller.get_node("LaserBeamLeft")
		if left_laser:
			var material = StandardMaterial3D.new()
			material.flags_transparent = true
			material.albedo_color = normal_ray_color
			material.emission_enabled = true
			material.emission = normal_ray_color
			material.emission_energy = 2.0
			left_laser.material_override = material
			print("Initialized left laser material")
			
	# Initialize shop state
	change_shop("bronze")

func _on_button_pressed(button_name: String, controller: String):
	if button_name != "trigger_click":
		return
		
	var raycast = get_node("XROrigin3D/XRController3D" + controller.capitalize() + "/RayCast" + controller.capitalize())
	if !raycast.is_colliding():
		return
		
	var collider = raycast.get_collider()
	if !collider or !collider.is_in_group("button"):
		return
		
	handle_button_press(collider)

func handle_button_press(button: Node):
	var button_name = button.name
	var parent_name = button.get_parent().name
	
	if parent_name == "TabBoundingBoxes":
		match button_name:
			"BronzeTab":
				change_shop("bronze")
			"SilverTab":
				change_shop("silver")
			"GoldTab":
				change_shop("gold")
		emit_signal("tab_selected", button_name)
	elif parent_name == "ItemBoundingBoxes":
		emit_signal("item_selected", button_name)

func change_shop(shop_type: String):
	current_shop = shop_type
	
	# Hide all shops
	bronze_shop.visible = false
	silver_shop.visible = false
	gold_shop.visible = false
	
	# Show selected shop
	match shop_type:
		"bronze":
			bronze_shop.visible = true
		"silver":
			silver_shop.visible = true
		"gold":
			gold_shop.visible = true

func _physics_process(_delta):
	update_laser_pointers()

func update_laser_pointers():
	# Update right controller laser
	if right_ray and right_laser_dot:
		var right_laser = right_controller.get_node("LaserBeamRight")
		if right_laser:
			var material = right_laser.material_override
			if material:
				if right_ray.is_colliding():
					var collision_point = right_ray.get_collision_point()
					var collider = right_ray.get_collider()
					
					right_laser_dot.global_position = collision_point
					right_laser_dot.visible = true
					
					if collider and collider.is_in_group("button"):
						material.albedo_color = hover_ray_color
						material.emission = hover_ray_color
					else:
						material.albedo_color = normal_ray_color
						material.emission = normal_ray_color
				else:
					material.albedo_color = normal_ray_color
					material.emission = normal_ray_color
					right_laser_dot.visible = false

	# Update left controller laser
	if left_ray and left_laser_dot:
		var left_laser = left_controller.get_node("LaserBeamLeft")
		if left_laser:
			var material = left_laser.material_override
			if material:
				if left_ray.is_colliding():
					var collision_point = left_ray.get_collision_point()
					var collider = left_ray.get_collider()
					
					left_laser_dot.global_position = collision_point
					left_laser_dot.visible = true
					
					if collider and collider.is_in_group("button"):
						material.albedo_color = hover_ray_color
						material.emission = hover_ray_color
					else:
						material.albedo_color = normal_ray_color
						material.emission = normal_ray_color
				else:
					material.albedo_color = normal_ray_color
					material.emission = normal_ray_color
					left_laser_dot.visible = false
