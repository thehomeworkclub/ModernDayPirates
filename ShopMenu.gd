extends Control

# Upgrade levels
var damage_level: int = 0
var coin_level: int = 0
var regen_level: int = 0
var health_level: int = 0

# Permanent upgrade levels
var damage_mult_level: int = 0
var coin_mult_level: int = 0
var health_mult_level: int = 0
var regen_mult_level: int = 0

# Weapon costs
var weapon_costs = {
	"standard": 0,
	"rapid": 25,
	"double": 40,
	"spread": 60,
	"power": 75
}

# Team upgrade costs
var damage_cost: int = 15
var coin_cost: int = 20
var regen_cost: int = 20
var health_cost: int = 20

# Permanent upgrade costs
var damage_mult_cost: int = 5
var coin_mult_cost: int = 4
var health_mult_cost: int = 6
var regen_mult_cost: int = 6

# Upgrade increments
var damage_increment: float = 0.1
var coin_increment: float = 0.15
var regen_increment: float = 1.0
var health_increment: float = 0.1

# Permanent upgrade increments
var damage_mult_increment: float = 0.1
var coin_mult_increment: float = 0.1
var health_mult_increment: float = 0.1
var regen_mult_increment: float = 0.2

func _ready() -> void:
	# Release mouse for UI interaction
	var player = get_tree().get_nodes_in_group("Player")
	if player.size() > 0 and player[0].has_method("release_mouse"):
		player[0].release_mouse()
	
	# Initialize UI
	update_currency_display()
	setup_weapon_buttons()
	setup_team_upgrade_buttons()
	setup_permanent_upgrade_buttons()
	
	# Connect continue button
	$Panel/CompleteButton.pressed.connect(_on_complete_button_pressed)

func setup_weapon_buttons() -> void:
	# Standard Gun
	$Panel/TabContainer/Weapons/VBoxContainer/WeaponGrid/StandardGun/VBoxContainer/BuyButton.pressed.connect(
		func(): buy_weapon("standard")
	)
	
	# Rapid Gun
	$Panel/TabContainer/Weapons/VBoxContainer/WeaponGrid/RapidGun/VBoxContainer/BuyButton.pressed.connect(
		func(): buy_weapon("rapid")
	)
	
	# Double Barrel
	$Panel/TabContainer/Weapons/VBoxContainer/WeaponGrid/DoubleGun/VBoxContainer/BuyButton.pressed.connect(
		func(): buy_weapon("double")
	)
	
	# Spread Shot
	$Panel/TabContainer/Weapons/VBoxContainer/WeaponGrid/SpreadGun/VBoxContainer/BuyButton.pressed.connect(
		func(): buy_weapon("spread")
	)
	
	# Power Cannon
	$Panel/TabContainer/Weapons/VBoxContainer/WeaponGrid/PowerGun/VBoxContainer/BuyButton.pressed.connect(
		func(): buy_weapon("power")
	)
	
	# Update button states based on current weapon
	update_weapon_buttons()

func setup_team_upgrade_buttons() -> void:
	# Damage upgrade
	$Panel/TabContainer/Team/VBoxContainer/UpgradeTree/DamagePanel/HBoxContainer/Button.pressed.connect(
		upgrade_damage
	)
	
	# Coin upgrade
	$Panel/TabContainer/Team/VBoxContainer/UpgradeTree/SecondTier/CoinPanel/VBoxContainer/Button.pressed.connect(
		upgrade_coin
	)
	
	# Regen upgrade
	$Panel/TabContainer/Team/VBoxContainer/UpgradeTree/SecondTier/RegenPanel/VBoxContainer/Button.pressed.connect(
		upgrade_regen
	)
	
	# Health upgrade
	$Panel/TabContainer/Team/VBoxContainer/UpgradeTree/SecondTier/HealthPanel/VBoxContainer/Button.pressed.connect(
		upgrade_health
	)
	
	# Update levels
	update_team_levels()

