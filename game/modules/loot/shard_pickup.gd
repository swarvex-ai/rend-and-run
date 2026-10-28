extends Node3D
## Presentation only. Route owns the one-time reward and persistent pending state.
signal reached(crate_id: String)
var crate_id := ""
var amount := 3
var player: CharacterBody3D
var _age := 0.0
var _collecting := false
var _sent := false
var _visual: Node3D
var _home := Vector3.ZERO

func _ready() -> void:
	_home = position
	_visual = Node3D.new(); add_child(_visual)
	var mat := StandardMaterial3D.new()
	mat.albedo_color=Color(.65,.76,.78);mat.metallic=.8;mat.roughness=.28
	mat.emission_enabled=true;mat.emission=Color(.06,.26,.28);mat.emission_energy_multiplier=1.2
	for i in 3:
		var piece:=MeshInstance3D.new()
		var mesh:=BoxMesh.new();mesh.size=Vector3(.055,.16,.075)
		piece.mesh=mesh;piece.material_override=mat
		piece.position=Vector3((i-1)*.09,.02 if i==1 else 0,0)
		piece.rotation=Vector3(.2,(i-1)*.7,(i-1)*-.45)
		_visual.add_child(piece)
	var label:=Label3D.new()
	label.text="%d SPLITTER"%amount;label.font_size=20;label.pixel_size=.003
	label.position.y=.32;label.modulate=Color(.4,.9,.93)
	label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label)

func _physics_process(delta: float) -> void:
	_age+=delta
	if _sent or not is_instance_valid(player):return
	if player._dying:
		_collecting=false;position=_home
		return
	var target:=player.global_position+Vector3(0,.65,0)
	var near:=absf(player.global_position.x-_home.x)<.95 and absf(player.global_position.y-(_home.y-.28))<.65
	# A brief reveal survives the breaking hit; never pull through a wall.
	if not _collecting and _age>.4 and near:
		var query:=PhysicsRayQueryParameters3D.create(global_position,target,1)
		if get_world_3d().direct_space_state.intersect_ray(query).is_empty():_collecting=true
	if _collecting:
		global_position=global_position.move_toward(target,delta*5.0)
		if global_position.distance_to(target)<.12:
			_sent=true;reached.emit(crate_id)
			if is_inside_tree():queue_free()
	else:
		_visual.position.y=.035*sin(_age*3.0)
		_visual.rotation.y=_age*.6
