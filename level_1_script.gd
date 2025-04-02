extends Node3D

@onready var melee_enemy = preload("res://enemies/melee enemy/MeleeEnemy.tscn")
@onready var boss_spawn = $bossspawn
@onready var wave_center = $wave_center.global_position

var boss_enemy = null
@onready var xr_origin = $XROrigin3D

# Called when the node enters the scene tree for the first time.
func _ready():
	# Initialize VR
	var xr_interface = XRServer.find_interface("OpenXR")
	if xr_interface:
		xr_interface.initialize()
		get_viewport().use_xr = true

	# Set up VR position
	if xr_origin:
		xr_origin.position = Vector3(1, 1.8, 1)
		# Add VR origin to player group for enemy targeting
		xr_origin.add_to_group("player")
	else:
		print("ERROR: XROrigin3D not found")
		return

	# Start waves after setup
	wave_1()
	boss_wave()

func boss_wave():
	if ResourceLoader.exists("res://enemies/bosses/melee boss/boss.tscn"):
		if boss_enemy == null:
			boss_enemy = load("res://enemies/bosses/melee boss/boss.tscn")
		var boss = boss_enemy.instantiate()
		if boss_spawn:
			boss.position = boss_spawn.global_position
		else:
			print("WARNING: boss_spawn not found, using default position")
		add_child(boss)
	else:
		print("Boss scene not found, skipping boss wave")

func wave_1():
	if !is_instance_valid(GlobalVars):
		print("ERROR: GlobalVars not found")
		return
		
	if !is_instance_valid(Level1Vars):
		print("ERROR: Level1Vars not found")
		return
		
	if !wave_center:
		print("ERROR: wave_center not found")
		return
	
	var wave_data = Level1Vars.get_current_wave_data()
	var enemy_count = wave_data["enemy_count"]
	
	print("Spawning wave with " + str(enemy_count) + " enemies")
	
	for i in range(enemy_count):
		var offset = Vector3(
			(i - enemy_count/2.0) * 5.0, # Space enemies horizontally
			0,
			0
		)
		GlobalVars.spawn_melee(Level1Vars, wave_center + offset, self)
	
	# Advance to next wave
	Level1Vars.current_wave += 1
