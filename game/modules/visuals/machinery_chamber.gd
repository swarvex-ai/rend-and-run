extends Node3D
# Static visual alcove behind the first bay; no collision or traversable surfaces.
var _steel:StandardMaterial3D
func _material(color:Color,metal:=0.0)->StandardMaterial3D:
 var m:=StandardMaterial3D.new();m.albedo_color=color;m.metallic=metal;m.roughness=.65;return m
func _box(label:String,pos:Vector3,size:Vector3,m:Material):
 var n:=MeshInstance3D.new();n.name=label;n.position=pos
 var mesh:=BoxMesh.new();mesh.size=size;n.mesh=mesh;n.material_override=m
 n.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;add_child(n)
func _ready():
 _steel=_material(Color(.10,.15,.17),.55)
 var distant:=_material(Color(.055,.06,.095))
 var trim:=_material(Color(.18,.24,.25),.5)
 var indicator:=_material(Color(.08,.26,.28))
 indicator.emission_enabled=true;indicator.emission=Color(.045,.16,.18);indicator.emission_energy_multiplier=.7
 _box("FarWall",Vector3(.95,2.45,-7.2),Vector3(4.5,2.7,.2),distant)
 _box("ChamberFloor",Vector3(.95,1.0,-4.7),Vector3(4.5,.2,5.0),_steel)
 _box("ChamberCeiling",Vector3(.95,3.9,-4.7),Vector3(4.5,.2,5),distant)
 for x in [-1.4,3.3]:
  _box("ReturnWall",Vector3(x,2.45,-4.7),Vector3(.2,2.7,5),distant)
  _box("WindowJamb",Vector3(x,2.45,-1.86),Vector3(.16,2.9,.24),trim)
 for y in [1.05,3.85]:_box("WindowLintel",Vector3(.95,y,-1.86),Vector3(4.85,.16,.24),trim)
 # Repeated depth ribs provide parallax, with a quiet central silhouette.
 for z in [-3.4,-5.1,-6.8]:
  for x in [-1.2,3.1]:_box("DepthRib",Vector3(x,2.45,z),Vector3(.12,2.6,.12),_steel)
  _box("CeilingBeam",Vector3(.95,3.7,z),Vector3(4.3,.12,.14),_steel)
 var skid=preload("res://assets3d/env/coolant_skid_v1/model.glb").instantiate()
 skid.name="CoolantSkid";skid.position=Vector3(.8,1.10,-5.4);add_child(skid)
 _box("FarServiceLight",Vector3(.8,3.48,-7.05),Vector3(1.8,.035,.03),indicator)
