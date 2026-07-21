extends Node
## SunManager (autoload singleton "SunManager")
## Tracks the player's sun currency. Sun.gd (falling sun pickups) and
## Plant.gd (sunflowers) both call add_sun(); PlantManager calls
## try_spend() when the player plants something.

signal sun_changed(new_amount: int)

@export var starting_sun: int = 50
var sun: int = 0

func reset(amount: int = -1) -> void:
	sun = starting_sun if amount < 0 else amount
	sun_changed.emit(sun)

## Adds sun (from collected Sun pickups or sunflowers).
func add_sun(amount: int) -> void:
	sun += amount
	sun_changed.emit(sun)

## Returns true and deducts sun if the player can afford `cost`.
func try_spend(cost: int) -> bool:
	if sun < cost:
		return false
	sun -= cost
	sun_changed.emit(sun)
	return true

func can_afford(cost: int) -> bool:
	return sun >= cost
