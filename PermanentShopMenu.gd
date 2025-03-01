extends Control

# Permanent upgrade levels
var damage_mult_level: int = 0
var coin_mult_level: int = 0
var health_mult_level: int = 0
var regen_mult_level: int = 0

# Permanent upgrade costs
var damage_mult_cost: int = 5
var coin_mult_cost: int = 4
var health_mult_cost: int = 6
var regen_mult_cost: int = 6

# Permanent upgrade increments
var damage_mult_increment: float = 0.1
var coin_mult_increment: float = 0.1
var health_mult_increment: float = 0.1
var regen_mult_increment: float = 0.2

func _ready() -> void:
	# Initialize upgrade levels from CurrencyManager
	damage_mult_level = 0  # Would be loaded from save in a full implementation
	coin_mult_level = 0
	health_mult_level = 0
	regen_mult_level = 0
	
	# Update displays
	update_currency_display()
	update_upgrade_levels()
	
	# Connect buttons
	setup_upgrade_buttons()
	$Panel/VBoxContainer/CloseButton.pressed.connect(_on_close_button_pressed)

func setup_upgrade_buttons() -> void:
	# Damage multiplier
	$Panel/VBoxContainer/UpgradesGrid/DamageMultPanel/VBoxContainer/BuyButton.pressed.connect(
		upgrade_damage_mult
	)
	
	# Coin multiplier
	$Panel/VBoxContainer/UpgradesGrid/CoinMultPanel/VBoxContainer/BuyButton.pressed.connect(
		upgrade_coin_mult
	)
	
	# Health multiplier
	$Panel/VBoxContainer/UpgradesGrid/HealthMultPanel/VBoxContainer/BuyButton.pressed.connect(
		upgrade_health_mult
	)
	
	# Regen multiplier
	$Panel/VBoxContainer/UpgradesGrid/RegenMultPanel/VBoxContainer/BuyButton.pressed.connect(
		upgrade_regen_mult
	)

func update_currency_display() -> void:
	$Panel/VBoxContainer/CurrencyDisplay/Bronze.text = "Bronze: %d" % CurrencyManager.bronze
	$Panel/VBoxContainer/CurrencyDisplay/Silver.text = "Silver: %d" % CurrencyManager.silver
	$Panel/VBoxContainer/CurrencyDisplay/Gold.text = "Gold: %d" % CurrencyManager.gold

func update_upgrade_levels() -> void:
	# Update level displays
	$Panel/VBoxContainer/UpgradesGrid/DamageMultPanel/VBoxContainer/Level.text = "Level: %d" % damage_mult_level
	$Panel/VBoxContainer/UpgradesGrid/CoinMultPanel/VBoxContainer/Level.text = "Level: %d" % coin_mult_level
	$Panel/VBoxContainer/UpgradesGrid/HealthMultPanel/VBoxContainer/Level.text = "Level: %d" % health_mult_level
	$Panel/VBoxContainer/UpgradesGrid/RegenMultPanel/VBoxContainer/Level.text = "Level: %d" % regen_mult_level

func upgrade_damage_mult() -> void:
	if CurrencyManager.gold >= damage_mult_cost:
		CurrencyManager.purchase(0, 0, damage_mult_cost)
		damage_mult_level += 1
		CurrencyManager.damage_multiplier += damage_mult_increment
		update_upgrade_levels()
		update_currency_display()

func upgrade_coin_mult() -> void:
	if CurrencyManager.gold >= coin_mult_cost:
		CurrencyManager.purchase(0, 0, coin_mult_cost)
		coin_mult_level += 1
		CurrencyManager.bronze_multiplier += coin_mult_increment
		update_upgrade_levels()
		update_currency_display()

func upgrade_health_mult() -> void:
	if CurrencyManager.gold >= health_mult_cost:
		CurrencyManager.purchase(0, 0, health_mult_cost)
		health_mult_level += 1
		CurrencyManager.max_health_multiplier += health_mult_increment
		update_upgrade_levels()
		update_currency_display()

func upgrade_regen_mult() -> void:
	if CurrencyManager.gold >= regen_mult_cost:
		CurrencyManager.purchase(0, 0, regen_mult_cost)
		regen_mult_level += 1
		CurrencyManager.health_regen_multiplier += regen_mult_increment
		update_upgrade_levels()
		update_currency_display()

func _on_close_button_pressed() -> void:
	queue_free()