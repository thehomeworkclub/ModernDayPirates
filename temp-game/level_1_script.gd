extends Node3D

@onready var scene = preload("res://player.tscn")

@onready var boss_enemy = preload("res://enemies/bosses/melee boss/Boss.tscn")
@onready var melee_enemy = preload("res://enemies/melee enemy/MeleeEnemy.tscn")
@onready var boss_spawn = $bossspawn
@onready var wave_center = $wave_center.global_position
@onready var wave_timer = $WaveTimer
signal wave_ended

# Called when the node enters the scene tree for the first time.
func _ready():
	var player = scene.instantiate()
	player.position = Vector3(1, 5, 1)
	add_child(player)
	wave_1()
	wave_ended.connect(_spawn_wave_2)
	boss_wave()
	
func boss_wave():
	var boss = boss_enemy.instantiate()
	boss.position = boss_spawn.global_position
	add_child(boss)

func wave_1():
	var state = {"died": 0}
	var positions = [
		Vector3(wave_center.x+5, wave_center.y, wave_center.z),
		wave_center,
		Vector3(wave_center.x-5, wave_center.y, wave_center.z)
		]
	spawn_melee_wave(positions, state, 3)
	

func _spawn_wave_2():
	wave_ended.disconnect(_spawn_wave_2)
	wave_ended.connect(_spawn_wave_3)
	var state = {"died": 0}
	var total = 3
	var positions = [
		Vector3(wave_center.x+5, wave_center.y, wave_center.z),
		wave_center,
		Vector3(wave_center.x-5, wave_center.y, wave_center.z)
		]
	spawn_ranged_wave(positions, state, total)
	print("second wave passed")

func _spawn_wave_3():
	wave_ended.disconnect(_spawn_wave_3)
	wave_ended.connect(_end_wave)
	var state = {"died": 0}
	var total = 5
	var positions_melee = [
		Vector3(wave_center.x+5, wave_center.y, wave_center.z),
		wave_center,
		Vector3(wave_center.x-5, wave_center.y, wave_center.z)
		]
	var positions_ranged = [
		Vector3(wave_center.x+3, wave_center.y, wave_center.z+4),
		Vector3(wave_center.x-3, wave_center.y, wave_center.z+4)
		]
	spawn_melee_wave(positions_melee, state, total)
	spawn_ranged_wave(positions_ranged, state, total)

		
func spawn_melee_wave(positions, death_count, total):
	for pos in positions:
		var enemy = GlobalVars.spawn_melee(Level1Vars, pos, self)
		enemy.enemy_died.connect(
			func():
				death_count.died += 1
				if death_count.died >= total:
					wave_ended.emit()
		)
func spawn_ranged_wave(positions, death_count, total):
	for pos in positions:
		var enemy = GlobalVars.spawn_ranged(Level1Vars, pos, self)
		enemy.enemy_died.connect(
			func():
				death_count.died += 1
				if death_count.died >= total:
					wave_ended.emit()
		)

func _end_wave():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	pass
