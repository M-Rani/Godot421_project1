## player.gd

class_name Player
extends CharacterBody2D

########################################################################################################################
### Movement settings and functions
########################################################################################################################

@export_category("Movement Settings")
@export var move_default_speed := 300.0
@export var move_default_acceleration := 50.0
@export var move_default_friction := 50.0

func get_input_direction():
	return Input.get_axis("move_left", "move_right")

func movement():
	var direction = get_input_direction()
	if is_on_floor():
		if direction != 0:
			velocity.x = move_toward(velocity.x, move_default_speed * direction, move_default_acceleration)
		else:
			velocity.x = move_toward(velocity.x, 0, move_default_friction)
	else:
		if direction != 0:
			velocity.x = move_toward(velocity.x, move_default_speed * direction, move_default_acceleration / 4)
		else:
			velocity.x = move_toward(velocity.x, 0, move_default_friction / 4)

########################################################################################################################
### Jumping settings and options
########################################################################################################################

@export_category("Jump Settings")
@export var jump_height := 100.0
@export var jump_time_to_peak := 0.5
@export var jump_time_to_descent := 0.4

@onready var jump_velocity : float = ((2.0 * jump_height) / jump_time_to_peak) * -1.0
@onready var jump_gravity : float = ((-2.0 * jump_height) / (jump_time_to_peak * jump_time_to_peak)) * -1.0
@onready var fall_gravity : float = ((-2.0 * jump_height) / (jump_time_to_descent * jump_time_to_descent)) * -1.0

func get_gravity() -> float:
	return jump_gravity if velocity.y < 0.0 else fall_gravity

func jump():
	velocity.y = jump_velocity

########################################################################################################################
### State handling
########################################################################################################################

enum STATE { WALK_RIGHT, WALK_LEFT, IDLE, WALL_HUG, JUMP }
var current_state : STATE
var previous_state : STATE

########################################################################################################################
### Physics Process
########################################################################################################################

@onready var sprite = $Sprite2D

func _physics_process(delta):
	movement()

	if velocity.x > 0:
		sprite.flip_h = false
		sprite.offset = Vector2(0, 0)
	elif velocity.x < 0:
		sprite.flip_h = true
		sprite.offset = Vector2(0, 0)

	if Input.is_action_just_pressed("jump") and is_on_floor():
		jump()


	# Apply velocity to player
	velocity.y += get_gravity() * delta
	move_and_slide()
