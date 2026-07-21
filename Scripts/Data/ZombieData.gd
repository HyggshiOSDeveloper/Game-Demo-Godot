@tool
extends Resource
class_name ZombieData
## Data-only description of a zombie type. Same pattern as PlantData:
## one Zombie.tscn + Zombie.gd, many data variants (Basic, Conehead,
## Buckethead, Fast), so behaviour code is never duplicated.

@export var zombie_name: String = "Zombie"
@export var texture: Texture2D            ## In-world sprite (optional; placeholder shown if empty).

@export_group("Combat")
@export var max_health: int = 100         ## Base body health.
@export var armor_health: int = 0         ## Extra health layer (cone/bucket). Depletes first.
@export var attack_damage: int = 20
@export var attack_interval: float = 1.0  ## Seconds between bites while eating a plant.

@export_group("Movement")
@export var speed: float = 20.0           ## Pixels/second walking left.
