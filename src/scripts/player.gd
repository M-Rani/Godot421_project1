## player.gd

class_name Player
extends CharacterBody2D

########################################################################################################################
### MOVEMENT settings and functions
###
### the "@export var ..." can be changed in the inspector, the values used here are the default values
### get input direction is seperated from the movement function for later use in the STATE_HANDLING
### the "movement" function needs to be at least called in the _physics_process(delta) function
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
### JUMPING settings and options
###
### "@export var ..." can be changed in the inspector
### "@onready var ..." handle calculations for jumping using the "@export var ..."
### Seperating the jump functings and gravity functions into their own functions allows us to give-
### unique properties to either, in this case we seperate out gravity to change it if the player is-
### on the ground or not.
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
### STATE HANDLING
###
### This will be a series of functions and variables that will allow us to define actions a player is-
### doing to make actions dinstinct, and to add restrictions to movement
########################################################################################################################

enum STATE { WALK_RIGHT, WALK_LEFT, IDLE, WALL_HUG, JUMP }
var current_state : STATE
var previous_state : STATE

########################################################################################################################
### Physics Process
###
### This sections will handle most of our realtime actions, this is where we call functions from-
### previous sections for actual implementation
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
