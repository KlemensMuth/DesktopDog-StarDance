extends Node

var dog_in_house = false

signal ball_dropped(pos: Vector2)
signal ball_picked_up 
signal ball_grabbed
signal ball_returned
signal house_call_dog(pos: Vector2)
signal house_release_dog
signal house_moved(pos: Vector2)
signal treat_grabbed
signal treat_moved(pos: Vector2)
signal treat_released
