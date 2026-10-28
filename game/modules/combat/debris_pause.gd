extends Node
## Keep transient bodies registered across menu pauses; freeze motion explicitly.
## This avoids duplicate physics-list registration on repeated workbench resumes.
var body: RigidBody3D
var _paused := false
var _was_frozen := false
var _was_sleeping := false
var _linear := Vector3.ZERO
var _angular := Vector3.ZERO
func _ready() -> void:
	body=get_parent() as RigidBody3D
	process_mode=Node.PROCESS_MODE_ALWAYS
	body.process_mode=Node.PROCESS_MODE_ALWAYS
func _process(_delta:float) -> void:
	var paused_now:bool=get_tree().paused
	if paused_now==_paused:return
	_paused=paused_now
	if paused_now:
		_was_frozen=body.freeze;_was_sleeping=body.sleeping;_linear=body.linear_velocity;_angular=body.angular_velocity
		body.freeze=true
	else:
		body.freeze=_was_frozen
		if not _was_frozen:
			body.linear_velocity=_linear;body.angular_velocity=_angular;body.sleeping=_was_sleeping
