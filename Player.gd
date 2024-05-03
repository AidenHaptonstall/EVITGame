extends CharacterBody3D


const SPEED = 9.0
const JUMP_VELOCITY = 4.5
var ExitPointX = position.x
var ExitPointY = position.y
var ExitPointZ = position.z
var inRoom = false

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

# Get the Pivots
@onready var TwistPivot = $Body/TwistPivot
@onready var PitchPivot = $Body/TwistPivot/PitchPivot

# Get GUI (Pause/General)
@onready var PauseMenu = $Body/TwistPivot/PitchPivot/Camera_Physics/Camera/GUI_Control/PauseMenu
@onready var GeneralUI = $Body/TwistPivot/PitchPivot/Camera_Physics/Camera/GUI_Control/GeneralUI
@onready var DeathScreen = $Body/TwistPivot/PitchPivot/Camera_Physics/Camera/GUI_Control/DeathScreen
@onready var CompleteScreen = $Body/TwistPivot/PitchPivot/Camera_Physics/Camera/GUI_Control/CompleteScreen

# Get General Items from UI
@onready var HP = $Body/TwistPivot/PitchPivot/Camera_Physics/Camera/GUI_Control/GeneralUI/HP
@onready var Stamina = $Body/TwistPivot/PitchPivot/Camera_Physics/Camera/GUI_Control/GeneralUI/Stamina
@onready var Lunch = $Body/TwistPivot/PitchPivot/Camera_Physics/Camera/GUI_Control/GeneralUI/Lunch
@onready var Total = $Body/TwistPivot/PitchPivot/Camera_Physics/Camera/GUI_Control/CompleteScreen/Total

# Get Focus Point
@onready var FocusPoint = $Body/TwistPivot/PitchPivot/Camera_Physics/Camera/FocusPoint
@onready var Hitbox = $Hitbox
@onready var EnemyDetection = $Body/EnemyPivot/EnemyDetection

# Get Animation Player
@onready var RotationAnimation = $Body/EnemyPivot/EnemyDetection/AnimationPlayer

# Get Enemy Pill
@onready var Enemy = $"../Enemy"

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	RotationAnimation.play("Rotation")

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta
		
	if HP.value == 0:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		GeneralUI.visible = false
		DeathScreen.visible = true
		Engine.time_scale = 0
	
	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		
	if Input.is_action_just_pressed("ui_cancel"):
		PauseMenu.visible = true
		GeneralUI.visible = false
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		Engine.time_scale = 0
	
	if EnemyDetection.is_colliding():
		if EnemyDetection.get_collider().name == "Enemy":
			HP.value -= HP.step
	
	if FocusPoint.is_colliding():
		if FocusPoint.get_collider().name == "Lunch":
			if Input.is_action_just_pressed("LeftClick"):
				Lunch.value += 1
		elif FocusPoint.get_collider().name == "Door":
			if Input.is_action_just_pressed("LeftClick") && Lunch.value > 0:
				ExitPointX = position.x
				ExitPointY = position.y
				ExitPointZ = position.z
				position.x = 0
				position.y = -43.5
				position.z = 0
				_regen_energy()
				inRoom = !inRoom
				Lunch.value -= Lunch.step
		elif FocusPoint.get_collider().name == "Admin":
			if Input.is_action_just_pressed("LeftClick"):
				position.x = -45
				position.y = -43.5
				position.z = 0
				inRoom = !inRoom
				_end_game()
		elif FocusPoint.get_collider().name == "ExitDoor":
			if Input.is_action_just_pressed("LeftClick"):
				position.x = ExitPointX
				position.y = ExitPointY
				position.z = ExitPointZ
				inRoom = !inRoom

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("Right", "Left", "Backward", "Forward")
	var direction = (TwistPivot.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if direction:
			if Input.is_action_just_pressed("Dash") && !inRoom && Stamina.value >= 20:
				velocity.x = direction.x * SPEED * 35
				velocity.z = direction.z * SPEED * 35
				Stamina.value -= Stamina.step * 20
			else:
				velocity.x = direction.x * SPEED
				velocity.z = direction.z * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
			velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()

func _unhandled_input(event: InputEvent) -> void:
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			TwistPivot.rotate_y( - event.relative.x * 0.01)
			PitchPivot.rotate_x( - event.relative.y * 0.01)
			PitchPivot.rotation.x = clamp(PitchPivot.rotation.x, deg_to_rad(-60), deg_to_rad(60))
			
func _regen_energy():
	while Stamina.value != 100:
		await get_tree().create_timer(.5).timeout
		Stamina.value += Stamina.step * 5

func _on_resume_pressed():
	PauseMenu.visible = false
	GeneralUI.visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	Engine.time_scale = 1

func _on_quit_pressed():
	get_tree().quit()

func _on_respawn_pressed():
	position.x = 0
	position.y = 3.2
	position.z = 0
	Enemy.position.x = -98
	Enemy.position.y = 2
	Enemy.position.z = -15
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	GeneralUI.visible = true
	DeathScreen.visible = false
	HP.value = HP.max_value
	Stamina.value = Stamina.max_value
	Lunch.value = Lunch.min_value
	Engine.time_scale = 1
	
func _end_game():
	Engine.time_scale = 0
	CompleteScreen.visible = true
	GeneralUI.visible = false
	Total.text = "You earned: $" + str(Lunch.value * 100) + "/$1500"
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
