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
@export var move_default_speed := 150.0
@export var move_default_acceleration := 50.0
@export var move_default_friction := 50.0

var direction_facing : int

func get_input_direction():
	var input_axis = Input.get_axis("move_left", "move_right")
	if input_axis < 0:
		direction_facing = -1
	elif input_axis > 0:
		direction_facing = 1
	return input_axis

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
### DASH and PULSE settings
###
### current dash implementation takes default_speed and multiplies it by a dash_power value
########################################################################################################################

@export_category("Dash Settings")
@export var dash_default_power := 3

func dash():
	if is_on_floor():
		velocity.x = move_default_speed * dash_default_power * get_input_direction()
	else:
		velocity.x = move_default_speed * dash_default_power / 1.25 * get_input_direction()

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
@export var jump_height := 75.0
@export var jump_time_to_peak := 0.4
@export var jump_time_to_descent := 0.3

@onready var jump_velocity : float = ((2.0 * jump_height) / jump_time_to_peak) * -1.0
@onready var jump_gravity : float = ((-2.0 * jump_height) / (jump_time_to_peak * jump_time_to_peak)) * -1.0
@onready var fall_gravity : float = ((-2.0 * jump_height) / (jump_time_to_descent * jump_time_to_descent)) * -1.0

var wall_jump_ready = true

func get_gravity() -> float:
	if !is_on_wall():
		return jump_gravity if velocity.y < 0.0 else fall_gravity
	else:
		# If touching the wall, lower gravity
		return jump_gravity if velocity.y < 0.0 else ( fall_gravity / 16 )

func jump():
	velocity.y = jump_velocity

func wall_jump():
	wall_jump_ready = false
	velocity.y = jump_velocity
	velocity.x = -direction_facing * 200.0

func boost_up():
	velocity.y = jump_velocity * 2

########################################################################################################################
### Physics Process
###
### This sections will handle most of our realtime actions, this is where we call functions from-
### previous sections for actual implementation
########################################################################################################################

@onready var sprite = $Sprite2D
@onready var coyote_timer = $CoyoteTimer

@export var default_push_force := 30.0
@export var default_jump_timer := 0.2

var is_jumping : bool

func _input(event : InputEvent):
	if (event.is_action_pressed("move_down") and is_on_floor()):
		position.y += 2

func _physics_process(delta):

	# Movement
	movement()

	# Set jump_timer to default, reset when action is pressed
	var jump_timer := 0.0
	if Input.is_action_just_pressed("jump"):
		is_jumping = true
		jump_timer = default_jump_timer

	jump_timer -= delta

	if jump_timer > 0:
		if is_on_floor() or !coyote_timer.is_stopped():
			coyote_timer.stop()
			jump()
		elif is_on_wall_only() and wall_jump_ready:
			wall_jump()

	if Input.is_action_just_pressed("dash"):
		dash()

	# Reset values when standing on floor
	if is_on_floor():
		wall_jump_ready = true

	if velocity.y > 0:
		is_jumping = false

	# Sprite Handling
	if velocity.x > 0:
		# Facing Right
		sprite.flip_h = false
		sprite.offset = Vector2(-40, 0)
	elif velocity.x < 0:
		# Facing Left
		sprite.flip_h = true
		sprite.offset = Vector2(40, 0)

	# Handle collision with other rigid bodies
	for i in get_slide_collision_count():
		var c = get_slide_collision(i)
		if c.get_collider() is RigidBody2D:
			c.get_collider().apply_central_impulse(-c.get_normal() * default_push_force)

	var was_on_floor = is_on_floor()

	if coyote_timer.is_stopped():
		velocity.y += get_gravity() * delta

	move_and_slide()
	if !is_on_floor() and was_on_floor and !is_jumping:
		coyote_timer.start()

