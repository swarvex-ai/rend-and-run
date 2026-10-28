extends "res://modules/world/clean_factory.gd"
## Continues the first-room architecture (docs/vision-referenz.jpg) through the rest of
## the route: enamel piers, light wall cladding, glazed bays with calibration humanoids
## or server racks, satin floor and ceiling diffusers. Visual only; no physics changes.

const BAY_PITCH := 5.9
const FIRST_BAY_X := 16.35  # first bay east of the first room's compute recess (x 10.5–13.4)
# Night maintenance (x < NIGHT_END_X) keeps its dark mood at reduced fixture energy.
const NIGHT_END_X := 29.5
const BAYS := ["compute","compute","calibration","assembly","compute","alcove","assembly","compute","alcove","compute"]
const FLOOR_FIRST_X := 16.0
const FLOOR_LAST_X := 82.0  # through the exit lock hall

var _amber: StandardMaterial3D

func _ready() -> void:
	white=mat(Color(.48,.50,.505),.18,.32)
	graphite=mat(Color(.035,.055,.065),.5,.38)
	steel=mat(Color(.32,.41,.44),.8,.25)
	cyan=mat(Color(.12,.7,.77),.1,.3,true)
	_amber=mat(Color(.95,.42,.08),.2,.4,true)
	_hide_greybox()
	var x := FLOOR_FIRST_X
	while x <= FLOOR_LAST_X:
		for scene in [preload("res://assets3d/env/lab_finish_v1/model.glb"),preload("res://assets3d/env/foreground_deck_v101/model.glb")]:
			var deck := scene.instantiate() as Node3D
			add_child(deck);deck.position.x=x
			_finish_deck_materials(deck)
		x += 3.0
	for i in BAYS.size():
		var bay_x := FIRST_BAY_X+i*BAY_PITCH
		var level := 0.4 if bay_x < NIGHT_END_X else 1.0
		_pier(bay_x-BAY_PITCH*.5)
		if BAYS[i]=="calibration":_calibration_bay(bay_x,i,level)
		elif BAYS[i]=="assembly":_assembly_bay(bay_x,i,level)
		elif BAYS[i]=="alcove":_alcove_bay(bay_x,level)
		else:_compute_bay(bay_x,level)
		var fixture:=_ceiling_and_corridor_light(bay_x,level)
		if bay_x<NIGHT_END_X:
			# Night maintenance runs on failing tubes.
			var flicker:=preload("res://modules/visuals/light_flicker.gd").new()
			flicker.lights.append(fixture[0]);flicker.diffuser=fixture[1];add_child(flicker)
		elif i%2==0:
			var beacon:=preload("res://modules/visuals/alarm_beacon.gd").new()
			beacon.name="AlarmBeacon";beacon.position=Vector3(bay_x-BAY_PITCH*.5,3.45,-1.5);add_child(beacon)
	_pier(FIRST_BAY_X+(BAYS.size()-.5)*BAY_PITCH)
	_lock_hall(FIRST_BAY_X+(BAYS.size()-.5)*BAY_PITCH)
	# Security cameras on every second pier (Blender asset): they follow Rend and call robots.
	for i in [1,3,5,7,9]:
		var cam:=preload("res://modules/world/security_camera.gd").new();cam.name="SecurityCamera"
		add_child(cam);cam.position=Vector3(FIRST_BAY_X-BAY_PITCH*.5+i*BAY_PITCH,3.35,-1.52)
	# Production line over the corridor: torso shells travel high above the floor strip.
	for run in [[33.0,12.0],[55.0,10.0]]:
		var line := preload("res://modules/world/assembly_line.gd").new()
		line.name="CorridorLine";add_child(line);line.position=Vector3(run[0],0,-.95)
		line.configure(run[1],int(run[1]/1.6),4.35,true)
		line.setup(mat(Color(.44,.45,.46),.35,.62),steel,graphite,int(run[0]))
	var mood:=preload("res://modules/world/atmosphere.gd").new();mood.name="Atmosphere";add_child(mood)
	mood.build(-4.0,FLOOR_LAST_X+2.0)
	var front:=preload("res://modules/world/foreground_layer.gd").new();front.name="ForegroundLayer";add_child(front)
	front.build(-4.0,FLOOR_LAST_X+2.0)
	var paint:=preload("res://modules/world/floor_markings.gd").new();paint.name="FloorMarkings";add_child(paint)
	paint.build(-4.0,FLOOR_LAST_X+3.0)
	# Denser haze in night maintenance lets the failing tubes and drone lights cut beams.
	var haze:=FogVolume.new();haze.name="NightHaze"
	haze.size=Vector3(NIGHT_END_X-FIRST_BAY_X+BAY_PITCH*.5,5.0,6.0)
	haze.position=Vector3((FIRST_BAY_X-BAY_PITCH*.5+NIGHT_END_X)*.5,2.5,0)
	var haze_material:=FogMaterial.new();haze_material.density=0.035;haze_material.albedo=Color(.55,.66,.8)
	haze_material.edge_fade=0.6;haze.material=haze_material;add_child(haze)
	for mesh in find_children("*","MeshInstance3D",true,false):
		mesh.layers=CALIBRATION_INTERIOR_LAYER if mesh in _calibration_meshes else FACTORY_SURFACE_LAYER

