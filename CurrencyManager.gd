extends Node

# Currency values
var bronze: int = 0
var silver: int = 0
var gold: int = 0

# Multipliers (from permanent upgrades)
var bronze_multiplier: float = 1.0
var silver_multiplier: float = 1.0
var gold_multiplier: float = 1.0

# Permanent upgrade values
var damage_multiplier: float = 1.0
var health_regen_multiplier: float = 1.0
var max_health_multiplier: float = 1.0

# Getter functions
func get_silver() -> int:
    return silver

func get_bronze() -> int:
    return bronze
    
func get_gold() -> int:
    return gold

# Reset temporary currency (for each campaign)
func reset_temp_currency() -> void:
    bronze = 0
    silver = 0

# Reset all currency (for new game)
func reset_all_currency() -> void:
    bronze = 0
    silver = 0
    gold = 0

# Add bronze currency (from killing enemies)
func add_bronze(amount: int) -> void:
    bronze += int(amount * bronze_multiplier)

# Add silver currency (from completing waves)
func add_silver(amount: int) -> void:
    silver += int(amount * silver_multiplier)

# Add gold currency (from completing waves quickly)
func add_gold(amount: int, time_percent: float) -> void:
    # time_percent is between 0.0 and 1.0, represents how close to target time
    # 1.0 = completed in target time or faster (max gold)
    # 0.0 = took twice the target time or longer (min gold)
    var adjusted_amount = int(amount * time_percent * gold_multiplier)
    gold += max(1, adjusted_amount) # Always give at least 1 gold

# Check if the player can afford an upgrade
func can_afford(bronze_cost: int, silver_cost: int, gold_cost: int) -> bool:
    return bronze >= bronze_cost and silver >= silver_cost and gold >= gold_cost

# Purchase an upgrade
func purchase(bronze_cost: int, silver_cost: int, gold_cost: int) -> bool:
    if can_afford(bronze_cost, silver_cost, gold_cost):
        bronze -= bronze_cost
        silver -= silver_cost
        gold -= gold_cost
        return true
    return false
