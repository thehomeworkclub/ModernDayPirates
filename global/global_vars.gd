extends Node

func spawn_melee(level_vars, position, parent):
    if !ResourceLoader.exists("res://enemies/melee enemy/MeleeEnemy.tscn"):
        print("ERROR: MeleeEnemy.tscn not found")
        return null
        
    var enemy_scene = load("res://enemies/melee enemy/MeleeEnemy.tscn")
    if enemy_scene:
        var enemy = enemy_scene.instantiate()
        if enemy:
            # Apply level variables if available
            if level_vars:
                if "enemy_health" in level_vars:
                    enemy.hp = level_vars.enemy_health
                if "enemy_speed" in level_vars:
                    enemy.speed = level_vars.enemy_speed
            
            enemy.position = position
            parent.add_child(enemy)
            print("Spawned melee enemy at: ", position)
            return enemy
    
    print("ERROR: Failed to spawn melee enemy")
    return null