func _hide_greybox() -> void:
	# Old block-out visuals east of the first room; every collider stays in place.
	var route := get_parent().get_parent()
	for child in route.get_children():
		if not child is Node3D or child.position.x < 13.5:continue
		var label := str(child.get_meta("construction_label",child.name))
		# RearShellEast would sit between the glazing and the bay interiors, which bring their own backwall.
		if label.begins_with("LaborFloor") or label in ["Pilaster","WallInset","Duct","GuideLight","FloorPanel","RearShellEast"]:
			child.hide()

func _pier(x: float) -> void:
	box("EnamelPier",Vector3(x,2.15,-1.73),Vector3(.65,4.3,.38),white)
	for y in [.14,1.45,3.8]:
		box("PanelJoint",Vector3(x,y,-1.53),Vector3(.61,.015,.018),graphite)
	box("FootLight",Vector3(x,.28,-1.48),Vector3(.035,.18,.04),_amber)

func _glazed_wall(x: float) -> void:
	var wall := preload("res://assets3d/env/factory_wall_finish_v1/model.glb").instantiate() as Node3D
	add_child(wall);wall.position=Vector3(x,0,-1.55)
	var pane := MeshInstance3D.new();pane.name="SafetyGlass"
	var quad := QuadMesh.new();quad.size=Vector2(4.72,2.65);pane.mesh=quad
	var glass := ShaderMaterial.new()
	glass.shader=preload("res://materials/factory_safety_glass.gdshader")
	glass.set_shader_parameter("ceiling_row",Vector4(x-3.0,CEILING_ROW_SPACING,3,CEILING_DIFFUSER_Y))
	glass.set_shader_parameter("ceiling_diffuser",Vector3(CEILING_DIFFUSER_Z,CEILING_DIFFUSER_HALF_SIZE.x,CEILING_DIFFUSER_HALF_SIZE.y))
	glass.set_shader_parameter("ceiling_radiance",Vector3(CEILING_DIFFUSER_COLOR.r,CEILING_DIFFUSER_COLOR.g,CEILING_DIFFUSER_COLOR.b)*CEILING_DIFFUSER_ENERGY)
	pane.material_override=glass;pane.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(pane);pane.position=Vector3(x,2.34,-1.49)
	for side in [-1.0,1.0]:
		box("GlassEdge",Vector3(x+side*2.355,2.34,-1.48),Vector3(.012,2.65,.016),steel)
		for y in [1.13,3.53]:box("GlassClip",Vector3(x+side*2.28,y,-1.45),Vector3(.13,.055,.065),graphite)
	# Genuine cavity behind the glazing.
	_mark_calibration_interior(box("BayBackwall",Vector3(x,2.55,-4.45),Vector3(BAY_PITCH,5.1,.16),graphite))
	_mark_calibration_interior(box("BayFloor",Vector3(x,.65,-3.05),Vector3(BAY_PITCH,.16,2.7),steel))
	_mark_calibration_interior(box("BayHeader",Vector3(x,4.25,-2.9),Vector3(BAY_PITCH,.65,2.7),graphite))

func _interior_light(x: float, energy: float) -> void:
	var key := AreaLight3D.new();key.name="BaySoftbox"
	key.position=Vector3(x,3.60,-2.40);key.rotation_degrees.x=-90
	key.area_size=Vector2(4.3,1.0);key.area_range=7.0
	key.light_color=Color(.86,.92,1);key.light_energy=energy
	key.light_cull_mask=CALIBRATION_INTERIOR_LAYER;key.shadow_enabled=false
	add_child(key)

