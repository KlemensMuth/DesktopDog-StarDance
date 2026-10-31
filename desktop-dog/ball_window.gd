extends Window

var dragging = false
var drag_offset = Vector2i()

func _input(event):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			drag_offset = DisplayServer.mouse_get_position() - position
			dragging = true
			Events.ball_grabbed.emit()
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			Events.ball_dropped.emit(Vector2(position) + Vector2(size) / 2)
			dragging = false

func _process(_delta: float) -> void:
	if dragging:
		position = DisplayServer.mouse_get_position() - drag_offset
		
func _ready():
	Events.ball_picked_up.connect(_on_ball_picked_up)
	Events.ball_returned.connect(_on_ball_returned)

func _on_ball_picked_up():
	if not dragging:
		hide()
		
func _on_ball_returned():
	position = DisplayServer.mouse_get_position() - Vector2i(size) / 2
	show()
