@tool
extends CharacterBody3D
class_name Enemy

var hp = 100
var damage = 10
var speed = 5.0
var is_boss = false

func _ready():
	var node_name = get_name().to_lower()
	if "boss" in node_name:
		is_boss = true
		hp = 500
		damage = 25
		speed = 3.0

func take_damage(amount):
	hp -= amount
	if hp <= 0:
		if is_boss:
			print("Boss defeated!")
		queue_free()

func _physics_process(delta):
	# Basic movement - can be overridden by specific enemy types
	if !Engine.is_editor_hint():
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			var player = players[0]
			var direction = (player.global_position - global_position).normalized()
			velocity = direction * speed
			move_and_slide()