func _calibration_bay(x: float, index: int, level: float) -> void:
	_glazed_wall(x)
	var cell := preload("res://assets3d/env/calibration_cell_v1/model.glb").instantiate() as Node3D
	add_child(cell);cell.position=Vector3(x,.8,-1.55)
	_finish_cell_materials(cell)
	_mark_calibration_interior(cell)
	var chassis := load("res://assets3d/characters/light_humanoid_baked_v1/model.glb").instantiate() as Node3D
	chassis.name="CalibrationHumanoid"
	add_child(chassis);chassis.position=Vector3(x,1.055,-3.03)
	_mark_calibration_interior(chassis)
	for marker in chassis.find_children("*Icosphere*","MeshInstance3D",true,false):marker.hide()
	var machine_rig := chassis.find_child("Skeleton3D",true,false) as Skeleton3D
	if machine_rig:
		var cycle=preload("res://modules/world/calibration_cycle.gd").new()
		cycle.name="CalibrationCycle";cycle.phase_offset=fmod(index*3.7,14.0)
		machine_rig.add_child(cycle)
	_interior_light(x,2.6*level)
	sign_text("ASSEMBLY / %02d" % (index+1),Vector3(x,.46,-1.478),22)

# Exit lock hall east of the last bay: the same enamel cladding, but closed walls with a
# hazard band, steady lights and rotating beacons around the lock door.
func _lock_hall(from_x: float) -> void:
	for i in 2:
		var x := from_x+BAY_PITCH*(i+.5)
		var wall := preload("res://assets3d/env/factory_wall_finish_v1/model.glb").instantiate() as Node3D
		add_child(wall);wall.position=Vector3(x,0,-1.55)
		box("LockPanel",Vector3(x,2.34,-1.5),Vector3(4.72,2.65,.05),white)
		for y in [1.4,2.0,2.6,3.2]:box("LockPanelGroove",Vector3(x,y,-1.47),Vector3(4.6,.012,.012),graphite)
		var band:=MeshInstance3D.new();band.name="HazardBand"
		var quad:=QuadMesh.new();quad.size=Vector2(4.72,.22);band.mesh=quad
		var paint:=ShaderMaterial.new();paint.shader=preload("res://materials/floor_paint.gdshader")
		paint.set_shader_parameter("hazard",true);paint.set_shader_parameter("wear",.2);paint.set_shader_parameter("size",Vector2(4.72,.22))
		band.material_override=paint;add_child(band);band.position=Vector3(x,1.13,-1.465)
		_pier(x+BAY_PITCH*.5)
		_ceiling_and_corridor_light(x,1.0)
		var beacon:=preload("res://modules/visuals/alarm_beacon.gd").new()
		beacon.name="AlarmBeacon";beacon.position=Vector3(x+BAY_PITCH*.5,3.45,-1.5);add_child(beacon)

## x of the open alcoves where a sentinel waits (lab_route spawns them).
static func alcove_xs() -> Array[float]:
	var result: Array[float] = []
	for i in BAYS.size():
		if BAYS[i]=="alcove":result.append(FIRST_BAY_X+i*BAY_PITCH)
	return result

# An open, unglazed recess at floor level: enamel wall either side of a 1.7 m doorway, a dark
# corridor running back into the plant and a dim service light. A sentinel stands inside.
func _alcove_bay(x: float, level: float) -> void:
	for side in [-1.0,1.0]:
		box("AlcoveWall",Vector3(x+side*1.95,2.15,-1.55),Vector3(2.0,4.3,.12),white)
		box("AlcoveJamb",Vector3(x+side*.9,1.4,-1.5),Vector3(.12,2.8,.2),graphite)
		box("AlcoveSide",Vector3(x+side*.95,1.4,-2.9),Vector3(.08,2.8,2.7),graphite)
		box("AlcoveMarker",Vector3(x+side*.83,1.4,-1.4),Vector3(.025,2.4,.02),_amber)
	box("AlcoveHeader",Vector3(x,3.55,-1.55),Vector3(1.9,1.5,.12),white)
	box("AlcoveLintel",Vector3(x,2.86,-1.5),Vector3(1.9,.12,.2),graphite)
	box("AlcoveBack",Vector3(x,1.4,-4.2),Vector3(1.8,2.8,.1),graphite)
	box("AlcoveCeiling",Vector3(x,2.82,-2.9),Vector3(1.8,.06,2.7),graphite)
	var lamp:=SpotLight3D.new();lamp.name="AlcoveServiceLight"
	lamp.position=Vector3(x,2.7,-3.6);lamp.rotation_degrees=Vector3(-70,0,0)
	lamp.light_color=Color(.55,.68,.8);lamp.light_energy=.6*level+.2;lamp.spot_range=3.5;lamp.spot_angle=40
	lamp.shadow_enabled=false;add_child(lamp)

