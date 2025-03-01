extends Area3D

@export var base_health: int = 10
var max_health: int
var health: int
var enemies_in_range: int = 0
var damage_timer: float = 0.0

func _ready() -> void:
	add_to_group("Player")
	
	# Calculate max health with any permanent upgrades
	max_health = int(base_health * (1.0 + GameManager.max_health_bonus) * CurrencyManager.max_health_multiplier)
	health = max_health
	
	monitoring = true
	monitorable = true
	connect("area_entered", self._on_area_entered)
	connect("area_exited", self._on_area_exited)

func _physics_process(delta: float) -> void:
	if enemies_in_range > 0:
		damage_timer += delta
		if damage_timer >= 1.0:
			take_damage(1)
			damage_timer = 0.0

func take_damage(amount: int) -> void:
	health -= amount
	if health <= 0:
		# Game over!
		health = 0
		get_tree().paused = true
		# Show game over UI
		var game_over_scene = load("res://GameOverMenu.tscn")
		if game_over_scene:
			var game_over_instance = game_over_scene.instantiate()
			get_tree().current_scene.add_child(game_over_instance)
		else:
			# Fallback if game over scene doesn't exist yet
			get_tree().change_scene_to_file("res://CampaignMenu.tscn")

func heal(amount: float) -> void:
	var heal_amount = int(amount)
	health = min(health + heal_amount, max_health)

func upgrade_max_health(bonus: float) -> void:
	max_health = int(base_health * (1.0 + GameManager.max_health_bonus + bonus) * CurrencyManager.max_health_multiplier)
	# Also heal when max health increases
	health += int(base_health * bonus * CurrencyManager.max_health_multiplier)
	health = min(health, max_health)

func _on_area_entered(area: Area3D) -> void:
	if area.is_in_group("Enemy"):
		enemies_in_range += 1

func _on_area_exited(area: Area3D) -> void:
	if area.is_in_group("Enemy"):
		enemies_in_range -= 1
