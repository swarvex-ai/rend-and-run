extends Node3D
## Maintenance sector behind the first sliding door: dark night shift with a guard and
## drones. (The power-routing puzzle that used to lock the door was removed on neVs'
## request, 2026-10-23: the door now opens as Rend approaches, see lab_route.gd.)
var route:Node3D
var circuits:=0
var defeated:Array=[]
var door:Node3D
var actors:Array[Node3D]=[]
var built_enemies:=false
var pending_defeats:Array=[]
var retry_time:=0.0
var maker:Node3D
var environment:Environment
var sunlight:DirectionalLight3D
var base_ambient:=.4
var base_sun:=1.0
func _ready():
	var world=route.main.get_node("WorldEnvironment")
	world.environment=world.environment.duplicate();environment=world.environment;base_ambient=environment.ambient_light_energy
	sunlight=route.main.get_node("DirectionalLight3D");base_sun=sunlight.light_energy
	maker=preload("res://modules/world/clean_factory.gd").new()
	var steel=maker.mat(Color(.2,.26,.3),.8,.3)
	var dark=maker.mat(Color(.025,.035,.05),.55,.4)
	var amber=maker.mat(Color(.9,.38,.06),.1,.3,true)
	var cyan=maker.mat(Color(.08,.6,.75),.3,.3,true)
	door=route.shortcut
	for child in door.get_panel().get_children():
		if child is MeshInstance3D:child.hide()
	for y in [1.0,3.0,5.0]:
		box(door.get_panel(),Vector3(0,y,0),Vector3(.65,1.96,3.4),steel)
		box(door.get_panel(),Vector3(0,y,1.74),Vector3(.12,1.6,.04),amber)
	box(self,Vector3(16.5,6.3,0),Vector3(1.4,.5,3.7),dark)
	var shape=door.get_body().get_node("CollisionShape3D") if door.get_body().has_node("CollisionShape3D") else door.get_body().get_child(0)
	shape.shape=shape.shape.duplicate();shape.shape.size=Vector3(.65,6.2,3.4);shape.position.y=3.1
	for child in route.get_children():
		if child is Label3D and child.position.x>17 and child.position.x<29:
			child.font_size=22;child.modulate=Color(.6,.75,.8)
	for x in [19.0,23.0,27.0]:
		box(self,Vector3(x,2.1,-1.35),Vector3(3.6,3.8,.32),dark)
		for dx in [-1.2,-.4,.4,1.2]:
			box(self,Vector3(x+dx,2.2,-1.13),Vector3(.58,2.4,.25),steel)
			for y in [1.4,1.8,2.2,2.6,3.0]:box(self,Vector3(x+dx,y,-.98),Vector3(.35,.025,.035),cyan if y!=2.2 else amber)
		box(self,Vector3(x,4.05,0),Vector3(3.7,.25,3.5),dark)
		var lamp:=OmniLight3D.new();lamp.position=Vector3(x,2.8,.6);lamp.light_color=Color(.16,.5,.65);lamp.light_energy=.7;lamp.omni_range=3.4;add_child(lamp)
	var key:=AreaLight3D.new();key.position=Vector3(23,3.3,2.8);key.rotation_degrees.x=-25;key.area_size=Vector2(10,1);key.light_color=Color(.55,.68,.8);key.light_energy=2;key.area_range=7;add_child(key)
func box(parent:Node3D,at:Vector3,size:Vector3,mat:Material):
	var mesh:=MeshInstance3D.new();mesh.mesh=maker.chamfered_box(size);mesh.material_override=mat;mesh.position=at;parent.add_child(mesh)
func _process(delta:float):
	var x:float=route.player.global_position.x
	var darkness:=smoothstep(16.5,19.0,x)*(1.0-smoothstep(27.5,30.0,x))
	environment.ambient_light_energy=lerpf(environment.ambient_light_energy,lerpf(base_ambient,.23,darkness),minf(1,delta*3))
	sunlight.light_energy=lerpf(sunlight.light_energy,lerpf(base_sun,base_sun*.42,darkness),minf(1,delta*3))
	retry_time-=delta
	if retry_time<=0 and not pending_defeats.is_empty():
		retry_time=1.0;_defeated(pending_defeats[0])
	if not route.shortcut_open:return
	if not built_enemies:
		built_enemies=true
		if not "maintenance_guard" in defeated:
			var guard=route.main._make_enemy(24.8,3,null,"scattergun");guard.encounter_id="maintenance_guard";guard.hp=5;guard.speed=2.4;guard.territory_min_x=18
			guard.get_node("VisualPivot").scale*=1.13
			guard.get_node("RoleLabel").text="WARTUNGSWACHE";guard.get_node("RoleLabel").font_size=18;guard.get_node("RoleLabel").pixel_size=.004
			var armor_material=guard._body_mesh.get_active_material(0).duplicate()
			armor_material.albedo_color=Color(.32,.42,.5);guard._body_mesh.set_surface_override_material(0,armor_material)
			guard.defeated.connect(_guard_defeated);actors.append(guard)
			var mount:=BoneAttachment3D.new();mount.bone_name="Spine2";guard._skeleton.add_child(mount)
			var pack=preload("res://assets3d/weapons/arm_servo_v1/model.glb").instantiate();mount.add_child(pack);pack.position=Vector3(0,0,-18);pack.scale=Vector3.ONE*180
		for i in 2:
			var id:="maintenance_drone_%d"%i
			if id in defeated:continue
			var drone=preload("res://modules/combat/maintenance_drone.gd").new();drone.encounter_id=id;drone.player=route.player;add_child(drone);drone.position=Vector3(20+i*6,1.7+i*.45,0);drone.home=drone.position;drone.timer=i*1.4;drone.destroyed.connect(_defeated);actors.append(drone)
	for actor in actors:
		if is_instance_valid(actor) and actor.get_script()==preload("res://modules/combat/maintenance_drone.gd"):actor.enabled=route.player.global_position.x>17.2
func _guard_defeated(guard):_defeated(guard.encounter_id)
func _defeated(id:String):
	if not id in ["maintenance_guard","maintenance_drone_0","maintenance_drone_1"] or id in defeated:return
	var previous:int=route.shards
	defeated.append(id);route.shards=mini(route.equipment.MAX_SHARDS,route.shards+2);route._save_progress()
	if route.save_error:
		defeated.erase(id);route.shards=previous;route.equipment.shards=previous
		if not id in pending_defeats:pending_defeats.append(id)
		route._message("Bergung noch nicht gespeichert — erneuter Versuch folgt.",4,3)
	else:
		pending_defeats.erase(id);route._message("+2 Splitter · Maschinenreste geborgen",2,1)
func _exit_tree():
	if is_instance_valid(maker):maker.free()
	for actor in actors:
		if is_instance_valid(actor):actor.queue_free()
