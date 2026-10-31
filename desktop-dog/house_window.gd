extends Window

var drag_offset = Vector2i()
var moving = false
var move_offset = Vector2i.ZERO

func _input(event):
	_handle_move(event)
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if Events.dog_in_house == false:
				Events.house_call_dog.emit(Vector2(position) + Vector2(size / 2))
			elif Events.dog_in_house == true:
				Events.house_release_dog.emit()

func _handle_move(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		if event.pressed:
			move_offset = DisplayServer.mouse_get_position() - position
			moving = true
		else:
			moving = false
			
func _process(_delta: float) -> void:
	if moving:
		position = DisplayServer.mouse_get_position() - move_offset
		Events.house_moved.emit(Vector2(position) + Vector2(size / 2))
