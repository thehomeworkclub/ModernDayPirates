extends Node3D

func _ready() -> void:
	$Label3D.position = Vector3.ZERO
	$Label3D.scale = Vector3(0.2, 0.2, 0.2)

func _process(_delta: float) -> void:
	$Label3D.text = "Voyage %d: %s\nDifficulty: %s\nRound: %d\nWave: %d" % [
		GameManager.current_voyage,
		GameManager.voyage_name,
		GameManager.difficulty,
		GameManager.current_round, 
		GameManager.current_wave
	]
