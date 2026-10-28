extends Node3D
## Assembly-sector architecture, behind the gameplay lane. No physics changes.
var white: StandardMaterial3D
var graphite: StandardMaterial3D
var steel: StandardMaterial3D
var cyan: StandardMaterial3D
var _deck_materials: Dictionary = {}
const FACTORY_SURFACE_LAYER := 1 << 18
const CALIBRATION_INTERIOR_LAYER := 1 << 19
var _calibration_meshes: Array[MeshInstance3D] = []

func _mark_calibration_interior(node: Node) -> void:
	if node is MeshInstance3D:
		_calibration_meshes.append(node)
	for child in node.get_children():
		_mark_calibration_interior(child)

# Shared physical placement and analytic reflection of the opposite ceiling row.
const CEILING_ROW_FIRST_X := -2.0
const CEILING_ROW_SPACING := 3.0
const CEILING_ROW_COUNT := 6
const CEILING_DIFFUSER_Y := 3.865
const CEILING_DIFFUSER_Z := 3.1
const CEILING_DIFFUSER_HALF_SIZE := Vector2(1.25,.29)
const CEILING_DIFFUSER_COLOR := Color(.74,.85,.95)
const CEILING_DIFFUSER_ENERGY := 3.0
func mat(color: Color, metal: float, rough: float, glow := false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color=color; m.metallic=metal; m.roughness=rough
	if glow:
		m.emission_enabled=true; m.emission=color; m.emission_energy_multiplier=1.4
	return m
func box(label: String, p: Vector3, size: Vector3, m: Material) -> MeshInstance3D:
	var n := MeshInstance3D.new(); n.name=label
	var mesh := chamfered_box(size)
	n.mesh=mesh; n.material_override=m; n.position=p; add_child(n)
	return n
# Small physical edge bevels catch the light even on untextured structural panels.
func chamfered_box(size: Vector3) -> ArrayMesh:
	var h := size * .5
	var bevel := minf(.028, minf(size.x, minf(size.y, size.z)) * .16)
	var inner := h - Vector3.ONE * bevel
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for axis in range(3):
		var u := (axis+1)%3
		var v := (axis+2)%3
		for sign_value in [-1.0,1.0]:
			var normal := Vector3.ZERO; normal[axis]=sign_value
			var points: Array[Vector3]=[]
			for pair in [Vector2(-1,-1),Vector2(1,-1),Vector2(1,1),Vector2(-1,1)]:
				var point := Vector3.ZERO
				point[axis]=h[axis]*sign_value;point[u]=inner[u]*pair.x;point[v]=inner[v]*pair.y
				points.append(point)
			add_polygon(surface,points,normal)
		# Four bevel strips parallel to this axis.
		for su in [-1.0,1.0]:
			for sv in [-1.0,1.0]:
				var points: Array[Vector3]=[]
				for pair in [Vector2(-1,0),Vector2(1,0),Vector2(1,1),Vector2(-1,1)]:
					var point := Vector3.ZERO;point[axis]=inner[axis]*pair.x
					point[u]=(h[u] if pair.y==0 else inner[u])*su
					point[v]=(inner[v] if pair.y==0 else h[v])*sv
					points.append(point)
				var normal := Vector3.ZERO;normal[u]=su;normal[v]=sv
				add_polygon(surface,points,normal.normalized())
	for sx in [-1.0,1.0]:
		for sy in [-1.0,1.0]:
			for sz in [-1.0,1.0]:
				var signs := Vector3(sx,sy,sz)
				var points: Array[Vector3]=[]
				for axis in range(3):
					var point := inner*signs;point[axis]=h[axis]*signs[axis];points.append(point)
				add_polygon(surface,points,signs.normalized())
	return surface.commit()
func add_polygon(surface: SurfaceTool, points: Array[Vector3], normal: Vector3) -> void:
	for i in range(1,points.size()-1):
		var a := points[0];var b := points[i];var c := points[i+1]
		if (b-a).cross(c-a).dot(normal)>0:
			var swap := b;b=c;c=swap
		for point in [a,b,c]:
			surface.set_normal(normal);surface.add_vertex(point)
func link(a: Vector3, b: Vector3, radius: float, m: Material) -> void:
	var n := MeshInstance3D.new(); var mesh := CylinderMesh.new()
	mesh.top_radius=radius; mesh.bottom_radius=radius; mesh.height=a.distance_to(b)
	mesh.radial_segments=16; n.mesh=mesh; n.material_override=m
	add_child(n); n.position=(a+b)*.5
	var y := (b-a).normalized(); var x := Vector3.FORWARD.cross(y).normalized()
	n.basis=Basis(x,y,x.cross(y).normalized())
func sign_text(text: String, p: Vector3, size: int) -> void:
	var n := Label3D.new(); n.text=text; n.position=p; n.font_size=size
	n.pixel_size=.004; n.modulate=Color(.18,.65,.7); n.outline_size=0; add_child(n)
func _ready() -> void:
	for child in get_parent().get_parent().get_children():
		if child is Label3D and child.text=="N / LAB\nSEKTOR 01": child.hide()
	white=mat(Color(.48,.50,.505),.18,.32)
	graphite=mat(Color(.035,.055,.065),.5,.38)
	steel=mat(Color(.32,.41,.44),.8,.25)
	cyan=mat(Color(.12,.7,.77),.1,.3,true)
	var amber := mat(Color(.95,.42,.08),.2,.4,true)
	# Remove only obsolete first-room visual backing; preserve every collider.
	var route := get_parent().get_parent()
	for child in route.get_children():
		if child is Node3D:
			var label := str(child.get_meta("construction_label",child.name))
			if label.begins_with("FirstRoomFloor") or label=="LaborFloor13" or label=="FoundationWest" or (label.begins_with("FloorPanel") and child.position.x<11):
				child.hide()
			elif label.begins_with("GuideLight") and child.position.x<14.5:
				child.hide() # This bay uses its actual amber fixtures, not the old cyan line.
			elif label == "RearShellEast":
				child.position.x=48.6
				var mesh_node: MeshInstance3D = child.get_child(0)
				var new_mesh := mesh_node.mesh.duplicate() as BoxMesh
				new_mesh.size.x=69.8;mesh_node.mesh=new_mesh
			elif label.begins_with("RearShell") or ((label.begins_with("WallInset") or label.begins_with("Pilaster") or label.begins_with("Duct")) and child.position.x<14):
				child.hide()
	for x in [-2.0,1.0,4.0,7.0,10.0,13.0]:
		var finish := preload("res://assets3d/env/lab_finish_v1/model.glb").instantiate() as Node3D
		add_child(finish);finish.position.x=x
		_finish_deck_materials(finish)
		var front := preload("res://assets3d/env/foreground_deck_v101/model.glb").instantiate() as Node3D
		add_child(front);front.position.x=x
		_finish_deck_materials(front)
	# A single static local capture supplies metal and glass with the actual room.
	var reflection := ReflectionProbe.new()
	reflection.name="FactoryReflection";reflection.position=Vector3(4,2,0)
	reflection.size=Vector3(18,6,8);reflection.interior=true
	reflection.box_projection=true;reflection.intensity=1.0
	add_child(reflection)
	_add_opposite_ceiling_row()
	var front_lamp := route.get_node_or_null("ServiceLamp3/PoolLight") as OmniLight3D
	if front_lamp:
		front_lamp.light_energy=.95;front_lamp.omni_range=4.2
		front_lamp.light_color=Color(.93,.94,1)
	# Genuine cavity: rear wall and floor lie behind the inset frame, not over it.
	_mark_calibration_interior(box("CellBackwall",Vector3(4.8,2.55,-4.45),Vector3(19,5.1,.16),graphite))
	_mark_calibration_interior(box("CellFloor",Vector3(4.8,.65,-3.05),Vector3(19,.16,2.7),steel))
	_mark_calibration_interior(box("ServiceHeader",Vector3(4.8,4.25,-2.9),Vector3(19,.65,2.7),graphite))
	for x in [-2.4,13.4]:
		box("EnamelPier",Vector3(x,2.15,-1.73),Vector3(.65,4.3,.38),white)
		for y in [.14,1.45,3.8]:
			box("PanelJoint",Vector3(x,y,-1.53),Vector3(.61,.015,.018),graphite)
		box("FootLight",Vector3(x,.28,-1.48),Vector3(.035,.18,.04),amber)
	for x in [.55,6.45]:
		var wall := preload("res://assets3d/env/factory_wall_finish_v1/model.glb").instantiate() as Node3D
		add_child(wall);wall.position=Vector3(x,0,-1.55)
		# Warm guide illumination originates at the authored pier's amber diffuser.
		# Small local pools reveal the satin floor without adding shadow-map passes.
		var guide := SpotLight3D.new();guide.name="PierGuidePool%d" % int(x)
		guide.position=Vector3(x+2.95,.285,-1.44)
		guide.rotation_degrees=Vector3(-25,180,0)
		guide.light_color=Color(1,.50,.16);guide.light_energy=1.2
		guide.spot_range=2.3;guide.spot_angle=65;guide.light_specular=.4;guide.shadow_enabled=false
		add_child(guide)
		var cell := preload("res://assets3d/env/calibration_cell_v1/model.glb").instantiate() as Node3D
		add_child(cell);cell.position=Vector3(x,.8,-1.55)
		_finish_cell_materials(cell)
		_mark_calibration_interior(cell)
		var pane := MeshInstance3D.new()
		pane.name="SafetyGlass01" if x<2 else "SafetyGlass02"
		var quad := QuadMesh.new();quad.size=Vector2(4.72,2.65);pane.mesh=quad
		var glass := ShaderMaterial.new()
		glass.shader=preload("res://materials/factory_safety_glass.gdshader")
		glass.set_shader_parameter("ceiling_row",Vector4(CEILING_ROW_FIRST_X,CEILING_ROW_SPACING,CEILING_ROW_COUNT,CEILING_DIFFUSER_Y))
		glass.set_shader_parameter("ceiling_diffuser",Vector3(CEILING_DIFFUSER_Z,CEILING_DIFFUSER_HALF_SIZE.x,CEILING_DIFFUSER_HALF_SIZE.y))
		glass.set_shader_parameter("ceiling_radiance",Vector3(CEILING_DIFFUSER_COLOR.r,CEILING_DIFFUSER_COLOR.g,CEILING_DIFFUSER_COLOR.b)*CEILING_DIFFUSER_ENERGY)
		pane.material_override=glass;pane.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(pane);pane.position=Vector3(x,2.34,-1.49)
		# Thin safety-glass edge and fastening tabs make the transparent plane readable.
		for side in [-1.0,1.0]:
			box("GlassEdge",Vector3(x+side*2.355,2.34,-1.48),Vector3(.012,2.65,.016),steel)
			for y in [1.13,3.53]:box("GlassClip",Vector3(x+side*2.28,y,-1.45),Vector3(.13,.055,.065),graphite)
		var chassis := load("res://assets3d/characters/light_humanoid_baked_v1/model.glb").instantiate() as Node3D
		chassis.name="CalibrationHumanoid"
		add_child(chassis);chassis.position=Vector3(x,1.055,-3.03)
		_mark_calibration_interior(chassis)
		for marker in chassis.find_children("*Icosphere*","MeshInstance3D",true,false):marker.hide()
		var machine_rig := chassis.find_child("Skeleton3D",true,false) as Skeleton3D
		if machine_rig:
			var cycle=preload("res://modules/world/calibration_cycle.gd").new()
			cycle.name="CalibrationCycle";cycle.phase_offset=0.0 if x<2 else 7.0
			machine_rig.add_child(cycle)
		var key := AreaLight3D.new();key.name="CalibrationSoftbox"
		key.position=Vector3(x,3.60,-2.40);key.rotation_degrees.x=-90
		key.area_size=Vector2(4.3,1.0);key.area_range=7.0
		key.light_color=Color(.86,.92,1);key.light_energy=2.6
		key.light_cull_mask=CALIBRATION_INTERIOR_LAYER
		key.shadow_enabled=false;key.light_size=.7
		key.shadow_normal_bias=1.0;key.shadow_bias=.15;add_child(key)
		sign_text("CALIBRATION / %02d" % (1 if x<2 else 2),Vector3(x,.46,-1.478),22)
	var lane_key := AreaLight3D.new();lane_key.name="CorridorSoftbox"
	lane_key.position=Vector3(4.0,4.35,1.05);lane_key.rotation_degrees.x=-65
	lane_key.area_size=Vector2(10.0,.65);lane_key.area_range=8.0
	lane_key.light_color=Color(.91,.95,1.0);lane_key.light_energy=4.4
	lane_key.shadow_enabled=true;lane_key.light_size=.65
	lane_key.light_cull_mask &= ~CALIBRATION_INTERIOR_LAYER
	lane_key.shadow_caster_mask=1 # Actors/props cast; nearby low-subdivision ceiling panels do not.
	lane_key.shadow_normal_bias=1.0;add_child(lane_key)
	# Narrow foreground finish rail retains the original playable floor height.
	box("DeckFrontTrim",Vector3(4.8,-.16,1.79),Vector3(18,.16,.08),steel)
	# Bestueckter, wiederverwendbarer Blender-Serverschrank statt Block-Platzhaltern.
	# The compute bay is the final bay of this room, with the same finished floor
	# and ceiling, an inset back panel and a mounted transom instead of a void.
	box("ComputeBackPanel",Vector3(11.95,1.92,-2.85),Vector3(2.85,3.80,.10),graphite)
	box("ComputeTransom",Vector3(11.95,3.55,-1.70),Vector3(2.85,.68,.22),white)
	box("ComputeTransomReveal",Vector3(11.95,3.175,-1.70),Vector3(2.85,.035,.24),graphite)
	for x in [10.48,13.42]:
		box("ComputeRecessJamb",Vector3(x,1.90,-2.19),Vector3(.08,3.75,1.3),steel)
	for x in [10.9,11.95,13.0]:
		box("ComputeRearRib",Vector3(x,1.9,-2.76),Vector3(.045,3.65,.075),steel)
	sign_text("COMPUTE / 01",Vector3(11.95,3.54,-1.579),20)
	for col in range(2):
		var x := 11.5+col*.9
		var rack := preload("res://assets3d/env/compute_rack_v1/model.glb").instantiate() as Node3D
		rack.name="ComputeRack%d" % col;add_child(rack);rack.position=Vector3(x,0,-1.65)
		sign_text("RACK / %02d" % (col+1),Vector3(x,2.565,-1.175),12)
	var task_diffuser := mat(Color(.76,.88,1),.05,.28,true)
	box("ComputeLampHousing",Vector3(11.95,3.02,-1.20),Vector3(1.85,.10,.34),graphite)
	box("ComputeLampDiffuser",Vector3(11.95,2.964,-1.20),Vector3(1.67,.018,.24),task_diffuser)
	for x in [11.3,12.6]:link(Vector3(x,3.06,-1.22),Vector3(x,4.05,-1.22),.012,steel)
	var rack_key := OmniLight3D.new();rack_key.name="ComputeTaskLight"
	rack_key.position=Vector3(11.95,2.90,-.8);rack_key.light_color=Color(.76,.88,1)
	rack_key.light_energy=1.2;rack_key.omni_range=3.2;rack_key.shadow_enabled=false;add_child(rack_key)
	var bay_key := AreaLight3D.new();bay_key.name="ComputeCorridorSoftbox"
	bay_key.position=Vector3(12.0,4.35,1.05);bay_key.rotation_degrees.x=-65
	bay_key.area_size=Vector2(2.8,.65);bay_key.area_range=6.0
	bay_key.light_color=Color(.91,.95,1);bay_key.light_energy=3.6
	bay_key.shadow_enabled=true;bay_key.light_size=.65
	bay_key.light_cull_mask &= ~CALIBRATION_INTERIOR_LAYER
	bay_key.shadow_caster_mask=1;bay_key.shadow_normal_bias=1.0;add_child(bay_key)

	# First-room architecture receives its local fixtures, not the outdoor-style sun.
	# Render layers separate cell fixtures from corridor fill; camera/probe see both.
	# Gameplay actors retain their existing layer and collisions.
	for mesh in find_children("*","MeshInstance3D",true,false):
		mesh.layers=CALIBRATION_INTERIOR_LAYER if mesh in _calibration_meshes else FACTORY_SURFACE_LAYER
	var sun := route.get_parent().get_node_or_null("DirectionalLight3D") as DirectionalLight3D
	if sun:
		sun.light_cull_mask &= ~(FACTORY_SURFACE_LAYER | CALIBRATION_INTERIOR_LAYER)
		sun.shadow_caster_mask &= ~(FACTORY_SURFACE_LAYER | CALIBRATION_INTERIOR_LAYER)

	var ambience := preload("res://modules/audio/factory_ambience.gd").new()
	ambience.name = "FactoryAmbience"
	ambience.actor = route.get_parent().get_node("Player")
	add_child(ambience)

func _finish_cell_materials(cell: Node3D) -> void:
	# Runtime finish of the authored Blender cell: dark machine enclosure behind
	# light cladding, with diffuse fixtures that retain colour through tonemapping.
	for mesh in cell.find_children("*","MeshInstance3D",true,false):
		for surface in mesh.mesh.get_surface_count():
			var source=mesh.get_active_material(surface)
			if not source is StandardMaterial3D:continue
			if source.resource_name not in ["Ceramic_white_enamel","Cool_diffuser"]:continue
			var finish:StandardMaterial3D=source.duplicate()
			if source.resource_name=="Ceramic_white_enamel":
				finish.albedo_color=Color(.17,.22,.25);finish.metallic=.45;finish.roughness=.38
			else:finish.emission_energy_multiplier=1.15
			mesh.set_surface_override_material(surface,finish)

func _add_opposite_ceiling_row() -> void:
	# In the room, beyond the walking lane; the camera sees their reflection in
	# the bay glass. These emitters do not require another camera or shadow pass.
	var diffuser := mat(CEILING_DIFFUSER_COLOR,0.0,.32)
	diffuser.emission_enabled=true
	diffuser.emission=CEILING_DIFFUSER_COLOR
	diffuser.emission_energy_multiplier=CEILING_DIFFUSER_ENERGY
	for i in CEILING_ROW_COUNT:
		var x := CEILING_ROW_FIRST_X+i*CEILING_ROW_SPACING
		box("OppositeCeilingFrame%d" % i,Vector3(x,CEILING_DIFFUSER_Y+.085,CEILING_DIFFUSER_Z),Vector3(2.8,.15,.8),graphite)
		box("OppositeCeilingDiffuser%d" % i,Vector3(x,CEILING_DIFFUSER_Y,CEILING_DIFFUSER_Z),Vector3(CEILING_DIFFUSER_HALF_SIZE.x*2,.02,CEILING_DIFFUSER_HALF_SIZE.y*2),diffuser)

func _finish_deck_materials(deck: Node3D) -> void:
	# Retain the Blender deck geometry/UVs and embedded machining texture.
	# Match walking and foreground plates with the same dark satin metal finish.
	for mesh in deck.find_children("*","MeshInstance3D",true,false):
		for surface in mesh.mesh.get_surface_count():
			var source=mesh.get_active_material(surface)
			if not source is StandardMaterial3D:continue
			if source.resource_name not in ["Satin_machined_floor","Foreground_satin_steel"]:continue
			var key: int = source.get_instance_id()
			if not _deck_materials.has(key):
				var finish:StandardMaterial3D=source.duplicate()
				finish.albedo_color=Color(.36,.40,.43)
				finish.metallic=.85
				finish.roughness=.65 if finish.roughness_texture else .17
				_deck_materials[key]=finish
			mesh.set_surface_override_material(surface,_deck_materials[key])