func setup_permanent_upgrade_buttons() -> void:
	# Damage multiplier
	$Panel/TabContainer/Permanent/VBoxContainer/PermanentGrid/DamageMultPanel/VBoxContainer/BuyButton.pressed.connect(
		upgrade_damage_mult
	)
	
	# Coin multiplier
	$Panel/TabContainer/Permanent/VBoxContainer/PermanentGrid/CoinMultPanel/VBoxContainer/BuyButton.pressed.connect(
		upgrade_coin_mult
	)
	
	# Health multiplier
	$Panel/TabContainer/Permanent/VBoxContainer/PermanentGrid/HealthMultPanel/VBoxContainer/BuyButton.pressed.connect(
		upgrade_health_mult
	)
	
	# Regen multiplier
	$Panel/TabContainer/Permanent/VBoxContainer/PermanentGrid/RegenMultPanel/VBoxContainer/BuyButton.pressed.connect(
		upgrade_regen_mult
	)
	
	# Set initial levels
	damage_mult_level = 0 # Will be loaded from save in a real implementation
	coin_mult_level = 0
	health_mult_level = 0
	regen_mult_level = 0
	
	# Update display
	update_permanent_levels()

func update_currency_display() -> void:
	$Panel/CurrencyDisplay/Bronze.text = "Bronze: %d" % CurrencyManager.bronze
	$Panel/CurrencyDisplay/Silver.text = "Silver: %d" % CurrencyManager.silver
	$Panel/CurrencyDisplay/Gold.text = "Gold: %d" % CurrencyManager.gold

func update_weapon_buttons() -> void:
	# Update all buttons
	var current_gun = GameManager.gun_type
	
	# Reset all buttons
	$Panel/TabContainer/Weapons/VBoxContainer/WeaponGrid/StandardGun/VBoxContainer/BuyButton.text = "Buy"
	$Panel/TabContainer/Weapons/VBoxContainer/WeaponGrid/RapidGun/VBoxContainer/BuyButton.text = "Buy"
	$Panel/TabContainer/Weapons/VBoxContainer/WeaponGrid/DoubleGun/VBoxContainer/BuyButton.text = "Buy"
	$Panel/TabContainer/Weapons/VBoxContainer/WeaponGrid/SpreadGun/VBoxContainer/BuyButton.text = "Buy"
	$Panel/TabContainer/Weapons/VBoxContainer/WeaponGrid/PowerGun/VBoxContainer/BuyButton.text = "Buy"
	
	# Set the equipped one
	match current_gun:
		"standard":
			$Panel/TabContainer/Weapons/VBoxContainer/WeaponGrid/StandardGun/VBoxContainer/BuyButton.text = "Equipped"
		"rapid":
			$Panel/TabContainer/Weapons/VBoxContainer/WeaponGrid/RapidGun/VBoxContainer/BuyButton.text = "Equipped"
		"double":
			$Panel/TabContainer/Weapons/VBoxContainer/WeaponGrid/DoubleGun/VBoxContainer/BuyButton.text = "Equipped"
		"spread":
			$Panel/TabContainer/Weapons/VBoxContainer/WeaponGrid/SpreadGun/VBoxContainer/BuyButton.text = "Equipped"
		"power":
			$Panel/TabContainer/Weapons/VBoxContainer/WeaponGrid/PowerGun/VBoxContainer/BuyButton.text = "Equipped"

func update_team_levels() -> void:
	# Update level displays
	$Panel/TabContainer/Team/VBoxContainer/UpgradeTree/DamagePanel/HBoxContainer/VBoxContainer/Level.text = "Level: %d" % damage_level
	$Panel/TabContainer/Team/VBoxContainer/UpgradeTree/SecondTier/CoinPanel/VBoxContainer/Level.text = "Level: %d" % coin_level
	$Panel/TabContainer/Team/VBoxContainer/UpgradeTree/SecondTier/RegenPanel/VBoxContainer/Level.text = "Level: %d" % regen_level
	$Panel/TabContainer/Team/VBoxContainer/UpgradeTree/SecondTier/HealthPanel/VBoxContainer/Level.text = "Level: %d" % health_level

func update_permanent_levels() -> void:
	# Update level displays
	$Panel/TabContainer/Permanent/VBoxContainer/PermanentGrid/DamageMultPanel/VBoxContainer/Level.text = "Level: %d" % damage_mult_level
	$Panel/TabContainer/Permanent/VBoxContainer/PermanentGrid/CoinMultPanel/VBoxContainer/Level.text = "Level: %d" % coin_mult_level
	$Panel/TabContainer/Permanent/VBoxContainer/PermanentGrid/HealthMultPanel/VBoxContainer/Level.text = "Level: %d" % health_mult_level
	$Panel/TabContainer/Permanent/VBoxContainer/PermanentGrid/RegenMultPanel/VBoxContainer/Level.text = "Level: %d" % regen_mult_level

