class_name EnemyDefinition
extends Resource

## Defines the properties of a single enemy type.
## Used by EnemyManager to spawn and render enemies via MultiMeshInstance3D.

@export var enemy_id: String = ""
@export var display_name: String = ""
@export var speed: float = 3.0
@export var scale: Vector3 = Vector3(1.0, 1.0, 1.0)
@export var mesh: Mesh = null
@export var position_jitter: float = 0.3
