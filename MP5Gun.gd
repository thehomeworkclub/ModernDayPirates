extends "res://BaseRifleGun.gd"

# Animation reference
@onready var animation_player = $AnimationPlayer

func _ready() -> void:
	# Set MP5 specific properties
	gun_type = "mp5"
	fire_rate = 0.08  # Faster fire rate for SMG
	bullet_damage = 1  # Lower damage than rifles
	magazine_size = 30
	reload_time = 2.0  # Quick reload
	accuracy = 0.85  # Less accurate than rifles
	recoil = 0.12    # Low recoil due to smaller caliber
	automatic = true  # Fully automatic
	
	# Call parent _ready after setting properties
	super._ready()
	
	print_verbose("MP5 submachine gun initialized")

# Override shoot method to add recoil animation
func shoot() -> void:
	# Play recoil animation
	if animation_player != null and animation_player.has_animation("recoil"):
		animation_player.stop()
		animation_player.play("recoil")
	
	# Call the parent shoot method
	super.shoot()
