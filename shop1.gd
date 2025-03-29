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

var normal_ray_color = Color(0, 0.5, 1, 0.6)
var hover_ray_color = Color(0, 1, 1, 0.8)
var bronze_color = Color(0.87, 0.443, 0, 1)
var silver_color = Color(0.75, 0.75, 0.75, 1)
var gold_color = Color(1, 0.843, 0, 1)

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
            return bronze_levels
        "silver":
            return silver_levels
        "gold":
            return gold_levels
    return bronze_levels  # Default fallback

func calculate_price(level: int) -> int:
    var price = BASE_PRICE * pow(CURVE_FACTOR, level - 1)
    return roundi(price)

func try_upgrade_item(item_name: String):
    var levels = get_current_levels()
    if levels[item_name] >= MAX_LEVEL:
        print("Item already at max level")
        return

    var price = calculate_price(levels[item_name])
    var currency_manager = get_node("/root/CurrencyManager")

    match current_shop:
        "bronze":
            if currency_manager.bronze_currency >= price:
                currency_manager.bronze_currency -= price
                levels[item_name] += 1
                update_currency_display()
                update_item_display(item_name)
        "silver":
            if currency_manager.silver_currency >= price:
                currency_manager.silver_currency -= price
                levels[item_name] += 1
                update_currency_display()
                update_item_display(item_name)
        "gold":
            if currency_manager.gold_currency >= price:
                currency_manager.gold_currency -= price
                levels[item_name] += 1
                update_currency_display()
                update_item_display(item_name)

func update_currency_display():
    var currency_manager = get_node("/root/CurrencyManager")
    bronze_currency.text = str(currency_manager.bronze_currency)
    silver_currency.text = str(currency_manager.silver_currency)
    gold_currency.text = str(currency_manager.gold_currency)

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
