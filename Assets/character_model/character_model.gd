extends Node3D
class_name AnimationController

enum CombatStatus {COMBAT, NONCOMBAT}

@export var animation_tree: AnimationTree
@export var right_hand: Node3D
@export var armature: Node3D
@export var turn_rate: float = 0.1
@export var hip_ik: SkeletonIK3D
@export var right_hand_ik: SkeletonIK3D
@export var left_hand_ik: SkeletonIK3D
@export var hip_target: Node3D


var current_mouse_rotation: Vector2 = Vector2.ZERO
var input_dir: Vector2 = Vector2.UP
var current_combat_status: CombatStatus = CombatStatus.NONCOMBAT
var next_weapon_to_load: WeaponModel
var hip_rotation_offset: float = -55	

func _ready() -> void:
	hip_ik.start()
	right_hand_ik.start()
	left_hand_ik.start()
	hip_ik.influence = 0
	right_hand_ik.influence = 0
	left_hand_ik.influence = 0

func on_state_machine_state_change(state: String) -> void:
	match current_combat_status:
		CombatStatus.NONCOMBAT:
			animation_tree["parameters/unarmed_movement/transition_request"] = state
		CombatStatus.COMBAT:
			animation_tree["parameters/armed_movement/transition_request"] = state

func on_combat_status_changed(status: String) -> void:
	match status:
		"non_combat":
			input_dir = Vector2.UP
			current_combat_status = CombatStatus.NONCOMBAT
			_on_camera_camera_rotated(current_mouse_rotation)
			rotate_model(input_dir, current_mouse_rotation)
			set_ik_influence(hip_ik, 0, .1)
			set_ik_influence(left_hand_ik, 0,.1)
			set_ik_influence(right_hand_ik, 0,.1)
		"combat":
			current_combat_status = CombatStatus.COMBAT
			rotate_model(Vector2.UP, current_mouse_rotation)
			set_ik_influence(hip_ik,  1, .1)

	animation_tree["parameters/combat_transition/transition_request"] = status

func set_ik_influence(ik: SkeletonIK3D,_influence: float, _time: float) -> void:
	var tween : Tween = get_tree().create_tween()
	tween.tween_property(ik,"influence",_influence, _time)

func on_character_input_direction_changed(dir: Vector2) -> void:
	input_dir = input_dir.lerp(dir,turn_rate)
	match current_combat_status:
		CombatStatus.NONCOMBAT:
			rotate_model(input_dir, current_mouse_rotation)
		CombatStatus.COMBAT:
			animation_tree["parameters/walk_blend/blend_position"] = input_dir
			animation_tree["parameters/run_blend/blend_position"] = input_dir
		
func _on_camera_camera_rotated(_rotation: Vector2) -> void:
	current_mouse_rotation = _rotation
	rotate_hip()
	match current_combat_status:
		CombatStatus.NONCOMBAT:
			transform.basis = Basis()
			rotate_object_local(Vector3(0,1,0), current_mouse_rotation.x)

func rotate_hip() -> void:
	hip_target.transform.basis = Basis()
	hip_target.rotate_object_local(Vector3(1,0,0), current_mouse_rotation.y)
	hip_target.rotate_object_local(Vector3(0,1,0),deg_to_rad(hip_rotation_offset))


func rotate_model(angle: Vector2 = Vector2.ZERO, _rotation: Vector2 = Vector2.ZERO) -> void:
	var new_angle: float = atan2(angle.x,angle.y) - _rotation.x
	armature.transform.basis = Basis()
	armature.rotate_object_local(Vector3(0,1,0),new_angle)

func _on_weapon_manager_weapon_changed(_weapon: Weapon, _model: WeaponModel) -> void:
	set_ik_influence(left_hand_ik, 0,.1)
	set_ik_influence(right_hand_ik, 0,.1)
	load_new_weapon(_weapon,_model)

func load_new_weapon(_weapon: Weapon, model: WeaponModel) -> void:
	right_hand.position = _weapon.hand_position
	right_hand.rotation = _weapon.hand_rotation
	
	animation_tree.tree_root.get_node("weapon_idle_animation").set_animation(_weapon.weapon_idle_animation.resource_name)
	animation_tree.tree_root.get_node("weapon_shoot_animation").set_animation(_weapon.weapon_shoot_animation.resource_name)
	animation_tree.tree_root.get_node("weapon_reload_animation").set_animation(_weapon.weapon_reload_animation.resource_name)
	animation_tree.tree_root.get_node("weapon_change_animation").set_animation(_weapon.weapon_change_animation.resource_name)
	
	animation_tree["parameters/change_weapon/request"] = AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE
	next_weapon_to_load = model

func attach_weapon_to_hand() -> void:
	if next_weapon_to_load:
		right_hand.add_child(next_weapon_to_load)
		next_weapon_to_load = null
	
func remove_weapon_attachment() -> void:
	if right_hand.get_child_count() > 0:
		var current_weapon_attachment: Node3D = right_hand.get_child(0)
		current_weapon_attachment.queue_free()

func activate_hand_ik() -> void:
	if current_combat_status == CombatStatus.COMBAT:
		set_ik_influence(right_hand_ik,.5,.1)
		set_ik_influence(left_hand_ik, 1,.1)


func _on_weapon_manager_weapon_manager_finished(status: String, weapons_is_empty: bool) -> void:
	if animation_tree["parameters/combat_transition/current_state"] == status:
		return
		
	on_combat_status_changed(status)
	
	next_weapon_to_load = null
	
	if not weapons_is_empty:
		if animation_tree["parameters/change_weapon/active"]:
			remove_weapon_attachment()
			animation_tree["parameters/change_weapon/request"] = AnimationNodeOneShot.ONE_SHOT_REQUEST_FADE_OUT
		else:
			animation_tree["parameters/change_weapon/request"] = AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE

func _on_weapon_manager_weapon_manager_started(status:String, _weapon: Weapon, _model: WeaponModel) -> void:
	on_combat_status_changed(status)
	load_new_weapon(_weapon, _model)

func _on_weapon_manager_weapon_fired() -> void:
	animation_tree["parameters/shoot/request"] = AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE

func _on_weapon_manager_weapon_realoded() -> void:
	set_ik_influence(right_hand_ik,0,.1)
	set_ik_influence(left_hand_ik,0,.1)
	animation_tree["parameters/reload/request"] = AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE
