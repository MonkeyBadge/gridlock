class_name GridCell

## Represents a single cell in the logical grid.
## This is a plain GDScript object (not a Resource) held in arrays by GridManager.
## passable is derived automatically from state via the state setter.

enum State { EMPTY, TOWER, STATIC_OBJECT, SPAWN, EXIT }

var position: Vector2i = Vector2i(0, 0)
var passable: bool = true

var _state: State = State.EMPTY

var state: State:
	get:
		return _state
	set(value):
		_state = value
		# Derive passable from state
		passable = (value == State.EMPTY or value == State.SPAWN or value == State.EXIT)
