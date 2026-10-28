extends CharacterBody3D
## Kamikaze drone (local geometry): hover -> lock-on (red eye blinking faster, warning beeps)
## -> committed dive at Rend -> detonates on contact with him, the floor, a wall or a case.
## The blast hurts everything in BLAST_RADIUS, robots included. Struck down by Rend first, it
## breaks apart without exploding.
const BLAST_RADIUS := 1.7
const BLAST_DAMAGE := 2
const DIVE_SPEED := 10.0
const LOCK_TIME := 0.9
var _beep := 0.0
signal destroyed(id:String)
var encounter_id:=""
var player:CharacterBody3D
var enabled:=false
var hp:=2
var _dead:=false
var phase:=0
var timer:=0.0
var home:=Vector3.ZERO
var target:=Vector3.ZERO
var shell:Node3D
var eye:StandardMaterial3D
var rotors:Array[Node3D]=[]
var age:=0.0
func _ready():
	collision_layer=2;collision_mask=1
	var col:=CollisionShape3D.new();var shape:=SphereShape3D.new();shape.radius=.32;col.shape=shape;add_child(col)
	shell=Node3D.new();add_child(shell)
	var maker=preload("res://modules/world/clean_factory.gd").new()
	var steel=maker.mat(Color(.24,.3,.34),.85,.25)
	var dark=maker.mat(Color(.025,.035,.045),.6,.36)
	eye=maker.mat(Color(.1,.8,.9),.3,.2,true)
	for spec in [[Vector3.ZERO,Vector3(.58,.23,.36),steel],[Vector3(0,-.14,0),Vector3(.28,.16,.26),dark],[Vector3(0,0,.2),Vector3(.22,.07,.025),eye]]:
		var m:=MeshInstance3D.new();m.mesh=maker.chamfered_box(spec[1]);m.material_override=spec[2];m.position=spec[0];shell.add_child(m)
	for x in [-.43,.43]:
		var ring:=MeshInstance3D.new();var torus:=TorusMesh.new();torus.inner_radius=.15;torus.outer_radius=.23;torus.rings=20;torus.ring_segments=8;ring.mesh=torus;ring.material_override=steel;ring.position.x=x;shell.add_child(ring)
		var rotor:=MeshInstance3D.new();rotor.mesh=maker.chamfered_box(Vector3(.34,.025,.045));rotor.material_override=dark;rotor.position=Vector3(x,.01,0);shell.add_child(rotor);rotors.append(rotor)
	maker.free()
func _physics_process(delta:float):
	if _dead or not is_instance_valid(player):return
	age+=delta
	for rotor in rotors:rotor.rotation.y+=delta*35
	if not enabled or player._dying:return
	timer-=delta
	var aim:=player.global_position+Vector3(0,.8,0)
	if phase==0:
		velocity=(home+Vector3(0,sin(age*2)*.12,0)-global_position)*2
		if absf(aim.x-global_position.x)<5 and absf(player.global_position.x-home.x)<7 and timer<=0:
			phase=1;timer=LOCK_TIME;target=aim;_beep=0.0
	elif phase==1:
		# Lock-on: hangs back and rises a little, eye blinks faster and faster.
		velocity=Vector3(0,.6,0)
		target=target.lerp(aim,delta*3.0)  # tracks him until it commits
		shell.rotation.z=sin(age*40)*.07
		var urgency:=1.0-timer/LOCK_TIME
		_beep-=delta
		if _beep<=0:
			_beep=lerpf(.28,.07,urgency);FX.play("block",2.6+urgency,-12.0)
			eye.emission=Color(1,.18,.02) if eye.emission.g>.3 else Color(1,.6,.2)
		eye.emission_energy_multiplier=lerpf(2,9,urgency)
		if timer<=0:phase=2;timer=1.2;velocity=(target-global_position).normalized()*DIVE_SPEED;eye.emission=Color(1,.1,0)
	elif phase==2:
		# Committed dive: no more steering, detonates on whatever it meets.
		shell.rotation.z=lerp_angle(shell.rotation.z,-signf(velocity.x)*.6,delta*8)
		if global_position.distance_to(aim)<.7 or is_on_floor() or is_on_wall() or is_on_ceiling() or timer<=0 or get_slide_collision_count()>0:
			detonate();return
	else:
		velocity=velocity.move_toward(Vector3.ZERO,delta*25)
		if timer<=0:phase=0;timer=.6;eye.emission=Color(.1,.8,.9);eye.emission_energy_multiplier=2
	move_and_slide()
	if phase!=2:global_position.z=move_toward(global_position.z,0,delta*2)
	global_position.x=clampf(global_position.x,home.x-7,home.x+7)
	global_position.y=clampf(global_position.y,.3,3.5)

