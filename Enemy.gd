extends CharacterBody3D

@onready var nav_agent := $NavigationAgent3D
@onready var player := $"../Player"
@onready var myself := $RayCast3D

var SPEED = 10.5

func _unhandled_input(event: InputEvent) -> void:
	print("InputEvent: ", event)
	var random_position := Vector3.ZERO
	if player.position.y >= 2:
		random_position.x = player.position.x
		random_position.z = player.position.z
	nav_agent.set_target_position(random_position)
	
func _physics_process(delta):
	var destination = nav_agent.get_next_path_position()
	var local_destination = destination - global_position
	var direction = local_destination.normalized()
	
	velocity = direction * SPEED
	move_and_slide()
