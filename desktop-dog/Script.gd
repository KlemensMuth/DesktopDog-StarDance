extends Node2D

enum State {GETTING_TREAT, IN_HOUSE, WALKING, RUNNING_TO_BALL, IDLE, SLEEPING, RESTING, DRAGGED, RUNNING_TO_HOUSE}
var trick_done = false
var maybe_idle = 0
var maybe_sleep = 0
var sleep_timer = 0
var maybe_rest = 0
var rest_timer = 0
var idle_timer = 0.0
var state = State.WALKING
var speed = 125
var direction = Vector2(-1, 0)
var screen_size = Vector2()
var window_size = Vector2()
var exact_position = Vector2()
var max_x = 0.0
#Drag var
var drag_offset = Vector2()
#Vars for Running to Ball
var run_speed = 250
var arrive_distance = 0.1
var target_position = Vector2()
var has_ball = false
var idle_after_ball = 0

@onready  var animated_sprite = $AnimatedSprite2D
@onready var area = $Area2D

func _ready():
	animated_sprite.animation_finished.connect(_on_animation_finished)
	screen_size = Vector2(DisplayServer.screen_get_size())
	window_size = Vector2(DisplayServer.window_get_size())
	exact_position = Vector2(DisplayServer.window_get_position())
	animated_sprite.play(_anim("Walking"))
	max_x = screen_size.x - window_size.x
	area.input_event.connect(_on_area_input)
	Events.ball_dropped.connect(_on_ball_dropped)
	Events.ball_grabbed.connect(_on_ball_grabbed)
	Events.house_call_dog.connect(_on_house_call_dog)
	Events.house_release_dog.connect(_on_house_release_dog)
	Events.house_moved.connect(_new_house_pos)
	Events.treat_grabbed.connect(_treat_grabbed)
	Events.treat_moved.connect(_treat_pos)
	Events.treat_released.connect(_on_treat_released)
	
#Setting State
func _set_state(new_state):
	if state == new_state:
		return
	else:
		state = new_state
		match state:
			State.WALKING:
				animated_sprite.play(_anim("Walking"))
				exact_position = Vector2(DisplayServer.window_get_position())
			State.DRAGGED:
				animated_sprite.play(_anim("Sit"))
			State.RUNNING_TO_BALL:
				animated_sprite.play(_anim("Running"))
			State.IDLE:
				animated_sprite.play(_anim("Idle"))
			State.RESTING:
				animated_sprite.play(_anim("Lying"))
			State.SLEEPING:
				animated_sprite.play(_anim("Sleeping"))
			State.RUNNING_TO_HOUSE:
				animated_sprite.play(_anim("Running"))
			State.IN_HOUSE:
				pass
			State.GETTING_TREAT:
				animated_sprite.play(_anim("Sit"))

func _physics_process(delta: float) -> void:
	match state:
		State.WALKING:
			_do_walking(delta)
		State.DRAGGED:
			_do_dragged()
		State.RUNNING_TO_BALL:
			_do_running_to_ball(delta)
		State.IDLE:
			_do_idle(delta)
		State.RESTING:
			_do_resting(delta)
		State.SLEEPING:
			_do_sleeping(delta)
		State.RUNNING_TO_HOUSE:
			_do_running_to_house(delta)
		State.IN_HOUSE:
			_in_house()

func _on_animation_finished():
	if state == State.GETTING_TREAT:
		animated_sprite.play(_anim("Sit"))

func _on_treat_released():
	if state == State.GETTING_TREAT:
		direction.x = 1 if animated_sprite.flip_h else -1
		_set_state(State.WALKING)
		trick_done = false

func _treat_pos(pos: Vector2):
	if state != State.GETTING_TREAT:
		return
	var over_dog = Rect2(exact_position, window_size).has_point(pos)
	if over_dog and not trick_done:
		trick_done = true
		animated_sprite.play(_anim("Trick"))
	elif not over_dog:
		trick_done = false

func _treat_grabbed():
	if state != State.IN_HOUSE and state != State.DRAGGED:
		trick_done = false
		_set_state(State.GETTING_TREAT)
		
		

func _new_house_pos(pos: Vector2):
	target_position = pos - window_size / 5

func _in_house():
	Events.dog_in_house = true
	hide()