## Blows up where it is: fireball, shrapnel, damage to everything close by.
func detonate() -> void:
	if _dead:return
	_dead=true;collision_layer=0
	var at:=global_position
	preload("res://modules/vfx/explosion.gd").blast(get_tree().current_scene,at,BLAST_RADIUS)
	preload("res://modules/vfx/debris.gd").breakup(get_tree().current_scene,at,Vector3.UP,16)
	FX.hitstop(0.08,0.05);FX.add_shake(0.9);FX.play("die",0.6,0.0)
	var space:=get_world_3d().direct_space_state
	for body in [player]+get_tree().get_nodes_in_group("enemies")+get_tree().get_nodes_in_group("throwables"):
		if not is_instance_valid(body) or body==self:continue
		var centre:Vector3=body.global_position+Vector3(0,.8,0)
		var d:=centre.distance_to(at)
		if d>BLAST_RADIUS:continue
		var q:=PhysicsRayQueryParameters3D.create(at,centre,1,[get_rid()])
		var hit:=space.intersect_ray(q)
		if not hit.is_empty() and hit.collider!=body:continue  # cover blocks the blast
		var push:=(centre-at).normalized()*lerpf(7.0,2.0,d/BLAST_RADIUS)
		if body==player:
			if not player._dying:player.take_damage(BLAST_DAMAGE,at,self)
		elif body is RigidBody3D:
			body.apply_central_impulse(push*body.mass*.6+Vector3(0,3,0))
		elif body.has_method("take_melee_hit") and body.get("_dead")!=true:
			body.take_melee_hit(BLAST_DAMAGE,Vector3(push.x,3.0,0))
	destroyed.emit(encounter_id)
	queue_free()
func receive_parry():
	phase=3;timer=1.8;velocity=Vector3.ZERO;FX.metal_contact(global_position,Vector3.UP)
func take_melee_hit(damage:int,knockback:Vector3):
	if _dead:return
	hp-=damage;FX.metal_contact(global_position,knockback);FX.play("hit",1.3,-5)
	phase=3;timer=.8;velocity=knockback*.3
	if hp>0:return
	_dead=true;collision_layer=0;destroyed.emit(encounter_id)
	for mesh in shell.get_children():
		if not mesh is MeshInstance3D:continue
		var bit:=RigidBody3D.new();bit.collision_layer=0;bit.collision_mask=1;get_parent().add_child(bit);bit.global_transform=mesh.global_transform
		var visual:=MeshInstance3D.new();visual.mesh=mesh.mesh;visual.material_override=mesh.material_override;bit.add_child(visual)
		var cs:=CollisionShape3D.new();var shape:=SphereShape3D.new();shape.radius=.12;cs.shape=shape;bit.add_child(cs)
		bit.linear_velocity=knockback*.25+Vector3(randf_range(-1,1),2,randf_range(-.6,.6));bit.angular_velocity=Vector3(2,3,4)
		bit.add_child(preload("res://modules/combat/debris_pause.gd").new())
		get_tree().create_timer(4).timeout.connect(bit.queue_free)
	queue_free()
