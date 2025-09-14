extends Node3D

@export var character: CharacterBody3D
@export var swap_cam_duration: float

@onready var edge_spring_arm: SpringArm3D = $EdgeSpringArm


var camera_rotation: Vector2 = Vector2.ZERO
const mouse_sensitivity: float = .001;
const max_y_rotation: float = 1.2

var camera_tween: Tween
var cache_edge_spring_arm_spring_length: float

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	cache_edge_spring_arm_spring_length = edge_spring_arm.spring_length


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		
#		# camera can be moved only when mouse is captured
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var mouse_event: Vector2 = event.screen_relative * mouse_sensitivity
		camera_look(mouse_event)
	
	if event.is_action_pressed("swap_cam"):
		swap_camera_alignment()

func camera_look(mouse_movement: Vector2) -> void:
	camera_rotation += mouse_movement
	
	transform.basis = Basis()
	character.transform.basis = Basis()
	character.rotate_object_local(Vector3(0, 1, 0), -camera_rotation.x)
	rotate_object_local(Vector3(1, 0, 0), -camera_rotation.y)
	
	camera_rotation.y = clamp(camera_rotation.y, -max_y_rotation, max_y_rotation)

func swap_camera_alignment() -> void:
	#cache_edge_spring_arm_spring_length = -cache_edge_spring_arm_spring_length
	var new_pos: float = cache_edge_spring_arm_spring_length * -sign(edge_spring_arm.spring_length)
	update_edge_sprint_arm_position(new_pos, swap_cam_duration)

func update_edge_sprint_arm_position(pos: float, duration: float) -> void:
	if camera_tween:
		camera_tween.kill()
	
	camera_tween = create_tween()
	camera_tween.tween_property(edge_spring_arm, "spring_length", pos, duration)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
