extends Node3D

signal item_selected(item_name: String)
signal tab_selected(tab_name: String)

@onready var bronze_shop = $ShopBackgrounds/BronzeShop
@onready var silver_shop = $ShopBackgrounds/SilverShop
@onready var gold_shop = $ShopBackgrounds/GoldShop

# Shop configuration
const STARTING_CURRENCY = 100  # Starting amount for each currency type
const BASE_PRICE = 1          # Base price for level 1 upgrades
const CURVE_FACTOR = 1.5      # How steeply prices increase (adjust for different curves)
const MAX_LEVEL = 10          # Maximum upgrade level

# Currency tracking
var bronze_currency = STARTING_CURRENCY
var silver_currency = STARTING_CURRENCY
var gold_currency = STARTING_CURRENCY

# Currency colors
var bronze_color = Color(0.87, 0.443, 0.0)
var silver_color = Color(0.75, 0.75, 0.75)
var gold_color = Color(1.0, 0.843, 0.0)

# Controller and visualization references
var right_controller: XRController3D = null
var left_controller: XRController3D = null 
var right_ray: RayCast3D = null
var left_ray: RayCast3D = null
var right_laser_dot: MeshInstance3D = null
var left_laser_dot: MeshInstance3D = null
var normal_ray_color = Color(0, 0.5, 1, 0.6)  # Blue
var hover_ray_color = Color(0, 1, 0, 0.6)     # Green

var current_shop = "bronze"

# Bronze Shop Upgrades
var bronze_levels = {
	"ItemBox1": 1,  # Health
	"ItemBox2": 1,  # Speed
	"ItemBox3": 1,  # Damage
	"ItemBox4": 1,  # Fire Rate
	"ItemBox5": 1,  # Bullet Speed
	"ItemBox6": 1   # Special
}

# Silver Shop Upgrades
var silver_levels = {
	"ItemBox1": 1,  # Shield
	"ItemBox2": 1,  # Dash
	"ItemBox3": 1,  # Critical
	"ItemBox4": 1,  # Range
	"ItemBox5": 1,  # Spread
	"ItemBox6": 1   # Special
}

# Gold Shop Upgrades
var gold_levels = {
	"ItemBox1": 1,  # Regen
	"ItemBox2": 1,  # Bounce
	"ItemBox3": 1,  # Pierce
	"ItemBox4": 1,  # Multi
	"ItemBox5": 1,  # Homing
	"ItemBox6": 1   # Ultimate
}

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

	if left_controller:
		print("Found left controller")
		left_controller.button_pressed.connect(_on_button_pressed.bind("left"))
		left_ray = left_controller.get_node("RayCastLeft")
		left_laser_dot = left_controller.get_node("LaserDotLeft")
			
	# Initialize shop state
	change_shop("bronze")
	update_currency_display()
	update_all_price_labels()

func _on_button_pressed(button_name: String, controller: String):
	print("\nController Button Event: " + button_name)
	
	if button_name != "trigger_click":
		return
		
	print(controller + " trigger clicked")
	var raycast = get_node("XROrigin3D/XRController3D" + controller.capitalize() + "/RayCast" + controller.capitalize())
	if !raycast.is_colliding():
		return
		
	var collider = raycast.get_collider()
	print(controller + " ray hit: " + str(collider.name if collider else "None"))
	
	if !collider or !collider.is_in_group("button"):
		return
		
	print("Pressing button: " + collider.name)
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
		try_upgrade_item(button_name)
		emit_signal("item_selected", button_name)

func get_current_levels():
	match current_shop:
		"bronze":
			return bronze_levels
		"silver":
			return silver_levels
		"gold":
			return gold_levels
	return bronze_levels  # Default fallback

func calculate_price(level: int) -> int:
	# Logarithmic price scaling: BASE_PRICE * (CURVE_FACTOR)^(level-1)
	# Example progression with default values (BASE_PRICE=1, CURVE_FACTOR=1.5):
	# Level 1: 1
	# Level 2: 2
	# Level 3: 3
	# Level 4: 4
	# Level 5: 6
	# Level 6: 8
	# Level 7: 12
	# Level 8: 18
	# Level 9: 26
	# Level 10: 39
	var price = BASE_PRICE * pow(CURVE_FACTOR, level - 1)
	return roundi(price)  # Round to nearest integer

