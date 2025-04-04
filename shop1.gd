extends Node3D

@onready var bronze_currency = $CurrencyViewport/MarginContainer/HBoxContainer/BronzeCurrency
@onready var silver_currency = $CurrencyViewport/MarginContainer/HBoxContainer/SilverCurrency
@onready var gold_currency = $CurrencyViewport/MarginContainer/HBoxContainer/GoldCurrency

@onready var bronze_shop = $ShopBackgrounds/BronzeShop
@onready var silver_shop = $ShopBackgrounds/SilverShop
@onready var gold_shop = $ShopBackgrounds/GoldShop

var current_shop = "bronze"
var right_controller
var left_controller
var right_ray
var left_ray
var right_laser_dot
var left_laser_dot

const MAX_LEVEL = 10
const BASE_PRICE = 10
const CURVE_FACTOR = 1.5

# Fixed prices for bronze menu (guns)
const BRONZE_PRICES = {
    "ItemBox1": 50,   # M16A1 (Default)
    "ItemBox2": 100,  # AK74
    "ItemBox3": 150,  # SCAR-L
    "ItemBox4": 200,  # HK416
    "ItemBox5": 250,  # MP5
    "ItemBox6": 300   # Mosin/Model1897
}

var normal_ray_color = Color(0, 0.5, 1, 0.6)
var hover_ray_color = Color(0, 1, 1, 0.8)
var bronze_color = Color(0.87, 0.443, 0, 1)
var silver_color = Color(0.75, 0.75, 0.75, 1)
var gold_color = Color(1, 0.843, 0, 1)

# Using upgrade levels from GameManager that persist between shop visits
# and only reset when the player dies

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
	elif parent_name == "ItemBoundingBoxes":
		try_upgrade_item(button_name)

func get_current_levels():
	match current_shop:
		"bronze":
			return GameManager.bronze_upgrade_levels
		"silver":
			return GameManager.silver_upgrade_levels
		"gold":
			return GameManager.gold_upgrade_levels
	return GameManager.bronze_upgrade_levels  # Default fallback

func calculate_price(level: int) -> int:
	var price = BASE_PRICE * pow(CURVE_FACTOR, level - 1)
	return roundi(price)

func try_upgrade_item(item_name: String):
	var levels = get_current_levels()
	var currency_manager = get_node("/root/CurrencyManager")
	var purchased = false
	
	match current_shop:
		"bronze":
			# Special handling for bronze shop (guns)
			# Only one gun can be selected at a time
			
			# If this item is already selected (level 1), do nothing
			if levels[item_name] == 1:
				print("Gun already selected")
				return
				
			# Check if we can afford this gun
			var price = BRONZE_PRICES[item_name]
			purchased = currency_manager.purchase(price, 0, 0)
			
			if purchased:
				# Reset all gun levels to 0
				for key in levels.keys():
					levels[key] = 0
				
				# Set selected gun to level 1
				levels[item_name] = 1
				
				# Update GameManager's gun type
				var gun_type = GameManager.gun_types_map[item_name]
				print("Switching to gun: " + gun_type)
				
				# Find VRGunController in the game and set the gun
				var controller = get_tree().get_first_node_in_group("Player")
				if controller:
					var gun_controller = controller.get_node_or_null("VRGunController")
					if gun_controller and gun_controller.has_method("switch_gun"):
						gun_controller.switch_gun(gun_type)
						print("Gun switched successfully to: " + gun_type)
			
				# Update all price labels and the display
				update_all_price_labels()
				update_currency_display()
		
		"silver":
			# Normal upgrade for silver shop
			if levels[item_name] >= MAX_LEVEL:
				print("Item already at max level")
				return
				
			var price = calculate_price(levels[item_name])
			purchased = currency_manager.purchase(0, price, 0)
			
			if purchased:
				levels[item_name] += 1
				update_item_display(item_name)
				update_currency_display()
				
		"gold":
			# Normal upgrade for gold shop
			if levels[item_name] >= MAX_LEVEL:
				print("Item already at max level")
				return
				
			var price = calculate_price(levels[item_name])
			purchased = currency_manager.purchase(0, 0, price)
			
			if purchased:
				levels[item_name] += 1
				update_item_display(item_name)
				update_currency_display()

func update_currency_display():
	var currency_manager = get_node("/root/CurrencyManager")
	var bronze = currency_manager.get_bronze()
	var silver = currency_manager.get_silver()
	var gold = currency_manager.get_gold()
	
	# Update the viewport labels
	if bronze_currency and silver_currency and gold_currency:
		bronze_currency.text = str(bronze)
		silver_currency.text = str(silver)
		gold_currency.text = str(gold)
		
		# Force viewport update
		$CurrencyViewport.render_target_update_mode = SubViewport.UPDATE_ONCE

func update_item_display(item_name: String):
	var levels = get_current_levels()
	var label = get_node("ItemBoundingBoxes/" + item_name + "/Label3D")
	var price_label = get_node("ItemBoundingBoxes/" + item_name + "/PriceLabel")

	if label and price_label:
		if current_shop == "bronze":
			# Bronze shop items are gun selections (0 = not selected, 1 = selected)
			if levels[item_name] == 1:
				# Selected gun
				label.text = "✓"
				price_label.text = "EQUIPPED"
				price_label.modulate = Color(0, 0.5, 0, 1)  # Green for equipped
			else:
				# Available to purchase
				label.text = ""
				price_label.text = "$" + str(BRONZE_PRICES[item_name])
				price_label.modulate = Color(0, 0, 0, 1)  # Black for price
		else:
			# Silver and Gold shops use normal upgrade levels (1-10)
			label.text = str(levels[item_name])
			if levels[item_name] < MAX_LEVEL:
				price_label.text = "$" + str(calculate_price(levels[item_name]))
				price_label.modulate = Color(0, 0, 0, 1)  # Keep price label black
			else:
				price_label.text = "MAX"
				price_label.modulate = Color(0, 0, 0, 1)  # Keep MAX text black

func update_all_price_labels():
	var levels = get_current_levels()
	for item_name in levels.keys():
		update_item_display(item_name)
		
	# For bronze shop, update the VRGunController with the currently selected gun
	if current_shop == "bronze":
		# Find selected gun
		var selected_gun = ""
		for item_name in levels.keys():
			if levels[item_name] == 1:
				selected_gun = GameManager.gun_types_map[item_name]
				break
				
		if selected_gun != "":
			# Find VRGunController in the game and set the gun
			var controller = get_tree().get_first_node_in_group("Player")
			if controller:
				var gun_controller = controller.get_node_or_null("VRGunController")
				if gun_controller and gun_controller.has_method("switch_gun"):
					gun_controller.switch_gun(selected_gun)
					print("Initial gun set to: " + selected_gun)

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
