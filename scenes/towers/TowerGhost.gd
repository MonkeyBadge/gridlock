extends Node3D

@onready var _mesh: MeshInstance3D = $Mesh
@export var material_valid: StandardMaterial3D
@export var material_invalid: StandardMaterial3D


func set_valid(is_valid: bool) -> void:
	_mesh.material_override = material_valid if is_valid else material_invalid