func try_upgrade_item(item_name: String):
	var levels = get_current_levels()
	if levels[item_name] >= MAX_LEVEL:
		print("Item already at max level")
		return
		
	var price = calculate_price(levels[item_name])
	
	match current_shop:
		"bronze":
			if bronze_currency >= price:
				bronze_currency -= price
				levels[item_name] += 1
				update_currency_display()
				update_item_display(item_name)
				print("Upgraded " + item_name + " to level " + str(levels[item_name]))
		"silver":
			if silver_currency >= price:
				silver_currency -= price
				levels[item_name] += 1
				update_currency_display()
				update_item_display(item_name)
				print("Upgraded " + item_name + " to level " + str(levels[item_name]))
		"gold":
			if gold_currency >= price:
				gold_currency -= price
				levels[item_name] += 1
				update_currency_display()
				update_item_display(item_name)
				print("Upgraded " + item_name + " to level " + str(levels[item_name]))

func update_currency_display():
	$CurrencyDisplay/BronzeCurrency.text = str(bronze_currency)
	$CurrencyDisplay/SilverCurrency.text = str(silver_currency)
	$CurrencyDisplay/GoldCurrency.text = str(gold_currency)

func update_item_display(item_name: String):
	var levels = get_current_levels()
	var label = get_node("ItemBoundingBoxes/" + item_name + "/Label3D")
	var price_label = get_node("ItemBoundingBoxes/" + item_name + "/PriceLabel")
	
	if label and price_label:
		label.text = str(levels[item_name])
		if levels[item_name] < MAX_LEVEL:
			price_label.text = "$" + str(calculate_price(levels[item_name]))
			match current_shop:
				"bronze":
					price_label.modulate = bronze_color
				"silver":
					price_label.modulate = silver_color
				"gold":
					price_label.modulate = gold_color
		else:
			price_label.text = "MAX"

func update_all_price_labels():
	var levels = get_current_levels()
	for item_name in levels.keys():
		update_item_display(item_name)

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
	
	# Update labels for the new shop
	update_all_price_labels()

func _physics_process(_delta):
	update_laser_pointers()

func update_laser_pointers():
	# Update right controller laser
	if right_ray and right_laser_dot:
		var right_laser = right_controller.get_node("LaserBeamRight")
		if right_laser and right_laser.material_override:
			if right_ray.is_colliding():
				var collision_point = right_ray.get_collision_point()
				var collider = right_ray.get_collider()
				
				right_laser_dot.global_position = collision_point
				right_laser_dot.visible = true
				
				if collider and collider.is_in_group("button"):
					right_laser.material_override.albedo_color = hover_ray_color
					right_laser.material_override.emission = hover_ray_color
				else:
					right_laser.material_override.albedo_color = normal_ray_color
					right_laser.material_override.emission = normal_ray_color
			else:
				right_laser.material_override.albedo_color = normal_ray_color
				right_laser.material_override.emission = normal_ray_color
				right_laser_dot.visible = false

	# Update left controller laser
	if left_ray and left_laser_dot:
		var left_laser = left_controller.get_node("LaserBeamLeft")
		if left_laser and left_laser.material_override:
			if left_ray.is_colliding():
				var collision_point = left_ray.get_collision_point()
				var collider = left_ray.get_collider()
				
				left_laser_dot.global_position = collision_point
				left_laser_dot.visible = true
				
				if collider and collider.is_in_group("button"):
					left_laser.material_override.albedo_color = hover_ray_color
					left_laser.material_override.emission = hover_ray_color
				else:
					left_laser.material_override.albedo_color = normal_ray_color
					left_laser.material_override.emission = normal_ray_color
			else:
				left_laser.material_override.albedo_color = normal_ray_color
				left_laser.material_override.emission = normal_ray_color
				left_laser_dot.visible = false
