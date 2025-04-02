extends Node

# Enemy configuration
var enemy_count = 2
var enemy_health = 100
var enemy_speed = 5.0
var enemy_damage = 10

# Wave configuration
var waves = [
    {
        "enemy_count": 2,
        "enemy_health": 100,
        "enemy_speed": 5.0,
        "enemy_damage": 10
    },
    {
        "enemy_count": 3,
        "enemy_health": 150,
        "enemy_speed": 5.5,
        "enemy_damage": 15
    }
]

# Current wave tracking
var current_wave = 0

func get_current_wave_data():
    if current_wave < waves.size():
        return waves[current_wave]
    return waves[0]
