class_name MapDefinition
extends Resource

## Pure data container for a map configuration.
## Defines the grid dimensions, spawn/exit positions, and pre-placed static objects.
## Loaded by GridManager.initialize_from_map() to initialize the logical grid.

@export var map_name: String = ""
@export var map_display_name: String = ""
@export var grid_width: int = 20
@export var grid_height: int = 20

## At least one spawn cell per map. Enemies enter from these positions.
@export var spawn_positions: Array[Vector2i] = []

## The single exit position. Enemies that reach this cell deduct lives.
@export var exit_position: Vector2i = Vector2i(0, 0)

## Pre-placed static objects (rocks, ruins, terrain) that are impassable at load time.
## These are STATIC_OBJECT state, distinct from player-placed TOWER cells (ADR-07 / Risk 7).
@export var static_object_positions: Array[Vector2i] = []
