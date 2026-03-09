class_name SpawnGroupResource
extends Resource

## Describes a group of enemies to spawn within a wave.
## delay_from_wave_start controls when this group begins spawning relative to wave launch.

@export var enemy_id: String = ""
@export var count: int = 1
@export var spawn_interval: float = 1.0
@export var delay_from_wave_start: float = 0.0
