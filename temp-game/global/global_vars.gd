extends Node
@onready var melee_enemy = preload("res://enemies/melee enemy/MeleeEnemy.tscn")
@onready var ranged_enemy = preload("res://enemies/ranged enemy/ranged enemy.tscn")

func spawn_enemy(enemy: PackedScene, damage: int, health: int, position: Vector3, scene) -> Enemy:
	var enemy_instance = enemy.instantiate()
	scene.add_child(enemy_instance)
	enemy_instance.global_position = position
	var enemy_class: Enemy = enemy_instance as Enemy
	enemy_class.base_damage = damage
	enemy_class.max_health = health
	return enemy_class
	


func spawn_melee(vars, position, scene) -> Enemy: 
	return spawn_enemy(melee_enemy, vars.melee_damage, vars.melee_damage, position, scene)
	
func spawn_ranged(vars, position, scene) -> Enemy:
	return spawn_enemy(ranged_enemy, vars.ranged_damage, vars.ranged_damage, position, scene)
	
	

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
