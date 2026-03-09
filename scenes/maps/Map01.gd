extends Node3D

## Map01 scene script.
## Loads the map_01 MapDefinition resource and initializes the GridManager.
## Must be the first thing called so all other systems see a valid grid.

@export var map_definition: MapDefinition


func _ready() -> void:
	if map_definition == null:
		push_error("Map01: map_definition is not assigned. Assign res://data/maps/map_01/map_01.tres in the Inspector.")
		return

	GridManager.initialize_from_map(map_definition)
	FlowFieldManager.recompute()
