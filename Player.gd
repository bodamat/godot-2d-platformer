extends KinematicBody2D

# player states
enum STATE {
	JUMP,
	JUMP_TO_FALL,
	FALL,
	MOVE
}

export var _c_Gravity := 0
export var gravity := 9.8
export var max_fall_speed := 200
export var gravity_multiplier := 1.5

export var _c_Movement := 0
export var accelaration := 10 # accelaration for smooth move
export var max_move_speed := 150
export var jump_force := 500
export var smooth_stop := 0.2 # smaller value - smoother stop
export var smooth_stop_after_fall := 0.15 # smaller value - smoother stop
export var wait_time_after_fall := 0.1

export var _c_references := 0
export(NodePath) onready var anim_tree = get_node(anim_tree) as AnimationTree
export(NodePath) onready var sprite = get_node(sprite) as Sprite
export(NodePath) onready var timer = get_node(timer) as Timer

var _velocity := Vector2() # movement velocity
var _enable_input := true
var _state: int = STATE.MOVE

# handle inputs
func _input(event: InputEvent) -> void:
	if !_enable_input: return
	
	if Input.is_action_just_pressed("jump") and is_on_floor():
		_change_state(STATE.JUMP)
		_velocity.y -= jump_force


func _physics_process(_delta: float) -> void:
	# change animation state for different situations
	_anim_states()
	# handle movement inputs
	_control()
	
	_velocity.x = clamp(_velocity.x, -max_move_speed, max_move_speed)
	
	# flip sprite depends on directions
	if _velocity.x > 0:
		sprite.flip_h = false
	elif _velocity.x < 0:
		sprite.flip_h = true
	
	# calculate gravity
	_gravity()
	
# warning-ignore:return_value_discarded
	# move player with stop on slope 
	move_and_slide(_velocity, Vector2.UP, true)

# calculate gravity
func _gravity() -> void:
	_velocity.y += gravity * gravity_multiplier
	if _velocity.y > max_fall_speed:
		_velocity.y = max_fall_speed

# handle movement inputs
func _control() -> void:
	if Input.is_action_pressed("move_right") and _enable_input:
		_velocity.x += accelaration
		_walking_anim(true)
	elif Input.is_action_pressed("move_left") and _enable_input:
		_velocity.x -= accelaration
		_walking_anim(true)
	else:
		_walking_anim(false)
		var smooth_time = smooth_stop_after_fall if _state == STATE.FALL else smooth_stop
		_velocity.x = lerp(_velocity.x, 0, smooth_time )

# change animation state for different situations
func _anim_states() -> void:
	# jump state
	if _velocity.y < 0:
		anim_tree.set("parameters/conditions/jumping", true)
		anim_tree.set("parameters/conditions/not_jumping", false)
	# transition from jump to fall state in the highest point of jump
	elif _velocity.y > 0 and !is_on_floor():
		anim_tree.set("parameters/conditions/jumping", false)
		anim_tree.set("parameters/conditions/falling", true)
		_change_state(STATE.JUMP_TO_FALL)
	# fall to the ground state
	elif _velocity.y > 0 and is_on_floor() and _state == STATE.JUMP_TO_FALL:
		anim_tree.set("parameters/conditions/falling", false)
		anim_tree.set("parameters/conditions/not_jumping", true)
		
		_change_state(STATE.FALL)
		_enable_input = false
		timer.start(wait_time_after_fall)

# change walking animations states 
func _walking_anim(start_walking: bool) -> void:
	anim_tree.set("parameters/conditions/start_walking", start_walking)
	anim_tree.set("parameters/conditions/stop_walking", !start_walking)

# change player states
func _change_state(new_state: int):
	if _state == new_state: return
	_state = new_state

# timer after fall timeout
func _on_FallTimer_timeout() -> void:
	timer.stop()
	_change_state(STATE.MOVE)
	_enable_input = true
