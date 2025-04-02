extends Node3D

@onready var anim_player = $AnimationPlayer
# Called when the node enters the scene tree for the first time.
func _ready():
	anim_player.get_animation("passive").loop_mode = Animation.LOOP_LINEAR
	anim_player.play("passive")
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