func _assembly_bay(x: float, index: int, level: float) -> void:
	# Production line behind glass: unpainted humanoid blanks travel on overhead hooks.
	_glazed_wall(x)
	var line := preload("res://modules/world/assembly_line.gd").new()
	line.name="AssemblyLine";add_child(line);line.position=Vector3(x,0,-3.0)
	line.setup(mat(Color(.44,.45,.46),.35,.62),steel,graphite,index)
	_mark_calibration_interior(line)
	# Two welding robots work on the blanks from the back of the bay (Blender asset).
	for side in [-1.0,1.0]:
		var arm := preload("res://modules/world/welding_arm.gd").new()
		arm.name="WeldingArm";arm.work_yaw=-side*0.55;arm.phase=fmod(index*1.7+(1.3 if side>0 else 0.0),4.0)
		add_child(arm);arm.position=Vector3(x+side*1.75,1.08,-4.0);arm.scale=Vector3.ONE*1.25
		_mark_calibration_interior(box("ArmPedestal",Vector3(x+side*1.75,.9,-4.0),Vector3(.7,.36,.7),graphite))
		_mark_calibration_interior(arm)
	_interior_light(x,2.4*level)
	sign_text("ASSEMBLY / %02d" % (index+1),Vector3(x,.46,-1.478),22)

func _compute_bay(x: float, level: float) -> void:
	# Server bay behind glass: the vision's racks with status LEDs and their hum.
	_glazed_wall(x)
	for col in range(4):
		var rack := preload("res://assets3d/env/compute_rack_v1/model.glb").instantiate() as Node3D
		rack.name="ServerRack%d" % col;add_child(rack)
		rack.position=Vector3(x-1.65+col*1.1,.73,-3.0)
		_mark_calibration_interior(rack)
	_interior_light(x,1.6*level)
	sign_text("COMPUTE / %02d" % (int((x-FIRST_BAY_X)/BAY_PITCH)+2),Vector3(x,.46,-1.478),22)

# Returns [corridor light, diffuser material] so callers can animate the fixture.
func _ceiling_and_corridor_light(x: float, level: float) -> Array:
	var diffuser := mat(CEILING_DIFFUSER_COLOR,0.0,.32)
	diffuser.emission_enabled=true;diffuser.emission=CEILING_DIFFUSER_COLOR
	diffuser.emission_energy_multiplier=CEILING_DIFFUSER_ENERGY*level
	for offset in [-1.5,1.5]:
		box("CeilingFrame",Vector3(x+offset,CEILING_DIFFUSER_Y+.085,CEILING_DIFFUSER_Z),Vector3(2.8,.15,.8),graphite)
		box("CeilingDiffuser",Vector3(x+offset,CEILING_DIFFUSER_Y,CEILING_DIFFUSER_Z),Vector3(CEILING_DIFFUSER_HALF_SIZE.x*2,.02,CEILING_DIFFUSER_HALF_SIZE.y*2),diffuser)
	var lane_key := AreaLight3D.new();lane_key.name="CorridorSoftbox"
	lane_key.position=Vector3(x,4.35,1.05);lane_key.rotation_degrees.x=-65
	lane_key.area_size=Vector2(BAY_PITCH-.4,.65);lane_key.area_range=8.0
	lane_key.light_color=Color(.91,.95,1.0);lane_key.light_energy=4.0*level
	lane_key.light_cull_mask &= ~CALIBRATION_INTERIOR_LAYER
	lane_key.shadow_enabled=false
	add_child(lane_key)
	var guide := SpotLight3D.new();guide.name="PierGuidePool"
	guide.position=Vector3(x-BAY_PITCH*.5+.05,.285,-1.44);guide.rotation_degrees=Vector3(-25,180,0)
	guide.light_color=Color(1,.50,.16);guide.light_energy=1.2
	guide.spot_range=2.3;guide.spot_angle=65;guide.light_specular=.4;guide.shadow_enabled=false
	add_child(guide)
	return [lane_key,diffuser]
