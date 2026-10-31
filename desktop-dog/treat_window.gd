extends Window

var moving = false
var move_offset = Vector2i.ZERO

func _input(event):
	_handle_move(event)

func _handle_move(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			move_offset = DisplayServer.mouse_get_position() - position
			moving = true
			Events.treat_grabbed.emit()
		elif moving:
			moving = false
			Events.treat_released.emit()
			
			
func _process(_delta: float) -> void:
	if moving:
		position = DisplayServer.mouse_get_position() - move_offset
		Events.treat_moved.emit(Vector2(position) + Vector2(size /2 ))
