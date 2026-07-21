@tool
extends Resource
class_name PlantData
## Data-only description of a plant type. One resource per plant species
## (Sunflower, Peashooter, WallNut, CherryBomb...). Keeping stats in a
## Resource instead of hard-coding them per-scene avoids duplicated code:
## a single Plant.tscn + Plant.gd can represent every plant type.

@export var plant_name: String = "Plant"
@export var icon: Texture2D               ## Seed packet icon (UI).
@export var texture: Texture2D            ## In-world sprite (optional; placeholder shown if empty).

@export_group("Economy")
@export var cost: int = 50                ## Sun cost to place.
@export var cooldown: float = 5.0         ## Seconds before this seed packet can be used again.

@export_group("Combat")
@export var max_health: int = 100
@export var can_attack: bool = false
@export var attack_damage: int = 20
@export var attack_interval: float = 1.5  ## Seconds between shots.
@export var attack_range: float = 900.0   ## Pixels; effectively "rest of the lane".
@export var projectile_speed: float = 400.0
@export var attack_sound: AudioStream     ## Played per shot; falls back to AudioManager's generic "shoot" sfx if empty.

@export_group("Ammo")
@export var max_ammo: int = 0             ## 0 = unlimited ammo, no reload needed.
@export var reload_time: float = 5.0      ## Seconds to fully reload once ammo hits 0.

@export_group("Sun Production")
@export var produces_sun: bool = false
@export var sun_amount: int = 25
@export var sun_interval: float = 10.0

@export_group("Instant / Area Effect (Cherry Bomb style)")
@export var is_instant: bool = false      ## Explodes shortly after being planted, then removes itself.
@export var fuse_time: float = 1.0
@export var explosion_damage: int = 1800
@export var explosion_radius_cells: int = 1 ## Cells in each direction destroyed.