func _do_running_to_house(delta):
	var to_target = target_position - exact_position
	var distance = to_target.length()

	if distance <= arrive_distance:
		_set_state(State.IN_HOUSE)
		

	var step = min(run_speed * delta, distance)
	var dir = to_target / distance
	exact_position += dir * step
	DisplayServer.window_set_position(Vector2i(exact_position))

	if abs(dir.x) > 0.1:
		animated_sprite.flip_h = dir.x > 0

func _on_house_call_dog(pos: Vector2) -> void:
		target_position = pos - window_size / 5
		_set_state(State.RUNNING_TO_HOUSE)

func _on_house_release_dog():
	if state == State.IN_HOUSE:
		Events.dog_in_house = false
		_set_state(State.WALKING)
		exact_position = target_position
		direction.x = 1
		animated_sprite.flip_h = true
		show()
		

func _do_sleeping(delta):
	sleep_timer -= delta
	if sleep_timer <= 0:
		_set_state(State.WALKING)
	else:
		return

func _do_resting(delta):
	rest_timer -= delta
	if rest_timer <= 0:
		maybe_sleep = randf_range(0, 1)
		if maybe_sleep <= 0.2:
			_set_state(State.SLEEPING)
			sleep_timer = randf_range(10, 120)
		else:
			_set_state(State.WALKING)
	else:
		return
#Walking Around
func _do_walking(delta):
	exact_position.x += direction.x * speed * delta
	exact_position.x = clamp(exact_position.x, 0, screen_size.x - window_size.x)
	DisplayServer.window_set_position(Vector2i(exact_position))
	if exact_position.x == 0 or exact_position.x >= max_x:
		maybe_idle = randf_range(0, 1)
		if maybe_idle <= 0.2:
			idle_timer = randf_range(2, 5)
			_set_state(State.IDLE)
		direction.x *= -1
		animated_sprite.flip_h = direction.x > 0
#Idle
func _do_idle(delta):
	idle_timer -= delta
	if idle_timer <= 0:
		maybe_rest = randf_range(0, 1)
		if maybe_rest <= 0.4:
			_set_state(State.RESTING)
			rest_timer = randf_range(5, 30)
		else:
			_set_state(State.WALKING)
	else:
		return
		

#Dragging
func _do_dragged():
	exact_position = Vector2(DisplayServer.mouse_get_position()) - drag_offset
	DisplayServer.window_set_position(Vector2i(exact_position))
	
# Mouse Input
func _on_area_input(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_set_state(State.DRAGGED)
			drag_offset = Vector2(DisplayServer.mouse_get_position() - DisplayServer.window_get_position())
		elif event.button_index == MOUSE_BUTTON_RIGHT and has_ball:
			_take_ball()

## letting go of left mouse
func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed and state == State.DRAGGED:
			_set_state(State.WALKING)
			
func _on_ball_dropped(pos: Vector2) -> void:
	if state == State.DRAGGED or state == State.IN_HOUSE:
		return
	target_position = pos - window_size / 5
	target_position.x = clamp(target_position.x, 0, max_x)
	target_position.y = clamp(target_position.y, 0, screen_size.y - window_size.y)
	_set_state(State.RUNNING_TO_BALL)
	
func _do_running_to_ball(delta):
	var to_target = target_position - exact_position
	var distance = to_target.length()

	if distance <= arrive_distance:
		_pick_up_ball()
		idle_after_ball = randf_range(0, 1)
		if idle_after_ball <= 0.5:
			idle_timer = randf_range(1, 10)
		_set_state(State.IDLE)
		return

	var step = min(run_speed * delta, distance)
	var dir = to_target / distance
	exact_position += dir * step
	DisplayServer.window_set_position(Vector2i(exact_position))

	if abs(dir.x) > 0.1:
		animated_sprite.flip_h = dir.x > 0

func _pick_up_ball():
	has_ball = true
	direction = Vector2(1 if animated_sprite.flip_h else -1, 0)
	_set_state(State.WALKING)
	Events.ball_picked_up.emit()
	
func _on_ball_grabbed():
	if state == State.RUNNING_TO_BALL:
		direction = Vector2(1 if animated_sprite.flip_h else -1, 0)
		_set_state(State.WALKING)

func _take_ball():
	if has_ball:
		has_ball = false
		match state:
			State.WALKING:
				animated_sprite.play(_anim("Walking"))
		Events.ball_returned.emit()

	
#Changes Ball or no Ball-Animation
func _anim(base: String) -> String:
	return base + "_Ball" if has_ball else base
		

			
	

		
