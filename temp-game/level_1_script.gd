extends Node3D

@onready var scene = preload("res://player.tscn")

@onready var boss_enemy = preload("res://enemies/bosses/melee boss/boss.tscn")
@onready var melee_enemy = preload("res://enemies/melee enemy/MeleeEnemy.tscn")
@onready var boss_spawn = $bossspawn
@onready var wave_center = $wave_center.global_position
# Called when the node enters the scene tree for the first time.
func _ready():
	var player = scene.instantiate()
	player.position = Vector3(1, 5, 1)
	add_child(player)
	wave_1()
	boss_wave()
	
func boss_wave():
	var boss = boss_enemy.instantiate()
	boss.position = boss_spawn.global_position
	add_child(boss)

func wave_1():
	GlobalVars.spawn_melee(Level1Vars, wave_center, self)
	GlobalVars.spawn_melee(
		Level1Vars, 
		Vector3(wave_center.x+5, wave_center.y, wave_center.z), 
		self
		)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	pass
