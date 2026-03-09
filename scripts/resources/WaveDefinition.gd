class_name WaveDefinition
extends Resource

## Defines a single wave's composition and timing.
## groups contains ordered SpawnGroupResource entries that describe what enemies spawn and when.

@export var wave_number: int = 1
@export var groups: Array[SpawnGroupResource] = []
@export var inter_wave_delay: float = 10.0


func get_total_enemy_count() -> int:
	var total: int = 0
	for group in groups:
		total += group.count
	return total