func buy_weapon(weapon_type: String) -> void:
	# If already equipped, do nothing
	if GameManager.gun_type == weapon_type:
		return
		
	# Check if we can afford it
	var cost = weapon_costs[weapon_type]
	if CurrencyManager.bronze >= cost:
		# Purchase the weapon
		if cost > 0:
			CurrencyManager.purchase(cost, 0, 0)
		
		# Set as active weapon
		GameManager.gun_type = weapon_type
		
		# Update UI
		update_weapon_buttons()
		update_currency_display()
		
		# Update player's gun
		var player = get_tree().get_nodes_in_group("Player")
		if player.size() > 0:
			var gun = player[0].find_child("Gun", true)
			if gun and gun.has_method("set_gun_type"):
				gun.set_gun_type(weapon_type)

func upgrade_damage() -> void:
	if CurrencyManager.silver >= damage_cost:
		CurrencyManager.purchase(0, damage_cost, 0)
		damage_level += 1
		GameManager.damage_bonus += damage_increment
		update_team_levels()
		update_currency_display()

func upgrade_coin() -> void:
	if CurrencyManager.silver >= coin_cost:
		CurrencyManager.purchase(0, coin_cost, 0)
		coin_level += 1
		GameManager.coin_bonus += coin_increment
		update_team_levels()
		update_currency_display()

func upgrade_regen() -> void:
	if CurrencyManager.silver >= regen_cost:
		CurrencyManager.purchase(0, regen_cost, 0)
		regen_level += 1
		GameManager.health_regen += regen_increment
		update_team_levels()
		update_currency_display()

func upgrade_health() -> void:
	if CurrencyManager.silver >= health_cost:
		CurrencyManager.purchase(0, health_cost, 0)
		health_level += 1
		GameManager.max_health_bonus += health_increment
		
		# Update player boat health
		var player_boat = get_tree().get_nodes_in_group("Player")
		if player_boat.size() > 0 and player_boat[0].has_method("upgrade_max_health"):
			player_boat[0].upgrade_max_health(health_increment)
		
		update_team_levels()
		update_currency_display()

func upgrade_damage_mult() -> void:
	if CurrencyManager.gold >= damage_mult_cost:
		CurrencyManager.purchase(0, 0, damage_mult_cost)
		damage_mult_level += 1
		CurrencyManager.damage_multiplier += damage_mult_increment
		update_permanent_levels()
		update_currency_display()

func upgrade_coin_mult() -> void:
	if CurrencyManager.gold >= coin_mult_cost:
		CurrencyManager.purchase(0, 0, coin_mult_cost)
		coin_mult_level += 1
		CurrencyManager.bronze_multiplier += coin_mult_increment
		update_permanent_levels()
		update_currency_display()

func upgrade_health_mult() -> void:
	if CurrencyManager.gold >= health_mult_cost:
		CurrencyManager.purchase(0, 0, health_mult_cost)
		health_mult_level += 1
		CurrencyManager.max_health_multiplier += health_mult_increment
		
		# Update player boat health
		var player_boat = get_tree().get_nodes_in_group("Player")
		if player_boat.size() > 0 and player_boat[0].has_method("upgrade_max_health"):
			player_boat[0].upgrade_max_health(0) # Just recalculate with new multiplier
		
		update_permanent_levels()
		update_currency_display()

func upgrade_regen_mult() -> void:
	if CurrencyManager.gold >= regen_mult_cost:
		CurrencyManager.purchase(0, 0, regen_mult_cost)
		regen_mult_level += 1
		CurrencyManager.health_regen_multiplier += regen_mult_increment
		update_permanent_levels()
		update_currency_display()

func _on_complete_button_pressed() -> void:
	# Restore mouse capture for gameplay
	var player = get_tree().get_nodes_in_group("Player")
	if player.size() > 0 and player[0].has_method("capture_mouse"):
		player[0].capture_mouse()
	
	# Close shop and continue to next wave
	queue_free()
	GameManager.close_shop()