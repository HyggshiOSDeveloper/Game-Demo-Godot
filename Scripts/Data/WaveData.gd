@tool
extends Resource
class_name WaveData
## Describes a single zombie wave: which zombies spawn, how many, how
## spread out in time. WaveManager consumes an Array[WaveData].

@export var zombies: Array[ZombieData] = []   ## Pool of zombie types this wave can use.
@export var zombie_count: int = 8             ## Total zombies to spawn this wave.
@export var spawn_interval: float = 2.5       ## Seconds between individual spawns.
@export var is_flag_wave: bool = false        ## "A huge wave is approaching!" banner wave.
